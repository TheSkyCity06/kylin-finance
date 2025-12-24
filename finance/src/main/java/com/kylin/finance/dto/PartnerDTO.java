package com.kylin.finance.dto;

import lombok.Data;

/**
 * 往来单位DTO（用于下拉选择）
 * 标准化字段名：partnerId 和 partnerName
 */
@Data
public class PartnerDTO {
    /**
     * 往来单位ID（对应 Owner.ownerId）
     */
    private Long partnerId;
    
    /**
     * 往来单位名称（对应 Owner.name）
     */
    private String partnerName;
    
    /**
     * 往来单位代码（对应 Owner.code）
     */
    private String partnerCode;
    
    /**
     * 往来单位类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)
     */
    private String category;
    
    /**
     * 关联的科目ID
     */
    private Long accountId;
    
    /**
     * 关联的科目名称（用于显示）
     */
    private String accountName;
}

