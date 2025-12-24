package com.kylin.finance.dto;

import lombok.Data;
import java.math.BigDecimal;

/**
 * 支付分配结果DTO（用于返回核销详情）
 */
@Data
public class PaymentAllocationResultDTO {
    /**
     * 单据编号
     */
    private String documentNo;

    /**
     * 分配金额
     */
    private BigDecimal amount;

    /**
     * 核销状态：PAID(全额), PARTIAL(部分)
     */
    private String status;

    /**
     * 剩余金额
     */
    private BigDecimal remainingAmount;
}
