package com.kylin.finance.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

/**
 * 资产负债表DTO
 */
@Data
public class BalanceSheetDTO {
    private String reportDate; // 报表日期
    
    // 资产部分
    private List<BalanceSheetItemDTO> assets;
    private BigDecimal totalAssets; // 资产合计
    
    // 负债部分
    private List<BalanceSheetItemDTO> liabilities;
    private BigDecimal totalLiabilities; // 负债合计
    
    // 所有者权益部分
    private List<BalanceSheetItemDTO> equity;
    private BigDecimal totalEquity; // 所有者权益合计
    
    // 验证：资产 = 负债 + 所有者权益
    private BigDecimal totalLiabilitiesAndEquity;
    
    /**
     * 资产负债表项目
     */
    @Data
    public static class BalanceSheetItemDTO {
        private String accountCode;
        private String accountName;
        private BigDecimal amount;
        private List<BalanceSheetItemDTO> children; // 子项目
    }
}
