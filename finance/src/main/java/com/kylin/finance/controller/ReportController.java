package com.kylin.finance.controller;

import com.alibaba.excel.EasyExcel;
import com.kylin.finance.dto.CashFlowExportRow;
import com.kylin.finance.service.IReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

/**
 * 报表控制器
 * 提供报表相关的API端点
 */
@RestController
@RequestMapping("/reports")
public class ReportController {

    @Autowired
    private IReportService reportService;

    /**
     * 导出现金流量表到Excel
     * 端点: GET /api/reports/cash-flow/export
     */
    @GetMapping("/cash-flow/export")
    public void exportCashFlow(
            @RequestParam String startDate,
            @RequestParam String endDate,
            HttpServletResponse response) throws IOException {
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        
        // 生成导出数据
        List<CashFlowExportRow> exportData = reportService.generateCashFlowExportData(start, end);
        
        // 设置响应头
        response.setContentType("application/vnd.ms-excel");
        response.setCharacterEncoding("utf-8");
        
        // 文件名使用URL编码，避免中文乱码
        String fileName = URLEncoder.encode("cash_flow", StandardCharsets.UTF_8)
            .replaceAll("\\+", "%20");
        response.setHeader("Content-Disposition", "attachment;filename=" + fileName + ".xlsx");
        
        // 使用EasyExcel写入Excel
        EasyExcel.write(response.getOutputStream(), CashFlowExportRow.class)
            .sheet("现金流量表")
            .doWrite(exportData);
    }
}

