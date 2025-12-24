package com.kylin.admin.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 用户角色关联表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_user_role")
public class SysUserRole extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long userId;  // 用户ID

    private Long roleId;  // 角色ID
}

