package com.kylin.finance.entity.payment;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/**
 * 支付分配实体（参考 GnuCash Payment Allocation）
 * 记录支付金额如何分配到具体单据（Lot Tracking）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_payment_allocation")
public class PaymentAllocation extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long allocationId;

    /**
     * 关联的支付ID（外键 -> fin_payment.payment_id）
     */
    private Long paymentId;

    /**
     * 分配到的单据类型：INVOICE(发票), BILL(账单)
     */
    private String documentType;

    /**
     * 分配到的单据ID
     */
    private Long documentId;

    /**
     * 分配金额
     */
    private BigDecimal amount;

    /**
     * 分配前的单据未结清金额
     */
    private BigDecimal previousUnpaidAmount;

    /**
     * 分配后的单据未结清金额
     */
    private BigDecimal remainingUnpaidAmount;

    /**
     * 分配状态：PARTIAL(部分支付), FULL(全额支付)
     */
    private String allocationStatus;
}
