package com.kylin.finance.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

/**
 * 现金流量表DTO
 */
@Data
public class CashFlowDTO {
    private String reportDate; // 报表日期
    
    // 经营活动产生的现金流量
    private List<CashFlowItemDTO> operatingActivities;
    private BigDecimal netOperatingCashFlow; // 经营活动产生的现金流量净额
    
    // 投资活动产生的现金流量
    private List<CashFlowItemDTO> investingActivities;
    private BigDecimal netInvestingCashFlow; // 投资活动产生的现金流量净额
    
    // 筹资活动产生的现金流量
    private List<CashFlowItemDTO> financingActivities;
    private BigDecimal netFinancingCashFlow; // 筹资活动产生的现金流量净额
    
    // 现金及现金等价物净增加额
    private BigDecimal netIncreaseInCash;
    
    // 期初现金及现金等价物余额
    private BigDecimal beginningCashBalance;
    
    // 期末现金及现金等价物余额
    private BigDecimal endingCashBalance;
    
    /**
     * 现金流量表项目
     */
    @Data
    public static class CashFlowItemDTO {
        private String itemName;
        private BigDecimal amount;
        private String description;
    }
}
