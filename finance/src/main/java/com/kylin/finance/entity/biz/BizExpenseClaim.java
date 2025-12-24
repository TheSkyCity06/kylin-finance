package com.kylin.finance.entity.biz;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 报销单主表实体
 * 对应数据库表：biz_expense_claim
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("biz_expense_claim")
public class BizExpenseClaim extends BaseEntity {

    private static final long serialVersionUID = 1L;

    /**
     * 报销单ID（主键）
     */
    @TableId(value = "claim_id", type = IdType.AUTO)
    private Long claimId;

    /**
     * 报销单号，如EXP20241201001
     */
    private String claimNo;

    /**
     * 申请人ID（外键 -> fin_owner.owner_id，关联员工）
     */
    private Long applicantId;

    /**
     * 报销日期
     */
    private LocalDate claimDate;

    /**
     * 报销总金额
     */
    private BigDecimal totalAmount;

    /**
     * 状态：DRAFT(草稿), POSTED(已过账), REVERSED(已冲销)
     */
    private String status;

    /**
     * 贷方科目ID（付款账户，如银行存款，外键 -> fin_account.account_id）
     */
    private Long creditAccountId;

    /**
     * 备注说明
     */
    private String notes;

    /**
     * 关联的凭证ID（过账后生成，外键 -> fin_transaction.trans_id）
     */
    private Long voucherId;

    /**
     * 明细列表（非数据库字段，用于业务处理）
     */
    @TableField(exist = false)
    private java.util.List<BizExpenseClaimDetail> details;
}

