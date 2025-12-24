package com.kylin.finance.entity.expense;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/**
 * 员工报销明细实体
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_expense_claim_item")
public class ExpenseClaimItem extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long itemId;

    /**
     * 关联的报销单ID（外键 -> fin_expense_claim.claim_id）
     */
    private Long claimId;

    /**
     * 费用描述
     */
    private String description;

    /**
     * 费用科目ID（外键 -> fin_account.account_id）
     * 例如：管理费用、差旅费等
     */
    private Long expenseAccountId;

    /**
     * 金额
     */
    private BigDecimal amount;

    /**
     * 发票/单据附件
     */
    private String attachment;
}
