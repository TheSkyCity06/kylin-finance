package com.kylin.finance.entity.document;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 冲销单据实体（参考 GnuCash Credit Note）
 * 用于更正已过账的发票或账单
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_credit_note")
public class CreditNote extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long creditNoteId;

    /**
     * 冲销单据编号（唯一）
     */
    private String creditNoteNo;

    /**
     * 冲销单据日期
     */
    private LocalDate creditNoteDate;

    /**
     * 原单据类型：INVOICE(发票), BILL(账单)
     */
    private String originalDocType;

    /**
     * 原单据ID
     */
    private Long originalDocId;

    /**
     * 关联的业务实体ID（客户或供应商）
     */
    private Long ownerId;

    /**
     * 冲销金额
     */
    private BigDecimal amount;

    /**
     * 原因
     */
    private String reason;

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
}
