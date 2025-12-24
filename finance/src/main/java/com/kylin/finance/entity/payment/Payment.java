package com.kylin.finance.entity.payment;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 支付实体（参考 GnuCash Payment）
 * 记录客户付款或供应商付款的完整信息
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_payment")
public class Payment extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long paymentId;

    /**
     * 支付编号（唯一）
     */
    private String paymentNo;

    /**
     * 支付日期
     */
    private LocalDate paymentDate;

    /**
     * 支付类型：RECEIPT(收款，从客户收款), PAYMENT(付款，给供应商付款)
     */
    private String paymentType;

    /**
     * 关联的业务实体ID（客户或供应商，外键 -> fin_owner.owner_id）
     */
    private Long ownerId;

    /**
     * 支付账户ID（银行存款等科目，外键 -> fin_account.account_id）
     */
    private Long accountId;

    /**
     * 币种ID（外键 -> fin_commodity.commodity_id）
     */
    private Long commodityId;

    /**
     * 支付总金额
     */
    private BigDecimal amount;

    /**
     * 备注/说明
     */
    private String memo;

    /**
     * 支付状态：CLEARED(已清算), RECONCILED(已对账), VOID(作废)
     */
    private String status;

    /**
     * 是否已过账
     */
    private Boolean posted;

    /**
     * 关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）
     */
    private Long transId;

    /**
     * 未分配金额（用于 Lot Tracking）
     */
    @TableField(exist = false)
    private BigDecimal unallocatedAmount;

    /**
     * 支付分配列表（非数据库字段）
     */
    @TableField(exist = false)
    private java.util.List<PaymentAllocation> allocations;
}
