package com.kylin.finance.service;

import com.kylin.finance.entity.expense.ExpenseClaim;
import com.kylin.finance.entity.FinTransaction;

/**
 * 员工报销服务接口
 */
public interface IExpenseClaimService {

    /**
     * 提交报销单
     * @param claim 报销单
     * @return 保存后的报销单
     */
    ExpenseClaim submitClaim(ExpenseClaim claim);

    /**
     * 审批报销单
     * @param claimId 报销单ID
     * @param approverId 审批人ID
     * @param approved 是否通过
     * @param comment 审批意见
     * @return 更新后的报销单
     */
    ExpenseClaim approveClaim(Long claimId, Long approverId, Boolean approved, String comment);

    /**
     * 过账报销单
     * 生成凭证：借：管理费用，贷：其他应付款-员工
     * @param claimId 报销单ID
     * @return 生成的交易
     */
    FinTransaction postClaimToLedger(Long claimId);
}
