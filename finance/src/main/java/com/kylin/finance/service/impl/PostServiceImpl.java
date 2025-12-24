package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.kylin.common.BusinessException;
import com.kylin.finance.common.DocumentStatus;
import com.kylin.finance.entity.*;
import com.kylin.finance.entity.business.Customer;
import com.kylin.finance.entity.business.Owner;
import com.kylin.finance.entity.business.Vendor;
import com.kylin.finance.entity.document.*;
import com.kylin.finance.mapper.*;
import com.kylin.finance.service.IPostService;
import com.kylin.finance.service.IFinTransactionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 过账服务实现（参考 GnuCash 双重检查逻辑）
 */
@Slf4j
@Service
public class PostServiceImpl implements IPostService {

    @Autowired
    private FinTransactionMapper transactionMapper;

    @Autowired
    private FinSplitMapper splitMapper;

    @Autowired
    private InvoiceMapper invoiceMapper;

    @Autowired
    private BillMapper billMapper;

    @Autowired
    private CreditNoteMapper creditNoteMapper;

    @Autowired
    private InvoiceItemMapper invoiceItemMapper;

    @Autowired
    private BillItemMapper billItemMapper;

    @Autowired
    private CustomerMapper customerMapper;

    @Autowired
    private VendorMapper vendorMapper;

    @Autowired
    private IFinTransactionService transactionService;
    
    @Autowired
    private OwnerMapper ownerMapper;
    
