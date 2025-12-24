package com.kylin.finance.entity.document;

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
 * 客户发票实体（参考 GnuCash Invoice）
 * 发票是向客户收取款项的单据
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_invoice")
public class Invoice extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long invoiceId;

    /**
     * 发票编号（唯一）
     */
    private String invoiceNo;

    /**
     * 发票日期
     */
    private LocalDate invoiceDate;

    /**
     * 到期日期
     */
    private LocalDate dueDate;

    /**
     * 关联的客户ID（外键 -> fin_owner.owner_id）
     */
    private Long customerId;

    /**
     * 客户名称（非数据库字段，用于前端显示）
     */
    @TableField(exist = false)
    private String customerName;

    /**
     * 发票状态（状态机）：
     * DRAFT(草稿) - 允许 CREATE, UPDATE, DELETE
     * VALIDATED(已审核) - 单据内容只读，允许过账
     * POSTED(已过账) - 已生成会计分录，单据编号已锁定，不允许修改
     * CANCELLED(已作废) - 任何状态都可以转为 CANCELLED
     */
    private String status;

    /**
     * 币种ID（外键 -> fin_commodity.commodity_id）
     */
    private Long commodityId;

    /**
     * 发票金额（含税）
     */
    private BigDecimal totalAmount;

    /**
     * 税额
     */
    private BigDecimal taxAmount;

    /**
     * 不含税金额
     */
    private BigDecimal netAmount;

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
     * 邮寄状态：NOT_SENT(未邮寄), SENT(已邮寄), DELIVERED(已送达)
     */
    private String shippingStatus;

    /**
     * 快递单号/追踪号
     */
    private String trackingNo;

    /**
     * 发票条目列表（非数据库字段）
     */
    @TableField(exist = false)
    private List<InvoiceItem> items;
}
