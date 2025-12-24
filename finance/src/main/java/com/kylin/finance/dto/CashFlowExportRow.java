package com.kylin.finance.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import com.alibaba.excel.annotation.write.style.ColumnWidth;
import com.alibaba.excel.annotation.format.NumberFormat;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 现金流量表Excel导出行数据模型
 */
@Data
public class CashFlowExportRow {
    
    /**
     * 项目名称
     */
    @ExcelProperty(value = "项目", index = 0)
    @ColumnWidth(40)
    private String itemName;
    
    /**
     * 金额
     */
    @ExcelProperty(value = "金额", index = 1)
    @ColumnWidth(20)
    @NumberFormat("#,##0.00")
    private BigDecimal amount;
    
    /**
     * 构造函数
     */
    public CashFlowExportRow() {
    }
    
    /**
     * 构造函数
     * @param itemName 项目名称
     * @param amount 金额（可为null，用于标题行）
     */
    public CashFlowExportRow(String itemName, BigDecimal amount) {
        this.itemName = itemName;
        this.amount = amount;
    }
    
    /**
     * 创建标题行（金额为空）
     */
    public static CashFlowExportRow createHeaderRow(String itemName) {
        return new CashFlowExportRow(itemName, null);
    }
    
    /**
     * 创建数据行
     */
    public static CashFlowExportRow createDataRow(String itemName, BigDecimal amount) {
        return new CashFlowExportRow(itemName, amount);
    }
}
