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
 * 供应商账单实体（参考 GnuCash Bill）
 * 账单是向供应商支付款项的单据
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_bill")
public class Bill extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long billId;

    /**
     * 账单编号（唯一）
     */
    private String billNo;

    /**
     * 账单日期
     */
    private LocalDate billDate;

    /**
     * 到期日期
     */
    private LocalDate dueDate;

    /**
     * 关联的供应商ID（外键 -> fin_owner.owner_id）
     */
    private Long vendorId;
    
    /**
     * 供应商名称（非数据库字段，用于前端显示）
     */
    @TableField(exist = false)
    private String vendorName;

    /**
     * 账单状态（状态机）：
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
     * 账单金额（含税）
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
     * 账单条目列表（非数据库字段）
     */
    @TableField(exist = false)
    private List<BillItem> items;
}
