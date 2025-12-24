package com.kylin.finance.dto;

import lombok.Data;
import java.math.BigDecimal;

/**
 * 科目余额汇总DTO（用于批量查询结果）
 */
@Data
public class AccountBalanceSummary {
    /**
     * 科目ID
     */
    private Long accountId;
    
    /**
     * 借方金额合计
     */
    private BigDecimal debitAmount;
    
    /**
     * 贷方金额合计
     */
    private BigDecimal creditAmount;
}

