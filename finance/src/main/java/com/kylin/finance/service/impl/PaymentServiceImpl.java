package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.kylin.common.BusinessException;
import com.kylin.finance.entity.*;
import com.kylin.finance.entity.business.Customer;
import com.kylin.finance.entity.business.Vendor;
import com.kylin.finance.entity.business.Owner;
import com.kylin.finance.entity.document.Invoice;
import com.kylin.finance.entity.document.Bill;
import com.kylin.finance.entity.payment.Payment;
import com.kylin.finance.entity.payment.PaymentAllocation;
import com.kylin.finance.mapper.*;
import com.kylin.finance.service.IPaymentService;
import com.kylin.finance.service.IFinTransactionService;
import com.kylin.finance.entity.FinTransaction;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 支付处理服务实现
 */
@Service
public class PaymentServiceImpl implements IPaymentService {

    @Autowired
    private PaymentMapper paymentMapper;

    @Autowired
    private PaymentAllocationMapper allocationMapper;

    @Autowired
    private InvoiceMapper invoiceMapper;

    @Autowired
    private BillMapper billMapper;

    @Autowired
    private CustomerMapper customerMapper;

    @Autowired
    private VendorMapper vendorMapper;

    @Autowired
    private OwnerMapper ownerMapper;

    @Autowired
    private IFinTransactionService transactionService;

