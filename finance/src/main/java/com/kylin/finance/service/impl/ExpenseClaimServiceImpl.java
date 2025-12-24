package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.kylin.common.BusinessException;
import com.kylin.finance.entity.*;
import com.kylin.finance.entity.business.Employee;
import com.kylin.finance.entity.expense.ExpenseClaim;
import com.kylin.finance.entity.expense.ExpenseClaimItem;
import com.kylin.finance.mapper.*;
import com.kylin.finance.service.IExpenseClaimService;
import com.kylin.finance.service.IFinTransactionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 员工报销服务实现
 */
@Service
public class ExpenseClaimServiceImpl implements IExpenseClaimService {

    @Autowired
    private ExpenseClaimMapper claimMapper;

    @Autowired
    private ExpenseClaimItemMapper claimItemMapper;

    @Autowired
    private EmployeeMapper employeeMapper;

    @Autowired
    private IFinTransactionService transactionService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ExpenseClaim submitClaim(ExpenseClaim claim) {
        if (claim == null) {
            throw new BusinessException("报销单不能为空");
        }

        // 生成报销单编号
        if (claim.getClaimNo() == null) {
            claim.setClaimNo(generateClaimNo());
        }

        // 设置初始状态
        claim.setApprovalStatus("PENDING");
        claim.setClaimDate(LocalDate.now());
        claim.setPosted(false);

        // 保存报销单
        claimMapper.insert(claim);

        // 保存报销明细
        if (claim.getItems() != null && !claim.getItems().isEmpty()) {
            for (ExpenseClaimItem item : claim.getItems()) {
                item.setClaimId(claim.getClaimId());
                claimItemMapper.insert(item);
            }
        }

        return claim;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ExpenseClaim approveClaim(Long claimId, Long approverId, Boolean approved, String comment) {
        ExpenseClaim claim = claimMapper.selectById(claimId);
        if (claim == null) {
            throw new BusinessException("报销单不存在");
        }

        if (!"PENDING".equals(claim.getApprovalStatus())) {
            throw new BusinessException("报销单状态不允许审批");
        }

        claim.setApproverId(approverId);
        claim.setApprovalDate(LocalDate.now());
        claim.setApprovalComment(comment);
        claim.setApprovalStatus(approved ? "APPROVED" : "REJECTED");

        claimMapper.updateById(claim);

        return claim;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction postClaimToLedger(Long claimId) {
        ExpenseClaim claim = claimMapper.selectById(claimId);
        if (claim == null) {
            throw new BusinessException("报销单不存在");
        }

        if (!"APPROVED".equals(claim.getApprovalStatus())) {
            throw new BusinessException("只有已审批的报销单才能过账");
        }

        if (claim.getPosted() != null && claim.getPosted()) {
            throw new BusinessException("报销单已过账，无法重复过账");
        }

        // 获取报销明细
        LambdaQueryWrapper<ExpenseClaimItem> itemWrapper = new LambdaQueryWrapper<>();
        itemWrapper.eq(ExpenseClaimItem::getClaimId, claimId);
        List<ExpenseClaimItem> items = claimItemMapper.selectList(itemWrapper);

        if (items.isEmpty()) {
            throw new BusinessException("报销单没有明细，无法过账");
        }

        // 创建交易
        FinTransaction transaction = new FinTransaction();
        transaction.setTransDate(claim.getClaimDate());
        transaction.setDescription("员工报销：" + claim.getClaimNo());
        transaction.setStatus(0); // 草稿状态
        transaction.setEnterDate(LocalDateTime.now());
        transaction.setVoucherNo(null);

        List<FinSplit> splits = new ArrayList<>();

        // 借方：管理费用（按明细科目汇总）
        for (ExpenseClaimItem item : items) {
            FinSplit debitSplit = new FinSplit();
            debitSplit.setAccountId(item.getExpenseAccountId());
            debitSplit.setDirection("DEBIT");
            debitSplit.setAmount(item.getAmount());
            debitSplit.setMemo(item.getDescription());
            splits.add(debitSplit);
        }

        // 贷方：其他应付款-员工
        Employee employee = employeeMapper.selectById(claim.getEmployeeId());
        Long payableAccountId = getEmployeePayableAccountId(employee);

        FinSplit creditSplit = new FinSplit();
        creditSplit.setAccountId(payableAccountId); // 其他应付款-员工
        creditSplit.setDirection("CREDIT");
        creditSplit.setAmount(claim.getTotalAmount());
        creditSplit.setMemo("员工报销：" + claim.getClaimNo());
        creditSplit.setOwnerId(claim.getEmployeeId());
        creditSplit.setOwnerType("EMPLOYEE");
        splits.add(creditSplit);

        transaction.setSplits(splits);

        // 保存交易
        transactionService.saveVoucher(transaction);

        // 更新报销单状态
        claim.setPosted(true);
        claim.setTransId(transaction.getTransId());
        claim.setApprovalStatus("POSTED");
        claimMapper.updateById(claim);

        return transaction;
    }

    /**
     * 获取员工的其他应付款科目ID
     */
    private Long getEmployeePayableAccountId(Employee employee) {
        if (employee != null && employee.getAccountId() != null) {
            return employee.getAccountId();
        }
        // 默认其他应付款科目ID (2241 - 其他应付款)
        return 2241L;
    }

    /**
     * 生成报销单编号
     */
    private String generateClaimNo() {
        return "EXP-" + System.currentTimeMillis();
    }
}
