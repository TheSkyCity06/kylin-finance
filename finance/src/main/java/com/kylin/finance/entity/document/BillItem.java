package com.kylin.finance.entity.document;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/**
 * 账单条目实体（参考 GnuCash Bill Item）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_bill_item")
public class BillItem extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long itemId;

    /**
     * 关联的账单ID（外键 -> fin_bill.bill_id）
     */
    private Long billId;

    /**
     * 项目描述
     */
    private String description;

    /**
     * 费用/资产科目ID（外键 -> fin_account.account_id）
     * 例如：管理费用、材料采购、固定资产等
     */
    private Long expenseAccountId;

    /**
     * 数量
     */
    private BigDecimal quantity;

    /**
     * 单价
     */
    private BigDecimal unitPrice;

    /**
     * 金额（数量 × 单价）
     */
    private BigDecimal amount;

    /**
     * 税率（百分比，如 13.00 表示 13%）
     */
    private BigDecimal taxRate;

    /**
     * 税额
     */
    private BigDecimal taxAmount;
}
