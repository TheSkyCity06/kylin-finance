package com.kylin.finance.dto;

import lombok.Data;
import java.math.BigDecimal;

/**
 * 科目余额DTO
 */
@Data
public class AccountBalanceDTO {
    private Long accountId;
    private String accountCode;
    private String accountName;
    private String accountType;
    private BigDecimal debitBalance;  // 借方余额
    private BigDecimal creditBalance; // 贷方余额
    private BigDecimal balance;       // 余额（根据科目类型计算）
}
