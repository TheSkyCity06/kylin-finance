package com.kylin.finance.entity.expense;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * 员工报销单实体
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_expense_claim")
public class ExpenseClaim extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long claimId;

    /**
     * 报销单编号（唯一）
     */
    private String claimNo;

    /**
     * 报销日期
     */
    private LocalDate claimDate;

    /**
     * 员工ID（外键 -> fin_owner.owner_id）
     */
    private Long employeeId;

    /**
     * 报销总金额
     */
    private BigDecimal totalAmount;

    /**
     * 审批状态：PENDING(待审批), APPROVED(已审批), REJECTED(已拒绝), POSTED(已过账)
     */
    private String approvalStatus;

    /**
     * 审批人ID
     */
    private Long approverId;

    /**
     * 审批时间
     */
    private LocalDate approvalDate;

    /**
     * 审批意见
     */
    private String approvalComment;

    /**
     * 备注
     */
    private String notes;

    /**
     * 是否已过账
     */
    private Boolean posted;

    /**
     * 关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）
     */
    private Long transId;

    /**
     * 报销明细列表（非数据库字段）
     */
    @TableField(exist = false)
    private List<ExpenseClaimItem> items;
}