    @Autowired
    private FinAccountMapper accountMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction postInvoiceToLedger(Invoice invoice) {
        log.info("开始过账发票，ID：{}，编号：{}", invoice.getInvoiceId(), invoice.getInvoiceNo());
        
        // 1. 检查发票状态（必须为 VALIDATED）
        DocumentStatus currentStatus = DocumentStatus.fromCode(invoice.getStatus());
        if (currentStatus != DocumentStatus.VALIDATED) {
            throw new BusinessException(
                String.format("发票状态为 %s，无法过账。只有已审核状态的发票才能过账。", currentStatus.getDescription()));
        }
        
        if (invoice.getPosted() != null && invoice.getPosted()) {
            throw new BusinessException("发票已过账，无法重复过账");
        }

        // 2. 验证客户信息和往来科目（双重检查 - 第一重）
        // 注意：invoice.getCustomerId() 返回的是 owner_id（fin_owner表的主键），不是 customer_id
        // 因此需要使用 OwnerMapper 查询，而不是 CustomerMapper
        Owner customer = ownerMapper.selectById(invoice.getCustomerId());
        if (customer == null) {
            throw new BusinessException("客户信息不存在，ID：" + invoice.getCustomerId());
        }

        if (customer.getAccountId() == null) {
            throw new BusinessException("客户未关联应收账款科目，无法过账。请先为客户关联应收账款科目。");
        }
        
        // 校验往来科目是否存在且有效
        FinAccount receivableAccount = accountMapper.selectById(customer.getAccountId());
        if (receivableAccount == null) {
            throw new BusinessException(
                String.format("客户关联的应收账款科目不存在，科目ID：%d。请检查客户配置。", customer.getAccountId()));
        }
        
        // 校验科目类型：客户必须关联资产类（ASSET）科目，如应收账款（1122）
        if (!"ASSET".equals(receivableAccount.getAccountType())) {
            throw new BusinessException(
                String.format("客户关联的科目类型错误。客户必须关联资产类（ASSET）科目，当前科目ID：%d，科目代码：%s，科目名称：%s，科目类型：%s。请为客户配置正确的应收账款科目（如1122）。",
                    receivableAccount.getAccountId(), 
                    receivableAccount.getAccountCode(), 
                    receivableAccount.getAccountName(),
                    receivableAccount.getAccountType()));
        }
        
        log.info("客户往来科目校验通过，客户：{}，科目ID：{}，科目代码：{}，科目名称：{}，科目类型：{}", 
            customer.getName(),
            receivableAccount.getAccountId(),
            receivableAccount.getAccountCode(), 
            receivableAccount.getAccountName(),
            receivableAccount.getAccountType());

        // 3. 获取发票条目
        LambdaQueryWrapper<InvoiceItem> itemWrapper = new LambdaQueryWrapper<>();
        itemWrapper.eq(InvoiceItem::getInvoiceId, invoice.getInvoiceId());
        List<InvoiceItem> items = invoiceItemMapper.selectList(itemWrapper);

        if (items.isEmpty()) {
            throw new BusinessException("发票没有条目，无法过账");
        }
        
        // 4. 双重检查 - 第二重：校验单据总额 = 明细行金额之和
        BigDecimal itemsTotalAmount = BigDecimal.ZERO;
        BigDecimal itemsTotalTax = BigDecimal.ZERO;
        
        for (InvoiceItem item : items) {
            if (item.getAmount() == null) {
                throw new BusinessException("发票条目金额不能为空，条目描述：" + item.getDescription());
            }
            if (item.getIncomeAccountId() == null) {
                throw new BusinessException("发票条目必须关联收入科目，条目描述：" + item.getDescription());
            }
            
            // 校验收入科目是否存在
            FinAccount incomeAccount = accountMapper.selectById(item.getIncomeAccountId());
            if (incomeAccount == null) {
                throw new BusinessException("发票条目的收入科目不存在，科目ID：" + item.getIncomeAccountId());
            }
            
            itemsTotalAmount = itemsTotalAmount.add(item.getAmount());
            if (item.getTaxAmount() != null) {
                itemsTotalTax = itemsTotalTax.add(item.getTaxAmount());
            }
        }
        
        // 计算明细行总金额（含税）
        BigDecimal itemsTotalWithTax = itemsTotalAmount.add(itemsTotalTax);
        
        // 比较单据总额和明细行金额之和（允许0.01的误差，用于处理浮点数精度问题）
        BigDecimal difference = invoice.getTotalAmount().subtract(itemsTotalWithTax).abs();
        if (difference.compareTo(new BigDecimal("0.01")) > 0) {
            throw new BusinessException(
                String.format("单据总额（%s）与明细行金额之和（%s）不一致，差额：%s。请检查发票金额计算。",
                    invoice.getTotalAmount(), itemsTotalWithTax, difference));
        }
        
        log.info("双重检查通过 - 单据总额：{}，明细行金额之和：{}", invoice.getTotalAmount(), itemsTotalWithTax);

        // 4. 创建交易
        FinTransaction transaction = new FinTransaction();
        transaction.setTransDate(invoice.getInvoiceDate());
        transaction.setDescription("发票过账：" + invoice.getInvoiceNo());
        transaction.setStatus(0); // 草稿状态，过账后可审核
        transaction.setEnterDate(LocalDateTime.now());
        transaction.setVoucherNo(null); // 稍后生成凭证号
        transaction.setCurrencyId(invoice.getCommodityId());

        List<FinSplit> splits = new ArrayList<>();

        // 借方：应收账款（客户关联科目）
        FinSplit receivableSplit = new FinSplit();
        receivableSplit.setAccountId(customer.getAccountId());
        receivableSplit.setDirection("DEBIT");
        receivableSplit.setAmount(invoice.getTotalAmount());
        receivableSplit.setMemo("应收账款 - 发票：" + invoice.getInvoiceNo());
        receivableSplit.setOwnerId(invoice.getCustomerId());
        receivableSplit.setOwnerType("CUSTOMER");
        splits.add(receivableSplit);

        // 贷方：收入科目
        BigDecimal totalIncome = BigDecimal.ZERO;
        BigDecimal totalTax = BigDecimal.ZERO;

        for (InvoiceItem item : items) {
            if (item.getIncomeAccountId() != null) {
                FinSplit incomeSplit = new FinSplit();
                incomeSplit.setAccountId(item.getIncomeAccountId());
                incomeSplit.setDirection("CREDIT");
                incomeSplit.setAmount(item.getAmount());
                incomeSplit.setMemo(item.getDescription());
                splits.add(incomeSplit);
                totalIncome = totalIncome.add(item.getAmount());
            }

            if (item.getTaxAmount() != null && item.getTaxAmount().compareTo(BigDecimal.ZERO) > 0) {
                totalTax = totalTax.add(item.getTaxAmount());
            }
        }

        // 如果有税费，单独记录
        if (totalTax.compareTo(BigDecimal.ZERO) > 0) {
            // 假设有一个默认的应交税费科目（2221）
            FinSplit taxSplit = new FinSplit();
            taxSplit.setAccountId(2221L); // 应交税费科目ID（需要根据实际配置）
            taxSplit.setDirection("CREDIT");
            taxSplit.setAmount(totalTax);
            taxSplit.setMemo("销项税 - 发票：" + invoice.getInvoiceNo());
            splits.add(taxSplit);
        }

        transaction.setSplits(splits);

        // 5. 保存交易（这会触发交易服务中的校验）
        transactionService.saveVoucher(transaction);
        
        log.info("会计分录生成成功，交易ID：{}，凭证号：{}", transaction.getTransId(), transaction.getVoucherNo());

        // 6. 更新发票状态为 POSTED，并锁定单据编号
        invoice.setStatus(DocumentStatus.POSTED.getCode());
        invoice.setPosted(true);
        invoice.setTransId(transaction.getTransId());
        // 锁定单据编号：确保编号不为空且唯一
        if (invoice.getInvoiceNo() == null || invoice.getInvoiceNo().trim().isEmpty()) {
            throw new BusinessException("发票编号不能为空，无法过账");
        }
        invoiceMapper.updateById(invoice);
        
        log.info("发票过账成功，ID：{}，编号：{}（已锁定），交易ID：{}", 
            invoice.getInvoiceId(), invoice.getInvoiceNo(), transaction.getTransId());

        return transaction;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction postBillToLedger(Bill bill) {
        log.info("开始过账账单，ID：{}，编号：{}", bill.getBillId(), bill.getBillNo());
        
        // 1. 检查账单状态（必须为 VALIDATED）
        DocumentStatus currentStatus = DocumentStatus.fromCode(bill.getStatus());
        if (currentStatus != DocumentStatus.VALIDATED) {
            throw new BusinessException(
                String.format("账单状态为 %s，无法过账。只有已审核状态的账单才能过账。", currentStatus.getDescription()));
        }
        
        if (bill.getPosted() != null && bill.getPosted()) {
            throw new BusinessException("账单已过账，无法重复过账");
        }

        // 2. 验证供应商信息和往来科目（双重检查 - 第一重）
        // 注意：bill.getVendorId() 返回的是 owner_id（fin_owner表的主键），不是 vendor_id
        // 因此需要使用 OwnerMapper 查询，而不是 VendorMapper
        Owner vendor = ownerMapper.selectById(bill.getVendorId());
        if (vendor == null) {
            throw new BusinessException("供应商信息不存在，ID：" + bill.getVendorId());
        }

        if (vendor.getAccountId() == null) {
            throw new BusinessException("供应商未关联应付账款科目，无法过账。请先为供应商关联应付账款科目。");
        }
        
        // 校验往来科目是否存在且有效
        FinAccount payableAccount = accountMapper.selectById(vendor.getAccountId());
        if (payableAccount == null) {
            throw new BusinessException(
                String.format("供应商关联的应付账款科目不存在，科目ID：%d。请检查供应商配置。", vendor.getAccountId()));
        }
        
        // 校验科目类型：供应商必须关联负债类（LIABILITY）科目，如应付账款（2202）
        if (!"LIABILITY".equals(payableAccount.getAccountType())) {
            throw new BusinessException(
                String.format("供应商关联的科目类型错误。供应商必须关联负债类（LIABILITY）科目，当前科目ID：%d，科目代码：%s，科目名称：%s，科目类型：%s。请为供应商配置正确的应付账款科目（如2202）。",
                    payableAccount.getAccountId(), 
                    payableAccount.getAccountCode(), 
                    payableAccount.getAccountName(),
                    payableAccount.getAccountType()));
        }
        
        log.info("供应商往来科目校验通过，供应商：{}，科目ID：{}，科目代码：{}，科目名称：{}，科目类型：{}", 
            vendor.getName(), 
            payableAccount.getAccountId(),
            payableAccount.getAccountCode(), 
            payableAccount.getAccountName(),
            payableAccount.getAccountType());

        // 3. 获取账单条目
        LambdaQueryWrapper<BillItem> itemWrapper = new LambdaQueryWrapper<>();
        itemWrapper.eq(BillItem::getBillId, bill.getBillId());
        List<BillItem> items = billItemMapper.selectList(itemWrapper);

        if (items.isEmpty()) {
            throw new BusinessException("账单没有条目，无法过账");
        }
        
        // 4. 双重检查 - 第二重：校验单据总额 = 明细行金额之和
        BigDecimal itemsTotalAmount = BigDecimal.ZERO;
        BigDecimal itemsTotalTax = BigDecimal.ZERO;
        
        for (BillItem item : items) {
            if (item.getAmount() == null) {
                throw new BusinessException("账单条目金额不能为空，条目描述：" + item.getDescription());
            }
            if (item.getExpenseAccountId() == null) {
                throw new BusinessException("账单条目必须关联费用/资产科目，条目描述：" + item.getDescription());
            }
            
            // 校验费用/资产科目是否存在
            FinAccount expenseAccount = accountMapper.selectById(item.getExpenseAccountId());
            if (expenseAccount == null) {
                throw new BusinessException("账单条目的费用/资产科目不存在，科目ID：" + item.getExpenseAccountId());
            }
            
            itemsTotalAmount = itemsTotalAmount.add(item.getAmount());
            if (item.getTaxAmount() != null) {
                itemsTotalTax = itemsTotalTax.add(item.getTaxAmount());
            }
        }
        
        // 计算明细行总金额（含税）
        BigDecimal itemsTotalWithTax = itemsTotalAmount.add(itemsTotalTax);
        
        // 比较单据总额和明细行金额之和（允许0.01的误差，用于处理浮点数精度问题）
        BigDecimal difference = bill.getTotalAmount().subtract(itemsTotalWithTax).abs();
        if (difference.compareTo(new BigDecimal("0.01")) > 0) {
            throw new BusinessException(
                String.format("单据总额（%s）与明细行金额之和（%s）不一致，差额：%s。请检查账单金额计算。",
                    bill.getTotalAmount(), itemsTotalWithTax, difference));
        }
        
        log.info("双重检查通过 - 单据总额：{}，明细行金额之和：{}", bill.getTotalAmount(), itemsTotalWithTax);

        // 4. 创建交易
        FinTransaction transaction = new FinTransaction();
        transaction.setTransDate(bill.getBillDate());
        transaction.setDescription("账单过账：" + bill.getBillNo());
        transaction.setStatus(0); // 草稿状态，过账后可审核
        transaction.setEnterDate(LocalDateTime.now());
        transaction.setVoucherNo(null);
        transaction.setCurrencyId(bill.getCommodityId());

        List<FinSplit> splits = new ArrayList<>();

        // 贷方：应付账款（供应商关联科目）
        FinSplit payableSplit = new FinSplit();
        payableSplit.setAccountId(vendor.getAccountId());
        payableSplit.setDirection("CREDIT");
        payableSplit.setAmount(bill.getTotalAmount());
        payableSplit.setMemo("应付账款 - 账单：" + bill.getBillNo());
        payableSplit.setOwnerId(bill.getVendorId());
        payableSplit.setOwnerType("VENDOR");
        splits.add(payableSplit);

        // 借方：费用/资产科目
        BigDecimal totalExpense = BigDecimal.ZERO;
        BigDecimal totalTax = BigDecimal.ZERO;

        for (BillItem item : items) {
            if (item.getExpenseAccountId() != null) {
                FinSplit expenseSplit = new FinSplit();
                expenseSplit.setAccountId(item.getExpenseAccountId());
                expenseSplit.setDirection("DEBIT");
                expenseSplit.setAmount(item.getAmount());
                expenseSplit.setMemo(item.getDescription());
                splits.add(expenseSplit);
                totalExpense = totalExpense.add(item.getAmount());
            }

            if (item.getTaxAmount() != null && item.getTaxAmount().compareTo(BigDecimal.ZERO) > 0) {
                totalTax = totalTax.add(item.getTaxAmount());
            }
        }

        // 如果有税费，单独记录进项税
        if (totalTax.compareTo(BigDecimal.ZERO) > 0) {
            // 假设有一个默认的应交税费科目（2221）- 进项税
            FinSplit taxSplit = new FinSplit();
            taxSplit.setAccountId(2221L); // 应交税费科目ID（需要根据实际配置）
            taxSplit.setDirection("DEBIT");
            taxSplit.setAmount(totalTax);
            taxSplit.setMemo("进项税 - 账单：" + bill.getBillNo());
            splits.add(taxSplit);
        }

        transaction.setSplits(splits);

        // 5. 保存交易（这会触发交易服务中的校验）
        transactionService.saveVoucher(transaction);
        
        log.info("会计分录生成成功，交易ID：{}，凭证号：{}", transaction.getTransId(), transaction.getVoucherNo());

        // 6. 更新账单状态为 POSTED，并锁定单据编号
        bill.setStatus(DocumentStatus.POSTED.getCode());
        bill.setPosted(true);
        bill.setTransId(transaction.getTransId());
        // 锁定单据编号：确保编号不为空且唯一
        if (bill.getBillNo() == null || bill.getBillNo().trim().isEmpty()) {
            throw new BusinessException("账单编号不能为空，无法过账");
        }
        billMapper.updateById(bill);
        
        log.info("账单过账成功，ID：{}，编号：{}（已锁定），交易ID：{}", 
            bill.getBillId(), bill.getBillNo(), transaction.getTransId());

        return transaction;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction postCreditNoteToLedger(CreditNote creditNote) {
        // 1. 检查冲销单据状态
        if (creditNote.getPosted() != null && creditNote.getPosted()) {
            throw new BusinessException("冲销单据已过账，无法重复过账");
        }

        // 2. 根据原单据类型创建反向交易
        FinTransaction originalTransaction = transactionMapper.selectById(
            "INVOICE".equals(creditNote.getOriginalDocType()) ?
                getInvoiceTransId(creditNote.getOriginalDocId()) :
                getBillTransId(creditNote.getOriginalDocId())
        );

        if (originalTransaction == null) {
            throw new BusinessException("原单据未找到或未过账");
        }

        // 3. 创建冲销交易（方向相反，金额相同）
        FinTransaction creditTransaction = new FinTransaction();
        creditTransaction.setTransDate(creditNote.getCreditNoteDate());
        creditTransaction.setDescription("冲销：" + creditNote.getCreditNoteNo() + " - " + creditNote.getReason());
        creditTransaction.setStatus(0);
        creditTransaction.setEnterDate(LocalDateTime.now());
        creditTransaction.setVoucherNo(null);

        // 获取原交易的分录并反向
        LambdaQueryWrapper<FinSplit> splitWrapper = new LambdaQueryWrapper<>();
        splitWrapper.eq(FinSplit::getTransId, originalTransaction.getTransId());
        List<FinSplit> originalSplits = splitMapper.selectList(splitWrapper);

        List<FinSplit> creditSplits = new ArrayList<>();
        for (FinSplit originalSplit : originalSplits) {
            FinSplit creditSplit = new FinSplit();
            creditSplit.setAccountId(originalSplit.getAccountId());
            creditSplit.setDirection("DEBIT".equals(originalSplit.getDirection()) ? "CREDIT" : "DEBIT");
            creditSplit.setAmount(originalSplit.getAmount());
            creditSplit.setMemo("冲销：" + originalSplit.getMemo());
            creditSplit.setOwnerId(originalSplit.getOwnerId());
            creditSplit.setOwnerType(originalSplit.getOwnerType());
            creditSplits.add(creditSplit);
        }

        creditTransaction.setSplits(creditSplits);

        // 4. 保存冲销交易
        transactionMapper.insert(creditTransaction);

        for (FinSplit split : creditSplits) {
            split.setTransId(creditTransaction.getTransId());
            splitMapper.insert(split);
        }

        // 5. 更新冲销单据状态
        creditNote.setPosted(true);
        creditNote.setTransId(creditTransaction.getTransId());
        creditNoteMapper.updateById(creditNote);

        return creditTransaction;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unpostInvoice(Long invoiceId) {
        Invoice invoice = invoiceMapper.selectById(invoiceId);
        if (invoice == null) {
            throw new BusinessException("发票不存在");
        }

        if (invoice.getPosted() == null || !invoice.getPosted()) {
            throw new BusinessException("发票未过账，无需撤销");
        }

        if (invoice.getTransId() != null) {
            // 删除关联的交易
            LambdaQueryWrapper<FinSplit> splitWrapper = new LambdaQueryWrapper<>();
            splitWrapper.eq(FinSplit::getTransId, invoice.getTransId());
            splitMapper.delete(splitWrapper);
            transactionMapper.deleteById(invoice.getTransId());
        }

        // 更新发票状态
        invoice.setPosted(false);
        invoice.setTransId(null);
        invoiceMapper.updateById(invoice);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unpostBill(Long billId) {
        Bill bill = billMapper.selectById(billId);
        if (bill == null) {
            throw new BusinessException("账单不存在");
        }

        if (bill.getPosted() == null || !bill.getPosted()) {
            throw new BusinessException("账单未过账，无需撤销");
        }

        if (bill.getTransId() != null) {
            // 删除关联的交易
            LambdaQueryWrapper<FinSplit> splitWrapper = new LambdaQueryWrapper<>();
            splitWrapper.eq(FinSplit::getTransId, bill.getTransId());
            splitMapper.delete(splitWrapper);
            transactionMapper.deleteById(bill.getTransId());
        }

        // 更新账单状态
        bill.setPosted(false);
        bill.setTransId(null);
        billMapper.updateById(bill);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unpostCreditNote(Long creditNoteId) {
        CreditNote creditNote = creditNoteMapper.selectById(creditNoteId);
        if (creditNote == null) {
            throw new BusinessException("冲销单据不存在");
        }

        if (creditNote.getPosted() == null || !creditNote.getPosted()) {
            throw new BusinessException("冲销单据未过账，无需撤销");
        }

        if (creditNote.getTransId() != null) {
            // 删除关联的交易
            LambdaQueryWrapper<FinSplit> splitWrapper = new LambdaQueryWrapper<>();
            splitWrapper.eq(FinSplit::getTransId, creditNote.getTransId());
            splitMapper.delete(splitWrapper);
            transactionMapper.deleteById(creditNote.getTransId());
        }

        // 更新冲销单据状态
        creditNote.setPosted(false);
        creditNote.setTransId(null);
        creditNoteMapper.updateById(creditNote);
    }

    private Long getInvoiceTransId(Long invoiceId) {
        Invoice invoice = invoiceMapper.selectById(invoiceId);
        return invoice != null ? invoice.getTransId() : null;
    }

    private Long getBillTransId(Long billId) {
        Bill bill = billMapper.selectById(billId);
        return bill != null ? bill.getTransId() : null;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction reverseInvoicePosting(Invoice invoice) {
        log.info("开始红冲发票，ID：{}，编号：{}", invoice.getInvoiceId(), invoice.getInvoiceNo());
        
        if (invoice.getTransId() == null) {
            throw new BusinessException("发票未过账，无法红冲");
        }
        
        // 获取原交易
        FinTransaction originalTransaction = transactionMapper.selectById(invoice.getTransId());
        if (originalTransaction == null) {
            throw new BusinessException("原交易不存在，无法红冲");
        }
        
        // 获取原交易的分录
        LambdaQueryWrapper<FinSplit> splitWrapper = new LambdaQueryWrapper<>();
        splitWrapper.eq(FinSplit::getTransId, originalTransaction.getTransId());
        List<FinSplit> originalSplits = splitMapper.selectList(splitWrapper);
        
        if (originalSplits.isEmpty()) {
            throw new BusinessException("原交易没有分录，无法红冲");
        }
        
        // 创建红冲交易（方向相反，金额相同）
        FinTransaction reverseTransaction = new FinTransaction();
        reverseTransaction.setTransDate(invoice.getInvoiceDate());
        reverseTransaction.setDescription("红冲发票：" + invoice.getInvoiceNo());
        reverseTransaction.setStatus(0); // 草稿状态
        reverseTransaction.setEnterDate(LocalDateTime.now());
        reverseTransaction.setVoucherNo(null);
        reverseTransaction.setCurrencyId(invoice.getCommodityId());
        
        List<FinSplit> reverseSplits = new ArrayList<>();
        for (FinSplit originalSplit : originalSplits) {
            FinSplit reverseSplit = new FinSplit();
            reverseSplit.setAccountId(originalSplit.getAccountId());
            // 方向相反
            reverseSplit.setDirection("DEBIT".equals(originalSplit.getDirection()) ? "CREDIT" : "DEBIT");
            reverseSplit.setAmount(originalSplit.getAmount());
            reverseSplit.setMemo("红冲：" + originalSplit.getMemo());
            reverseSplit.setOwnerId(originalSplit.getOwnerId());
            reverseSplit.setOwnerType(originalSplit.getOwnerType());
            reverseSplits.add(reverseSplit);
        }
        
        reverseTransaction.setSplits(reverseSplits);
        
        // 保存红冲交易（这会触发交易服务中的校验）
        transactionService.saveVoucher(reverseTransaction);
        
        log.info("发票红冲成功，原交易ID：{}，红冲交易ID：{}，凭证号：{}", 
            originalTransaction.getTransId(), reverseTransaction.getTransId(), reverseTransaction.getVoucherNo());
        
        return reverseTransaction;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction reverseBillPosting(Bill bill) {
        log.info("开始红冲账单，ID：{}，编号：{}", bill.getBillId(), bill.getBillNo());
        
        if (bill.getTransId() == null) {
            throw new BusinessException("账单未过账，无法红冲");
        }
        
        // 获取原交易
        FinTransaction originalTransaction = transactionMapper.selectById(bill.getTransId());
        if (originalTransaction == null) {
            throw new BusinessException("原交易不存在，无法红冲");
        }
        
        // 获取原交易的分录
        LambdaQueryWrapper<FinSplit> splitWrapper = new LambdaQueryWrapper<>();
        splitWrapper.eq(FinSplit::getTransId, originalTransaction.getTransId());
        List<FinSplit> originalSplits = splitMapper.selectList(splitWrapper);
        
        if (originalSplits.isEmpty()) {
            throw new BusinessException("原交易没有分录，无法红冲");
        }
        
        // 创建红冲交易（方向相反，金额相同）
        FinTransaction reverseTransaction = new FinTransaction();
        reverseTransaction.setTransDate(bill.getBillDate());
        reverseTransaction.setDescription("红冲账单：" + bill.getBillNo());
        reverseTransaction.setStatus(0); // 草稿状态
        reverseTransaction.setEnterDate(LocalDateTime.now());
        reverseTransaction.setVoucherNo(null);
        reverseTransaction.setCurrencyId(bill.getCommodityId());
        
        List<FinSplit> reverseSplits = new ArrayList<>();
        for (FinSplit originalSplit : originalSplits) {
            FinSplit reverseSplit = new FinSplit();
            reverseSplit.setAccountId(originalSplit.getAccountId());
            // 方向相反
            reverseSplit.setDirection("DEBIT".equals(originalSplit.getDirection()) ? "CREDIT" : "DEBIT");
            reverseSplit.setAmount(originalSplit.getAmount());
            reverseSplit.setMemo("红冲：" + originalSplit.getMemo());
            reverseSplit.setOwnerId(originalSplit.getOwnerId());
            reverseSplit.setOwnerType(originalSplit.getOwnerType());
            reverseSplits.add(reverseSplit);
        }
        
        reverseTransaction.setSplits(reverseSplits);
        
        // 保存红冲交易（这会触发交易服务中的校验）
        transactionService.saveVoucher(reverseTransaction);
        
        log.info("账单红冲成功，原交易ID：{}，红冲交易ID：{}，凭证号：{}", 
            originalTransaction.getTransId(), reverseTransaction.getTransId(), reverseTransaction.getVoucherNo());
        
        return reverseTransaction;
    }
}
