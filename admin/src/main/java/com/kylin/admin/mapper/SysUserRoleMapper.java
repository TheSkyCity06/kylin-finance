package com.kylin.admin.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.admin.entity.SysUserRole;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户角色关联表 Mapper
 */
@Mapper
public interface SysUserRoleMapper extends BaseMapper<SysUserRole> {
}

