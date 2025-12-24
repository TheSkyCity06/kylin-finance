package com.kylin.finance.dto;

import lombok.Data;
import java.util.List;

/**
 * 科目DTO（用于树形结构）
 */
@Data
public class AccountDTO {
    private Long accountId;
    private String accountCode;
    private String accountName;
    private String accountType;
    private Long parentId;
    private List<AccountDTO> children; // 子科目列表
    private Boolean isLeaf; // 是否为末级科目
    private String path; // 科目层级路径，如：资产 > 货币资金 > 银行存款
}
