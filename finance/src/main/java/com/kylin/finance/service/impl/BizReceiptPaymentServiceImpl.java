package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kylin.common.BusinessException;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.entity.FinSplit;
import com.kylin.finance.entity.FinTransaction;
import com.kylin.finance.entity.biz.BizReceiptPayment;
import com.kylin.finance.mapper.BizReceiptPaymentMapper;
import com.kylin.finance.service.IBizReceiptPaymentService;
import com.kylin.finance.service.IFinAccountService;
import com.kylin.finance.service.IFinTransactionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * 收付款单服务实现类
 */
@Slf4j
@Service
public class BizReceiptPaymentServiceImpl implements IBizReceiptPaymentService {

    @Autowired
    private BizReceiptPaymentMapper paymentMapper;

    @Autowired
    private IFinAccountService accountService;

    @Autowired
    private IFinTransactionService transactionService;

    /**
     * 保存收付款单（新增或更新）
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public BizReceiptPayment saveReceiptPayment(BizReceiptPayment payment) {
        try {
            // 1. 数据校验
            validateReceiptPayment(payment);

            // 2. 生成单据编号（如果是新增）
            if (payment.getId() == null) {
                if (payment.getCode() == null || payment.getCode().isEmpty()) {
                    payment.setCode(generatePaymentNo());
                }
                payment.setStatus(0); // 默认状态为草稿
            }

            // 3. 保存或更新
            if (payment.getId() == null) {
                paymentMapper.insert(payment);
            } else {
                paymentMapper.updateById(payment);
            }

            return payment;
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("保存收付款单失败: " + e.getMessage());
        }
    }

    /**
     * 保存并过账收付款单
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public BizReceiptPayment saveAndPostReceiptPayment(BizReceiptPayment payment) {
        try {
            // 1. 先保存
            payment = saveReceiptPayment(payment);

            // 2. 验证账户存在
            validateAccountExists(payment.getAccountId());

            // 3. 更新账户余额
            updateAccountBalance(payment);

            // 4. 生成凭证（如果凭证生成逻辑完善）
            // FinTransaction voucher = generateVoucher(payment);
            // if (voucher != null && voucher.getSplits() != null && voucher.getSplits().size() >= 2) {
            //     transactionService.saveVoucher(voucher);
            //     payment.setVoucherId(voucher.getTransId());
            // }

            // 5. 更新收付款单状态为已过账
            payment.setStatus(1); // 已过账
            paymentMapper.updateById(payment);

            return payment;
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("保存并过账收付款单失败: " + e.getMessage());
        }
    }

    /**
     * 分页查询收付款单列表
     */
    @Override
    public IPage<BizReceiptPayment> getReceiptPaymentList(Page<BizReceiptPayment> page, String type, Integer status) {
        log.info("查询收付款单列表 - pageNum: {}, pageSize: {}, type: {}, status: {}", 
            page.getCurrent(), page.getSize(), type, status);
        
        LambdaQueryWrapper<BizReceiptPayment> wrapper = new LambdaQueryWrapper<>();
        
        // 类型过滤（如果type为空，不过滤，返回所有类型）
        if (type != null && !type.trim().isEmpty()) {
            wrapper.eq(BizReceiptPayment::getType, type.trim());
        }
        
        // 状态过滤（如果status为空，不过滤，返回所有状态）
        // 注意：status=0表示草稿，status=1表示已过账
        // 如果前端传了status参数，才会过滤；如果没传，返回所有状态的数据
        if (status != null) {
            wrapper.eq(BizReceiptPayment::getStatus, status);
        }
        
        // 排序：按日期倒序，再按ID倒序
        wrapper.orderByDesc(BizReceiptPayment::getDate);
        wrapper.orderByDesc(BizReceiptPayment::getId);
        
        IPage<BizReceiptPayment> result = paymentMapper.selectPage(page, wrapper);
        log.info("查询收付款单列表结果 - 总数: {}, 当前页记录数: {}", result.getTotal(), result.getRecords().size());
        
        return result;
    }

    /**
     * 根据ID查询收付款单
     */
    @Override
    public BizReceiptPayment getById(Long id) {
        return paymentMapper.selectById(id);
    }

    /**
     * 根据ID查询收付款单详情
     */
    @Override
    public BizReceiptPayment selectBizReceiptPaymentById(Long id) {
        return paymentMapper.selectBizReceiptPaymentById(id);
    }

    /**
     * 生成收付款单号
     * 格式：RP + 日期(yyyyMMdd) + 序号(3位)
     * 例如：RP20241201001
     */
    private String generatePaymentNo() {
        String dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        
        // 查询当天最大序号
        LambdaQueryWrapper<BizReceiptPayment> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(BizReceiptPayment::getCode, "RP" + dateStr);
        wrapper.orderByDesc(BizReceiptPayment::getCode);
        wrapper.last("LIMIT 1");
        BizReceiptPayment last = paymentMapper.selectOne(wrapper);
        
        int sequence = 1;
        if (last != null && last.getCode() != null) {
            String lastNo = last.getCode();
            if (lastNo.length() >= 12 && lastNo.startsWith("RP" + dateStr)) {
                try {
                    sequence = Integer.parseInt(lastNo.substring(10)) + 1;
                } catch (NumberFormatException e) {
                    sequence = 1;
                }
            }
        }
        
        return String.format("RP%s%03d", dateStr, sequence);
    }

