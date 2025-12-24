package com.kylin.finance.entity.biz;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 收付款单实体
 * 对应数据库表：biz_receipt_payment
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("biz_receipt_payment")
public class BizReceiptPayment extends BaseEntity {

    private static final long serialVersionUID = 1L;

    /**
     * 收付款单ID（主键）
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 单据编号，如RP20241201001（Receipt Payment）
     */
    private String code;

    /**
     * 类型：RECEIPT(收款), PAYMENT(付款)
     * 前端传值：'RECEIPT' 或 'PAYMENT'
     * 存储时也可以使用：1=收款, 2=付款
     */
    private String type;

    /**
     * 往来单位名称（客户/供应商名称）
     */
    private String partnerName;

    /**
     * 往来单位ID（外键 -> fin_owner.owner_id）
     */
    private Long ownerId;

    /**
     * 结算账户ID（外键 -> fin_account.account_id，如现金、银行存款）
     */
    private Long accountId;

    /**
     * 金额
     */
    private BigDecimal amount;

    /**
     * 收付款日期
     */
    private LocalDate date;

    /**
     * 摘要说明
     */
    private String remark;

    /**
     * 状态：0=草稿(DRAFT), 1=已过账(POSTED)
     */
    private Integer status;

    /**
     * 关联的凭证ID（过账后生成，外键 -> fin_transaction.trans_id）
     */
    private Long voucherId;
}

