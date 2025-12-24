package com.kylin.finance.dto;

import lombok.Data;
import java.time.LocalDate;

/**
 * 凭证查询DTO
 */
@Data
public class VoucherQueryDTO {
    private String voucherNo;      // 凭证号
    private LocalDate startDate;   // 开始日期
    private LocalDate endDate;     // 结束日期
    private Long accountId;        // 科目ID
    private Integer status;        // 状态：0-草稿，1-已审核
    private Integer pageNum = 1;   // 页码
    private Integer pageSize = 10; // 每页大小
}