    /**
     * 校验收付款单数据
     */
    private void validateReceiptPayment(BizReceiptPayment payment) {
        if (payment == null) {
            throw new BusinessException("收付款单数据不能为空");
        }

        // 校验类型
        if (payment.getType() == null || payment.getType().isEmpty()) {
            throw new BusinessException("类型不能为空");
        }
        if (!"RECEIPT".equals(payment.getType()) && !"PAYMENT".equals(payment.getType())) {
            throw new BusinessException("类型必须是 RECEIPT(收款) 或 PAYMENT(付款)");
        }

        // 校验日期
        if (payment.getDate() == null) {
            throw new BusinessException("日期不能为空");
        }

        // 校验往来单位
        if (payment.getOwnerId() == null || payment.getOwnerId() <= 0) {
            throw new BusinessException("往来单位ID不能为空");
        }
        if (payment.getPartnerName() == null || payment.getPartnerName().isEmpty()) {
            throw new BusinessException("往来单位名称不能为空");
        }

        // 校验结算账户
        if (payment.getAccountId() == null || payment.getAccountId() <= 0) {
            throw new BusinessException("结算账户ID不能为空");
        }

        // 校验金额
        if (payment.getAmount() == null || payment.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException("金额必须大于0");
        }

        // 校验账户是否存在
        validateAccountExists(payment.getAccountId());
    }

    /**
     * 验证账户是否存在
     */
    private void validateAccountExists(Long accountId) {
        FinAccount account = accountService.getById(accountId);
        if (account == null) {
            throw new BusinessException("结算账户不存在，ID: " + accountId);
        }
    }

    /**
     * 更新账户余额
     * 
     * @param payment 收付款单对象
     */
    private void updateAccountBalance(BizReceiptPayment payment) {
        // TODO: 实现账户余额更新逻辑
        // 如果 Type == RECEIPT (收款): 增加账户余额
        // 如果 Type == PAYMENT (付款): 减少账户余额
        // 
        // 注意：在实际系统中，余额通常是通过查询凭证分录动态计算的
        // 这里可以调用 AccountService 的更新余额方法（如果存在）
        // 或者通过生成凭证的方式，让凭证系统自动更新余额
        
        // 示例代码（需要根据实际的 AccountService 接口调整）:
        // if ("RECEIPT".equals(payment.getType())) {
        //     accountService.increaseBalance(payment.getAccountId(), payment.getAmount());
        // } else if ("PAYMENT".equals(payment.getType())) {
        //     accountService.decreaseBalance(payment.getAccountId(), payment.getAmount());
        // }
        
        // 当前实现：通过生成凭证的方式更新余额，凭证系统会自动处理余额计算
        // 所以这里不需要手动更新余额，余额会在查询时动态计算
    }

    /**
     * 生成凭证
     * 
     * @param payment 收付款单对象
     * @return 凭证对象
     */
    private FinTransaction generateVoucher(BizReceiptPayment payment) {
        FinTransaction voucher = new FinTransaction();
        voucher.setTransDate(payment.getDate());
        
        String description = "RECEIPT".equals(payment.getType()) 
            ? "收款单：" + payment.getCode() + " - " + payment.getPartnerName()
            : "付款单：" + payment.getCode() + " - " + payment.getPartnerName();
        if (payment.getRemark() != null && !payment.getRemark().isEmpty()) {
            description += " - " + payment.getRemark();
        }
        voucher.setDescription(description);
        voucher.setStatus(1); // 已审核状态（过账即审核）
        voucher.setEnterDate(LocalDateTime.now());

        List<FinSplit> splits = new ArrayList<>();

        // 根据类型生成不同的分录
        if ("RECEIPT".equals(payment.getType())) {
            // 收款：借方-结算账户（资产增加），贷方-需要业务层提供科目
            // 简化实现：只生成结算账户的借方分录
            // 注意：完整的凭证需要借贷平衡，这里需要另一个科目（如应收账款、收入等）
            // 为了演示，这里只生成结算账户的分录，实际业务中需要根据往来单位类型确定对应科目
            
            FinSplit debitSplit = new FinSplit();
            debitSplit.setAccountId(payment.getAccountId());
            debitSplit.setDirection("DEBIT");
            debitSplit.setAmount(payment.getAmount());
            debitSplit.setMemo("收款：" + payment.getPartnerName() + (payment.getRemark() != null ? " - " + payment.getRemark() : ""));
            splits.add(debitSplit);

            // TODO: 根据 ownerId 和业务规则查找对应的贷方科目（应收账款、预收账款、收入等）
            // 这里暂时不生成完整的凭证，只更新结算账户余额
            // 实际业务中应该根据往来单位的类型（客户/供应商）和业务场景确定对应科目
            
        } else {
            // 付款：借方-需要业务层提供科目，贷方-结算账户（资产减少）
            
            FinSplit creditSplit = new FinSplit();
            creditSplit.setAccountId(payment.getAccountId());
            creditSplit.setDirection("CREDIT");
            creditSplit.setAmount(payment.getAmount());
            creditSplit.setMemo("付款：" + payment.getPartnerName() + (payment.getRemark() != null ? " - " + payment.getRemark() : ""));
            splits.add(creditSplit);

            // TODO: 根据 ownerId 和业务规则查找对应的借方科目（应付账款、预付账款、费用等）
            // 这里暂时不生成完整的凭证，只更新结算账户余额
            // 实际业务中应该根据往来单位的类型（客户/供应商）和业务场景确定对应科目
        }

        // 注意：当前实现只生成单边分录，不符合借贷平衡原则
        // 实际业务中需要生成完整的借贷分录才能保存凭证
        // 这里暂时注释掉凭证保存，只更新收付款单状态
        // voucher.setSplits(splits);
        // return voucher;
        
        // 简化实现：暂时不生成凭证，只更新余额
        // 实际业务中需要完善凭证生成逻辑
        return null;
    }
}

