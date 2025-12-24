package com.kylin.admin.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import com.baomidou.mybatisplus.annotation.IdType;

/**
 * 菜单权限表
 * 控制具体的页面访问和按钮点击
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_menu")
public class SysMenu extends BaseEntity {
    @TableId(type = IdType.ASSIGN_ID)
    private Long id; // 在这里定义，SysUserService 就能找到 getId() 了

    private String menuName;   // 菜单名称

    private Long parentId;     // 父菜单ID

    private Integer orderNum;  // 显示顺序

    private String path;       // 路由地址 (Vue前端用)

    /**
     * 权限标识 (核心字段)
     * 例如：
     * finance:account:list (查看账户)
     * finance:account:add (新增账户)
     */
    private String perms;

    private String icon;       // 菜单图标

    private String menuType;   // 类型（M目录 C菜单 F按钮）
}