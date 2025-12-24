package com.kylin.finance.entity.biz;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;

/**
 * 报销明细表实体
 * 对应数据库表：biz_expense_claim_detail
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("biz_expense_claim_detail")
public class BizExpenseClaimDetail extends BaseEntity {

    private static final long serialVersionUID = 1L;

    /**
     * 报销明细ID（主键）
     */
    @TableId(value = "detail_id", type = IdType.AUTO)
    private Long detailId;

    /**
     * 报销单ID（外键 -> biz_expense_claim.claim_id）
     */
    private Long claimId;

    /**
     * 借方科目ID（费用科目，如差旅费，外键 -> fin_account.account_id）
     */
    private Long debitAccountId;

    /**
     * 金额
     */
    private BigDecimal amount;

    /**
     * 摘要说明
     */
    private String description;
}

