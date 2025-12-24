package com.kylin.finance.entity.business;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BusinessException;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 员工实体（参考 GnuCash Employee）
 * 员工通常关联"其他应收款"或"其他应付款"科目
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_employee")
public class Employee extends Owner {
    
    /**
     * 员工ID（主键，对应 fin_employee.employee_id）
     */
    @TableId(value = "employee_id", type = IdType.AUTO)
    private Long employeeId;
    
    /**
     * 业务实体ID（外键 -> fin_owner.owner_id）
     * 注意：fin_employee 表中的 owner_id 字段是外键，不是主键
     * 需要重写父类的 ownerId 字段，移除 @TableId 注解，只保留 @TableField
     */
    @TableField("owner_id")
    private Long ownerId;
    
    /**
     * 员工编号
     */
    private String employeeNo;
    
    /**
     * 部门
     */
    private String department;
    
    /**
     * 职位
     */
    private String position;
    
    /**
     * 入职日期
     */
    private LocalDate hireDate;
    
    // ========== 以下字段继承自 Owner 和 BaseEntity，但不存在于 fin_employee 表中 ==========
    // 这些字段在 fin_owner 表中，需要通过 JOIN 查询获取
    
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
    
    @TableField(exist = false)
    private LocalDateTime createTime;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private LocalDateTime updateTime;  // 在 fin_owner 表中
    
    @TableField(exist = false)
    private Integer isDeleted;  // 在 fin_owner 表中
    
    /**
     * 实现基类的校验方法
     * 确保涉及员工的分录必须同时记录在关联的往来科目下
     */
    @Override
    public void validateSplitAssociation(Long splitAccountId, java.math.BigDecimal splitAmount) {
        // 调用父类的基础校验
        super.validateSplitAssociation(splitAccountId, splitAmount);
        
        // 可以添加员工特定的校验逻辑
    }
}

