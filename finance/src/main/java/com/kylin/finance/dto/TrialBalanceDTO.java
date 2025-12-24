package com.kylin.finance.dto;

import lombok.Data;
import java.math.BigDecimal;

/**
 * 试算平衡表DTO
 */
@Data
public class TrialBalanceDTO {
    private Long accountId;
    private String accountCode;
    private String accountName;
    private String accountType;
    private BigDecimal periodBeginDebit;   // 期初借方
    private BigDecimal periodBeginCredit;  // 期初贷方
    private BigDecimal periodDebit;        // 本期借方
    private BigDecimal periodCredit;       // 本期贷方
    private BigDecimal periodEndDebit;     // 期末借方
    private BigDecimal periodEndCredit;    // 期末贷方
}
