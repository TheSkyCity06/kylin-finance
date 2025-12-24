package com.kylin.finance.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/**
 * 分录实体（参考 GnuCash Entry 概念）
 * Entry 是 Transaction 和 Account 之间的关联，包含借方和贷方金额
 * 注意：在我们的实现中，Entry 概念上对应 Split，但这里提供更明确的借贷金额字段
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_entry")
public class FinEntry extends BaseEntity {
    
    @TableId(type = IdType.AUTO)
    private Long entryId;
    
    /**
     * 关联的交易ID（外键 -> fin_transaction.trans_id）
     */
    private Long transId;
    
    /**
     * 关联的科目ID（外键 -> fin_account.account_id）
     */
    private Long accountId;
    
    /**
     * 借方金额（如果为借方分录，此字段有值；贷方分录此字段为0）
     */
    private BigDecimal debitAmount;
    
    /**
     * 贷方金额（如果为贷方分录，此字段有值；借方分录此字段为0）
     */
    private BigDecimal creditAmount;
    
    /**
     * 分录备注/摘要
     */
    private String memo;
    
    /**
     * 关联的业务实体ID（可选，如果涉及客户/供应商/员工）
     */
    private Long ownerId;
    
    /**
     * 业务实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)
     */
    private String ownerType;
}

