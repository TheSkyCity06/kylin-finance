package com.kylin.admin.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import com.baomidou.mybatisplus.annotation.IdType;
/**
 * 角色表
 * 用于定义：管理员、财务主管、普通会计等
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_role")
public class SysRole extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id; // 在这里定义，SysUserService 就能找到 getId() 了
    private String roleName;    // 角色名称 (如：财务主管)

    private String roleKey;     // 角色权限字符串 (如：finance_manager)

    private Integer roleSort;   // 显示顺序

    private String remark;      // 备注
}