    @Autowired
    private FinSplitMapper splitMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Payment processCustomerPayment(Owner owner, BigDecimal amount, Long accountId) {
        if (owner == null || amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException("支付参数无效");
        }

        // 查询该客户所有未结清的发票（OPEN 或 PARTIAL 状态），按创建时间升序排列
        LambdaQueryWrapper<Invoice> invoiceWrapper = new LambdaQueryWrapper<>();
        invoiceWrapper.eq(Invoice::getCustomerId, owner.getOwnerId())
                     .in(Invoice::getStatus, "OPEN", "PARTIAL")
                     .orderByAsc(Invoice::getCreateTime);

        List<Invoice> unpaidInvoices = invoiceMapper.selectList(invoiceWrapper);

        if (unpaidInvoices.isEmpty()) {
            throw new BusinessException("该客户没有未结清的发票");
        }

        // 计算所有欠款总和
        BigDecimal totalUnpaidAmount = unpaidInvoices.stream()
            .map(invoice -> calculateUnpaidAmount(invoice))
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 检查支付金额是否超过欠款总和
        if (amount.compareTo(totalUnpaidAmount) > 0) {
            throw new BusinessException("支付金额 " + amount + " 超过欠款总和 " + totalUnpaidAmount);
        }

        // 创建支付记录
        Payment payment = new Payment();
        payment.setPaymentNo(generatePaymentNo());
        payment.setPaymentDate(LocalDate.now());
        payment.setPaymentType("RECEIPT");
        payment.setOwnerId(owner.getOwnerId());
        payment.setAccountId(accountId);
        payment.setAmount(amount);
        payment.setStatus("CLEARED");
        payment.setPosted(false);

        // 保存支付记录
        paymentMapper.insert(payment);

        // 循环抵扣发票金额
        BigDecimal remainingAmount = amount;
        List<PaymentAllocation> allocations = new ArrayList<>();

        for (Invoice invoice : unpaidInvoices) {
            if (remainingAmount.compareTo(BigDecimal.ZERO) <= 0) {
                break;
            }

            BigDecimal unpaidAmount = calculateUnpaidAmount(invoice);
            if (unpaidAmount.compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }

            BigDecimal allocationAmount = remainingAmount.min(unpaidAmount);

            // 创建分配记录
            PaymentAllocation allocation = new PaymentAllocation();
            allocation.setPaymentId(payment.getPaymentId());
            allocation.setDocumentType("INVOICE");
            allocation.setDocumentId(invoice.getInvoiceId());
            allocation.setAmount(allocationAmount);
            allocation.setPreviousUnpaidAmount(unpaidAmount);
            allocation.setRemainingUnpaidAmount(unpaidAmount.subtract(allocationAmount));
            allocation.setAllocationStatus(
                allocationAmount.compareTo(unpaidAmount) >= 0 ? "FULL" : "PARTIAL"
            );

            allocations.add(allocation);

            // 注意：贷方分录（应收账款的贷方，资产减少）将在 postPaymentToLedger 时创建
            // 这里只创建分配记录，不创建分录

            // 更新发票状态
            if (allocation.getRemainingUnpaidAmount().compareTo(BigDecimal.ZERO) == 0) {
                invoice.setStatus("PAID");
            } else {
                invoice.setStatus("PARTIAL");
            }
            invoiceMapper.updateById(invoice);

            remainingAmount = remainingAmount.subtract(allocationAmount);
        }

        // 保存分配记录
        for (PaymentAllocation allocation : allocations) {
            allocationMapper.insert(allocation);
        }

        // 注意：贷方分录信息通过 PaymentAllocation 记录关联
        // 在 postPaymentToLedger 时，会根据 PaymentAllocation 记录重新创建贷方分录

        return payment;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Payment processVendorPayment(Owner owner, BigDecimal amount, Long accountId) {
        if (owner == null || amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException("支付参数无效");
        }

        // 从数据库获取供应商信息（确保 accountId 等字段已加载）
        Owner vendorOwner = ownerMapper.selectById(owner.getOwnerId());
        if (vendorOwner == null || !"VENDOR".equals(vendorOwner.getOwnerType())) {
            throw new BusinessException("供应商不存在或类型不匹配");
        }

        // 查询该供应商所有未结清的账单（OPEN 或 PARTIAL 状态），按创建时间升序排列
        LambdaQueryWrapper<Bill> billWrapper = new LambdaQueryWrapper<>();
        billWrapper.eq(Bill::getVendorId, vendorOwner.getOwnerId())
                   .in(Bill::getStatus, "OPEN", "PARTIAL")
                   .orderByAsc(Bill::getCreateTime);

        List<Bill> unpaidBills = billMapper.selectList(billWrapper);

        if (unpaidBills.isEmpty()) {
            throw new BusinessException("该供应商没有未结清的账单");
        }

        // 计算所有欠款总和
        BigDecimal totalUnpaidAmount = unpaidBills.stream()
            .map(bill -> calculateUnpaidAmount(bill))
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 检查支付金额是否超过欠款总和
        if (amount.compareTo(totalUnpaidAmount) > 0) {
            throw new BusinessException("支付金额 " + amount + " 超过欠款总和 " + totalUnpaidAmount);
        }

        // 创建支付记录
        Payment payment = new Payment();
        payment.setPaymentNo(generatePaymentNo());
        payment.setPaymentDate(LocalDate.now());
        payment.setPaymentType("PAYMENT");
        payment.setOwnerId(vendorOwner.getOwnerId());
        payment.setAccountId(accountId);
        payment.setAmount(amount);
        payment.setStatus("CLEARED");
        payment.setPosted(false);

        // 保存支付记录
        paymentMapper.insert(payment);

        // 循环抵扣账单金额
        BigDecimal remainingAmount = amount;
        List<PaymentAllocation> allocations = new ArrayList<>();

        for (Bill bill : unpaidBills) {
            if (remainingAmount.compareTo(BigDecimal.ZERO) <= 0) {
                break;
            }

            BigDecimal unpaidAmount = calculateUnpaidAmount(bill);
            if (unpaidAmount.compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }

            BigDecimal allocationAmount = remainingAmount.min(unpaidAmount);

            // 创建分配记录
            PaymentAllocation allocation = new PaymentAllocation();
            allocation.setPaymentId(payment.getPaymentId());
            allocation.setDocumentType("BILL");
            allocation.setDocumentId(bill.getBillId());
            allocation.setAmount(allocationAmount);
            allocation.setPreviousUnpaidAmount(unpaidAmount);
            allocation.setRemainingUnpaidAmount(unpaidAmount.subtract(allocationAmount));
            allocation.setAllocationStatus(
                allocationAmount.compareTo(unpaidAmount) >= 0 ? "FULL" : "PARTIAL"
            );

            allocations.add(allocation);

            // 注意：借方分录（应付账款的借方，负债减少）将在 postPaymentToLedger 时创建
            // 这里只创建分配记录，不创建分录

            // 更新账单状态
            if (allocation.getRemainingUnpaidAmount().compareTo(BigDecimal.ZERO) == 0) {
                bill.setStatus("PAID");
            } else {
                bill.setStatus("PARTIAL");
            }
            billMapper.updateById(bill);

            remainingAmount = remainingAmount.subtract(allocationAmount);
        }

        // 保存分配记录
        for (PaymentAllocation allocation : allocations) {
            allocationMapper.insert(allocation);
        }

        return payment;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Payment processPayment(Owner owner, BigDecimal amount, Long accountId, String paymentType) {
        // 保留原有方法作为备用
        if (owner == null || amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException("支付参数无效");
        }

        // 创建支付记录
        Payment payment = new Payment();
        payment.setPaymentNo(generatePaymentNo());
        payment.setPaymentDate(LocalDate.now());
        payment.setPaymentType(paymentType);
        payment.setOwnerId(owner.getOwnerId());
        payment.setAccountId(accountId);
        payment.setAmount(amount);
        payment.setStatus("CLEARED");
        payment.setPosted(false);

        // 保存支付记录
        paymentMapper.insert(payment);

        return payment;
    }

    /**
     * 计算单据的未结清金额
     */
    private BigDecimal calculateUnpaidAmount(Object document) {
        BigDecimal totalAmount = BigDecimal.ZERO;
        Long documentId = null;

        if (document instanceof Invoice) {
            Invoice invoice = (Invoice) document;
            totalAmount = invoice.getTotalAmount();
            documentId = invoice.getInvoiceId();
        } else if (document instanceof Bill) {
            Bill bill = (Bill) document;
            totalAmount = bill.getTotalAmount();
            documentId = bill.getBillId();
        }

        if (documentId == null) {
            return BigDecimal.ZERO;
        }

        // 计算已分配的支付金额
        LambdaQueryWrapper<PaymentAllocation> allocationWrapper = new LambdaQueryWrapper<>();
        allocationWrapper.eq(PaymentAllocation::getDocumentId, documentId);

        List<PaymentAllocation> allocations = allocationMapper.selectList(allocationWrapper);
        BigDecimal allocatedAmount = allocations.stream()
            .map(PaymentAllocation::getAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        return totalAmount.subtract(allocatedAmount);
    }

    /**
     * 获取客户的应收账款科目ID
     */
    private Long getCustomerReceivableAccountId(Long ownerId) {
        Owner owner = ownerMapper.selectById(ownerId);
        if (owner != null && owner.getAccountId() != null) {
            return owner.getAccountId();
        }
        // 默认应收账款科目ID (1122 - 应收账款)
        return 1122L;
    }

    /**
     * 获取供应商的应付账款科目ID
     */
    private Long getVendorPayableAccountId(Long ownerId) {
        Owner owner = ownerMapper.selectById(ownerId);
        if (owner != null && owner.getAccountId() != null) {
            return owner.getAccountId();
        }
        // 默认应付账款科目ID (2202 - 应付账款)
        return 2202L;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void performLotTracking(Payment payment) {
        // 核销逻辑现在在 processCustomerPayment 中实现
        // 此方法保留用于可能的扩展或供应商付款逻辑
        if (payment == null || payment.getAmount() == null) {
            return;
        }

        // 对于供应商付款，可以在这里实现类似的核销逻辑
        if ("PAYMENT".equals(payment.getPaymentType())) {
            // TODO: 实现供应商付款的核销逻辑
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction postPaymentToLedger(Payment payment) {
        if (payment.getPosted() != null && payment.getPosted()) {
            throw new BusinessException("支付已过账，无法重复过账");
        }

        // 创建交易
        FinTransaction transaction = new FinTransaction();
        transaction.setTransDate(payment.getPaymentDate());
        transaction.setDescription("支付过账：" + payment.getPaymentNo());
        transaction.setStatus(0); // 草稿状态
        transaction.setEnterDate(LocalDateTime.now());
        transaction.setVoucherNo(null);

        List<FinSplit> splits = new ArrayList<>();

        if ("RECEIPT".equals(payment.getPaymentType())) {
            // 客户收款（RECEIPT）：
            // 借：银行存款（资产增加）
            // 贷：应收账款（资产减少）
            
            // 获取该支付的所有分配记录，用于创建对应的贷方分录
            LambdaQueryWrapper<PaymentAllocation> allocationWrapper = new LambdaQueryWrapper<>();
            allocationWrapper.eq(PaymentAllocation::getPaymentId, payment.getPaymentId());
            List<PaymentAllocation> allocations = allocationMapper.selectList(allocationWrapper);
            
            // 创建借方分录：银行存款
            FinSplit debitSplit = new FinSplit();
            debitSplit.setAccountId(payment.getAccountId()); // 银行存款
            debitSplit.setDirection("DEBIT");
            debitSplit.setAmount(payment.getAmount());
            debitSplit.setMemo("客户收款：" + payment.getPaymentNo());
            splits.add(debitSplit);
            
            // 创建贷方分录：应收账款（根据分配记录创建多条分录）
            Owner owner = ownerMapper.selectById(payment.getOwnerId());
            Long receivableAccountId = getCustomerReceivableAccountId(payment.getOwnerId());
            
            for (PaymentAllocation allocation : allocations) {
                FinSplit creditSplit = new FinSplit();
                creditSplit.setAccountId(receivableAccountId); // 应收账款科目
                creditSplit.setDirection("CREDIT");
                creditSplit.setAmount(allocation.getAmount());
                
                // 获取单据编号
                String documentNo = "";
                if ("INVOICE".equals(allocation.getDocumentType())) {
                    Invoice invoice = invoiceMapper.selectById(allocation.getDocumentId());
                    if (invoice != null) {
                        documentNo = invoice.getInvoiceNo();
                    }
                }
                
                creditSplit.setMemo("客户收款核销 - 发票：" + documentNo);
                creditSplit.setOwnerId(payment.getOwnerId());
                creditSplit.setOwnerType("CUSTOMER");
                splits.add(creditSplit);
            }
            
        } else if ("PAYMENT".equals(payment.getPaymentType())) {
            // 供应商付款（PAYMENT）：
            // 借：应付账款（负债减少）
            // 贷：银行存款（资产减少）
            
            // 获取该支付的所有分配记录，用于创建对应的借方分录
            LambdaQueryWrapper<PaymentAllocation> allocationWrapper = new LambdaQueryWrapper<>();
            allocationWrapper.eq(PaymentAllocation::getPaymentId, payment.getPaymentId());
            List<PaymentAllocation> allocations = allocationMapper.selectList(allocationWrapper);
            
            // 创建借方分录：应付账款（根据分配记录创建多条分录）
            Owner owner = ownerMapper.selectById(payment.getOwnerId());
            Long payableAccountId = getVendorPayableAccountId(payment.getOwnerId());
            
            for (PaymentAllocation allocation : allocations) {
                FinSplit debitSplit = new FinSplit();
                debitSplit.setAccountId(payableAccountId); // 应付账款科目
                debitSplit.setDirection("DEBIT");
                debitSplit.setAmount(allocation.getAmount());
                
                // 获取单据编号
                String documentNo = "";
                if ("BILL".equals(allocation.getDocumentType())) {
                    Bill bill = billMapper.selectById(allocation.getDocumentId());
                    if (bill != null) {
                        documentNo = bill.getBillNo();
                    }
                }
                
                debitSplit.setMemo("供应商付款核销 - 账单：" + documentNo);
                debitSplit.setOwnerId(payment.getOwnerId());
                debitSplit.setOwnerType("VENDOR");
                splits.add(debitSplit);
            }
            
            // 创建贷方分录：银行存款
            FinSplit creditSplit = new FinSplit();
            creditSplit.setAccountId(payment.getAccountId()); // 银行存款
            creditSplit.setDirection("CREDIT");
            creditSplit.setAmount(payment.getAmount());
            creditSplit.setMemo("供应商付款：" + payment.getPaymentNo());
            splits.add(creditSplit);
        }

        transaction.setSplits(splits);

        // 保存交易
        transactionService.saveVoucher(transaction);

        // 更新支付状态
        payment.setPosted(true);
        payment.setTransId(transaction.getTransId());
        paymentMapper.updateById(payment);

        return transaction;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unpostPayment(Long paymentId) {
        Payment payment = paymentMapper.selectById(paymentId);
        if (payment == null) {
            throw new BusinessException("支付记录不存在");
        }

        if (payment.getPosted() == null || !payment.getPosted()) {
            throw new BusinessException("支付未过账，无需撤销");
        }

        if (payment.getTransId() != null) {
            // 删除关联的交易和分录
            transactionService.deleteVoucher(payment.getTransId());
        }

        // 删除支付分配记录
        LambdaUpdateWrapper<PaymentAllocation> allocationWrapper = new LambdaUpdateWrapper<>();
        allocationWrapper.eq(PaymentAllocation::getPaymentId, paymentId);
        allocationMapper.delete(allocationWrapper);

        // 重置单据状态（这里简化处理，实际应该重新计算）
        // TODO: 实现更复杂的状态重置逻辑

        // 更新支付状态
        payment.setPosted(false);
        payment.setTransId(null);
        paymentMapper.updateById(payment);
    }

    @Override
    public BigDecimal getUnpaidAmount(Long ownerId) {
        if (ownerId == null) {
            return BigDecimal.ZERO;
        }

        BigDecimal totalInvoiceAmount = BigDecimal.ZERO;
        BigDecimal totalBillAmount = BigDecimal.ZERO;

        // 计算发票未结清金额
        LambdaQueryWrapper<Invoice> invoiceWrapper = new LambdaQueryWrapper<>();
        invoiceWrapper.eq(Invoice::getCustomerId, ownerId)
                     .ne(Invoice::getStatus, "PAID");

        List<Invoice> invoices = invoiceMapper.selectList(invoiceWrapper);
        for (Invoice invoice : invoices) {
            totalInvoiceAmount = totalInvoiceAmount.add(calculateUnpaidAmount(invoice));
        }

        // 计算账单未结清金额
        LambdaQueryWrapper<Bill> billWrapper = new LambdaQueryWrapper<>();
        billWrapper.eq(Bill::getVendorId, ownerId)
                  .ne(Bill::getStatus, "PAID");

        List<Bill> bills = billMapper.selectList(billWrapper);
        for (Bill bill : bills) {
            totalBillAmount = totalBillAmount.add(calculateUnpaidAmount(bill));
        }

        // 对于客户，返回应收金额；对于供应商，返回应付金额
        return totalInvoiceAmount.add(totalBillAmount);
    }

    /**
     * 生成支付编号
     */
    private String generatePaymentNo() {
        // 简化实现，实际应该考虑并发和格式化
        return "PAY-" + System.currentTimeMillis();
    }

    @Override
    public java.util.List<com.kylin.finance.dto.PaymentAllocationResultDTO> getPaymentAllocations(Long paymentId) {
        LambdaQueryWrapper<PaymentAllocation> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(PaymentAllocation::getPaymentId, paymentId);
        List<PaymentAllocation> allocations = allocationMapper.selectList(wrapper);

        java.util.List<com.kylin.finance.dto.PaymentAllocationResultDTO> results = new java.util.ArrayList<>();
        
        for (PaymentAllocation allocation : allocations) {
            com.kylin.finance.dto.PaymentAllocationResultDTO dto = 
                new com.kylin.finance.dto.PaymentAllocationResultDTO();
            
            // 获取单据编号
            if ("INVOICE".equals(allocation.getDocumentType())) {
                Invoice invoice = invoiceMapper.selectById(allocation.getDocumentId());
                if (invoice != null) {
                    dto.setDocumentNo(invoice.getInvoiceNo());
                }
            } else if ("BILL".equals(allocation.getDocumentType())) {
                Bill bill = billMapper.selectById(allocation.getDocumentId());
                if (bill != null) {
                    dto.setDocumentNo(bill.getBillNo());
                }
            }
            
            dto.setAmount(allocation.getAmount());
            dto.setStatus("FULL".equals(allocation.getAllocationStatus()) ? "PAID" : "PARTIAL");
            dto.setRemainingAmount(allocation.getRemainingUnpaidAmount());
            
            results.add(dto);
        }
        
        return results;
    }
}
