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
 * 客户实体（参考 GnuCash Customer）
 * 客户通常关联"应收账款"科目
 * 
 * 注意：fin_customer 表只包含客户扩展字段（customer_id, owner_id, credit_limit等），
 * 基础信息（name, accountId等）在 fin_owner 表中。
 * 
 * 因此，继承自 Owner 的字段需要标记为 @TableField(exist = false)，
 * 表示这些字段不存在于 fin_customer 表中，需要通过 JOIN 查询或单独查询 fin_owner 表获取。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_customer")
public class Customer extends Owner {
    
    /**
     * 客户ID（主键，对应 fin_customer.customer_id）
     */
    @TableId(value = "customer_id", type = IdType.AUTO)
    private Long customerId;
    
    /**
     * 业务实体ID（外键 -> fin_owner.owner_id）
     * 注意：fin_customer 表中的 owner_id 字段是外键，不是主键
     * 需要重写父类的 ownerId 字段，移除 @TableId 注解，只保留 @TableField
     */
    @TableField("owner_id")
    private Long ownerId;
    
    /**
     * 客户信用额度
     */
    @TableField("credit_limit")
    private java.math.BigDecimal creditLimit;
    
    /**
     * 客户等级
     */
    @TableField("customer_level")
    private String customerLevel;
    
    /**
     * 客户行业
     */
    @TableField("industry")
    private String industry;
    
    // ========== 以下字段继承自 Owner，但不存在于 fin_customer 表中 ==========
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
    
    // ========== 以下字段继承自 BaseEntity，但不存在于 fin_customer 表中 ==========
    // 这些字段在 fin_owner 表中，需要通过 JOIN 查询获取
    
    @TableField(exist = false)
    private LocalDateTime createTime;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private LocalDateTime updateTime;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private Integer isDeleted;  // 在 fin_owner 表中
    
    /**
     * 实现基类的校验方法
     * 确保涉及客户的分录必须同时记录在"应收账款"科目下
     */
    @Override
    public void validateSplitAssociation(Long splitAccountId, java.math.BigDecimal splitAmount) {
        // 调用父类的基础校验
        super.validateSplitAssociation(splitAccountId, splitAmount);
        
        // 可以添加客户特定的校验逻辑
        // 例如：检查信用额度等
    }
}

