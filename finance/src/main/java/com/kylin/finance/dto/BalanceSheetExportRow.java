package com.kylin.finance.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import com.alibaba.excel.annotation.write.style.ColumnWidth;
import com.alibaba.excel.annotation.format.NumberFormat;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 资产负债表Excel导出行数据模型
 * 用于将资产负债表的两侧（资产 vs 负债及权益）合并为单行数据
 */
@Data
public class BalanceSheetExportRow {
    
    /**
     * 列0: 资产项目名称
     */
    @ExcelProperty(value = "资产项目", index = 0)
    @ColumnWidth(25)
    private String assetName;
    
    /**
     * 列1: 资产期末余额
     */
    @ExcelProperty(value = "期末余额", index = 1)
    @ColumnWidth(20)
    @NumberFormat("#,##0.00")
    private BigDecimal assetAmount;
    
    /**
     * 列2: 空列（分隔符）
     */
    @ExcelProperty(value = "", index = 2)
    @ColumnWidth(5)
    private String spacer;
    
    /**
     * 列3: 负债及权益项目名称
     */
    @ExcelProperty(value = "负债及权益项目", index = 3)
    @ColumnWidth(25)
    private String liabilityEquityName;
    
    /**
     * 列4: 负债及权益期末余额
     */
    @ExcelProperty(value = "期末余额", index = 4)
    @ColumnWidth(20)
    @NumberFormat("#,##0.00")
    private BigDecimal liabilityEquityAmount;
    
    /**
     * 构造函数 - 资产行
     */
    public BalanceSheetExportRow(String assetName, BigDecimal assetAmount) {
        this.assetName = assetName;
        this.assetAmount = assetAmount;
        this.spacer = "";
        this.liabilityEquityName = "";
        this.liabilityEquityAmount = null;
    }
    
    /**
     * 构造函数 - 负债及权益行
     */
    public BalanceSheetExportRow(String liabilityEquityName, BigDecimal liabilityEquityAmount, boolean isLiabilityEquity) {
        this.assetName = "";
        this.assetAmount = null;
        this.spacer = "";
        this.liabilityEquityName = liabilityEquityName;
        this.liabilityEquityAmount = liabilityEquityAmount;
    }
    
    /**
     * 构造函数 - 空行（用于对齐）
     */
    public BalanceSheetExportRow() {
        this.assetName = "";
        this.assetAmount = null;
        this.spacer = "";
        this.liabilityEquityName = "";
        this.liabilityEquityAmount = null;
    }
    
    /**
     * 创建资产行
     */
    public static BalanceSheetExportRow createAssetRow(String name, BigDecimal amount) {
        return new BalanceSheetExportRow(name, amount);
    }
    
    /**
     * 创建负债及权益行
     */
    public static BalanceSheetExportRow createLiabilityEquityRow(String name, BigDecimal amount) {
        return new BalanceSheetExportRow(name, amount, true);
    }
    
    /**
     * 创建空行
     */
    public static BalanceSheetExportRow createEmptyRow() {
        return new BalanceSheetExportRow();
    }
}
