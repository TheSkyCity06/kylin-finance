package com.kylin.finance.service;

import com.kylin.finance.dto.BalanceSheetDTO;
import com.kylin.finance.dto.BalanceSheetExportRow;
import com.kylin.finance.dto.CashFlowDTO;
import com.kylin.finance.dto.CashFlowExportRow;
import com.kylin.finance.dto.TrialBalanceExportRow;

import java.time.LocalDate;
import java.util.List;

/**
 * 报表服务接口
 */
public interface IReportService {
    
    /**
     * 生成资产负债表
     * @param reportDate 报表日期
     */
    BalanceSheetDTO generateBalanceSheet(LocalDate reportDate);
    
    /**
     * 生成现金流量表
     * @param startDate 开始日期
     * @param endDate 结束日期
     */
    CashFlowDTO generateCashFlowStatement(LocalDate startDate, LocalDate endDate);
    
    /**
     * 生成资产负债表导出数据（Excel格式）
     * @param reportDate 报表日期
     * @return Excel导出行数据列表
     */
    List<BalanceSheetExportRow> generateBalanceSheetExportData(LocalDate reportDate);
    
    /**
     * 生成试算平衡表导出数据（Excel格式）
     * @param startDate 开始日期
     * @param endDate 结束日期
     * @return Excel导出行数据列表
     */
    List<TrialBalanceExportRow> generateTrialBalanceExportData(LocalDate startDate, LocalDate endDate);
    
    /**
     * 生成现金流量表导出数据（Excel格式）
     * @param startDate 开始日期
     * @param endDate 结束日期
     * @return Excel导出行数据列表
     */
    List<CashFlowExportRow> generateCashFlowExportData(LocalDate startDate, LocalDate endDate);
}
