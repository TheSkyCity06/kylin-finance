package com.kylin.finance.entity.document;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/**
 * 发票条目实体（参考 GnuCash Invoice Item）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_invoice_item")
public class InvoiceItem extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long itemId;

    /**
     * 关联的发票ID（外键 -> fin_invoice.invoice_id）
     */
    private Long invoiceId;

    /**
     * 项目描述
     */
    private String description;

    /**
     * 收入科目ID（外键 -> fin_account.account_id）
     * 例如：主营业务收入、其他业务收入等
     */
    private Long incomeAccountId;

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
