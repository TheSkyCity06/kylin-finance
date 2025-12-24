package com.kylin.finance.entity.business;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.IdType;
import com.kylin.common.BusinessException;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.time.LocalDateTime;

/**
 * 供应商实体（参考 GnuCash Vendor）
 * 供应商通常关联"应付账款"科目
 * 
 * 注意：fin_vendor 表只包含供应商扩展字段（vendor_id, owner_id, vendor_type等），
 * 基础信息（name, accountId等）在 fin_owner 表中。
 * 
 * 因此，继承自 Owner 的字段需要标记为 @TableField(exist = false)，
 * 表示这些字段不存在于 fin_vendor 表中，需要通过 JOIN 查询或单独查询 fin_owner 表获取。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_vendor")
public class Vendor extends Owner {
    
    /**
     * 供应商ID（主键，对应 fin_vendor.vendor_id）
     */
    @TableId(value = "vendor_id", type = IdType.AUTO)
    private Long vendorId;
    
    /**
     * 业务实体ID（外键 -> fin_owner.owner_id）
     * 注意：fin_vendor 表中的 owner_id 字段是外键，不是主键
     * 需要重写父类的 ownerId 字段，移除 @TableId 注解，只保留 @TableField
     */
    @TableField("owner_id")
    private Long ownerId;
    
    /**
     * 供应商类型
     */
    @TableField("vendor_type")
    private String vendorType;
    
    /**
     * 供应商等级
     */
    @TableField("vendor_level")
    private String vendorLevel;
    
    /**
     * 付款条件（如：30天、60天）
     */
    @TableField("payment_terms")
    private String paymentTerms;
    
    // ========== 以下字段继承自 Owner，但不存在于 fin_vendor 表中 ==========
    // 这些字段需要通过 JOIN 查询 fin_owner 表获取，或使用 OwnerMapper 查询
    
    @TableField(exist = false)
    private String name;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private String code;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private Long accountId;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private String ownerType;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private String contactName;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private String contactPhone;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private String contactEmail;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private String address;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private String notes;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private Boolean enabled;  // 在 fin_owner 表中
    
    // ========== 以下字段继承自 BaseEntity，但不存在于 fin_vendor 表中 ==========
    // 这些字段在 fin_owner 表中，需要通过 JOIN 查询获取
    
    @TableField(exist = false)
    private LocalDateTime createTime;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private LocalDateTime updateTime;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private Integer isDeleted;  // 在 fin_owner 表中
    
    /**
     * 实现基类的校验方法
     * 确保涉及供应商的分录必须同时记录在"应付账款"科目下
     */
    @Override
    public void validateSplitAssociation(Long splitAccountId, java.math.BigDecimal splitAmount) {
        // 调用父类的基础校验
        super.validateSplitAssociation(splitAccountId, splitAmount);
        
        // 可以添加供应商特定的校验逻辑
    }
}

