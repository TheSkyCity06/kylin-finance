package com.kylin.finance.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import com.alibaba.excel.annotation.write.style.ColumnWidth;
import com.alibaba.excel.annotation.format.NumberFormat;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 试算平衡表Excel导出行数据模型
 */
@Data
public class TrialBalanceExportRow {
    
    /**
     * 科目编码
     */
    @ExcelProperty(value = "科目编码", index = 0)
    @ColumnWidth(15)
    private String accountCode;
    
    /**
     * 科目名称
     */
    @ExcelProperty(value = "科目名称", index = 1)
    @ColumnWidth(25)
    private String accountName;
    
    /**
     * 期初余额
     * 根据科目类型计算：资产类/费用类 = 借方 - 贷方，负债类/权益类/收入类 = 贷方 - 借方
     */
    @ExcelProperty(value = "期初余额", index = 2)
    @ColumnWidth(20)
    @NumberFormat("#,##0.00")
    private BigDecimal openingBalance;
    
    /**
     * 本期借方发生
     */
    @ExcelProperty(value = "本期借方发生", index = 3)
    @ColumnWidth(20)
    @NumberFormat("#,##0.00")
    private BigDecimal periodDebit;
    
    /**
     * 本期贷方发生
     */
    @ExcelProperty(value = "本期贷方发生", index = 4)
    @ColumnWidth(20)
    @NumberFormat("#,##0.00")
    private BigDecimal periodCredit;
    
    /**
     * 期末余额
     * 根据科目类型计算：资产类/费用类 = 借方 - 贷方，负债类/权益类/收入类 = 贷方 - 借方
     */
    @ExcelProperty(value = "期末余额", index = 5)
    @ColumnWidth(20)
    @NumberFormat("#,##0.00")
    private BigDecimal endingBalance;
}
