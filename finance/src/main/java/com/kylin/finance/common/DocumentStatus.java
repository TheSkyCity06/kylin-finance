package com.kylin.finance.common;

/**
 * 商业单据状态枚举（参考 GnuCash 状态机）
 * 状态流转：DRAFT -> VALIDATED -> POSTED
 * 任何状态都可以转为 CANCELLED
 */
public enum DocumentStatus {
    
    /**
     * 草稿状态
     * - 允许：CREATE, UPDATE, DELETE
     * - 不允许：过账
     */
    DRAFT("DRAFT", "草稿"),
    
    /**
     * 已审核状态
     * - 允许：查看、过账
     * - 不允许：UPDATE, DELETE（单据内容只读）
     */
    VALIDATED("VALIDATED", "已审核"),
    
    /**
     * 已过账状态
     * - 单据编号已锁定
     * - 已生成会计分录
     * - 不允许：UPDATE, DELETE, 再次过账
     */
    POSTED("POSTED", "已过账"),
    
    /**
     * 已作废状态
     * - 任何状态都可以转为 CANCELLED
     * - 不允许：任何修改操作
     */
    CANCELLED("CANCELLED", "已作废");
    
    private final String code;
    private final String description;
    
    DocumentStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
    
    public String getCode() {
        return code;
    }
    
    public String getDescription() {
        return description;
    }
    
    /**
     * 根据代码获取状态枚举
     */
    public static DocumentStatus fromCode(String code) {
        if (code == null) {
            return DRAFT;
        }
        for (DocumentStatus status : values()) {
            if (status.code.equals(code)) {
                return status;
            }
        }
        return DRAFT;
    }
    
    /**
     * 检查是否可以更新
     */
    public boolean canUpdate() {
        return this == DRAFT;
    }
    
    /**
     * 检查是否可以删除
     */
    public boolean canDelete() {
        return this == DRAFT;
    }
    
    /**
     * 检查是否可以过账
     */
    public boolean canPost() {
        return this == VALIDATED;
    }
    
    /**
     * 检查是否可以审核
     */
    public boolean canValidate() {
        return this == DRAFT;
    }
    
    /**
     * 检查是否可以作废
     */
    public boolean canCancel() {
        return this != CANCELLED;
    }
    
    /**
     * 检查是否已锁定（不允许修改）
     */
    public boolean isLocked() {
        return this == VALIDATED || this == POSTED || this == CANCELLED;
    }
}

