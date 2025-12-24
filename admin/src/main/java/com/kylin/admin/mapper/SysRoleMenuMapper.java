package com.kylin.admin.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.admin.entity.SysRoleMenu;
import org.apache.ibatis.annotations.Mapper;

/**
 * 角色菜单关联表 Mapper
 */
@Mapper
public interface SysRoleMenuMapper extends BaseMapper<SysRoleMenu> {
}

