package com.kylin.admin.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 角色菜单关联表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_role_menu")
public class SysRoleMenu extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long roleId;  // 角色ID

    private Long menuId;   // 菜单ID
}

