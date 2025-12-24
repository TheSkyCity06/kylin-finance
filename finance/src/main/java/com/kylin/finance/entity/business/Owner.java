package com.kylin.finance.entity.business;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 业务实体基类（参考 GnuCash Owner 概念）
 * 所有业务实体（客户、供应商、员工）的基类
 * 注意：由于 MyBatis-Plus 的限制，这里使用具体类而非抽象类
 * 子类通过继承和重写方法实现多态
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_owner")
public class Owner extends BaseEntity {
    
    @TableId(type = IdType.AUTO)
    private Long ownerId;
    
    /**
     * 实体名称
     */
    private String name;
    
    /**
     * 实体代码/编号
     */
    private String code;
    
    /**
     * 关联的往来科目ID（外键 -> fin_account.account_id）
     * 例如：客户关联"应收账款"，供应商关联"应付账款"
     */
    private Long accountId;
    
    /**
     * 实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)
     */
    private String ownerType;
    
    /**
     * 联系人姓名
     */
    private String contactName;
    
    /**
     * 联系电话
     */
    private String contactPhone;
    
    /**
     * 联系邮箱
     */
    private String contactEmail;
    
    /**
     * 地址
     */
    private String address;
    
    /**
     * 备注
     */
    private String notes;
    
    /**
     * 是否启用
     */
    private Boolean enabled;
    
    /**
     * 关联的科目名称（非数据库字段，用于前端显示）
     */
    @TableField(exist = false)
    private String accountName;
    
    /**
     * 校验方法：确保涉及此实体的分录必须同时记录在关联科目下
     * 子类可以重写此方法以实现特定的校验逻辑
     */
    public void validateSplitAssociation(Long splitAccountId, java.math.BigDecimal splitAmount) {
        if (this.getAccountId() == null) {
            throw new com.kylin.common.BusinessException("业务实体\"" + this.getName() + "\"未关联往来科目，无法进行业务处理");
        }
        
        // 如果分录的科目不是该实体关联的科目，抛出异常
        if (!this.getAccountId().equals(splitAccountId)) {
            throw new com.kylin.common.BusinessException(
                String.format("涉及业务实体\"%s\"的分录必须记录在其关联的往来科目（科目ID：%d）下，当前分录科目ID：%d",
                    this.getName(), this.getAccountId(), splitAccountId));
        }
    }
}

