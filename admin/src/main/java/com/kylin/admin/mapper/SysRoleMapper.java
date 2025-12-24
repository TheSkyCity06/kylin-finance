package com.kylin.admin.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.admin.entity.SysRole;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 角色表 数据层
 */
@Mapper
public interface SysRoleMapper extends BaseMapper<SysRole> {

    /**
     * 根据用户ID查询角色列表
     * 关联逻辑：sys_role (r) -> sys_user_role (ur)
     */
    @Select("SELECT r.* " +
            "FROM sys_role r " +
            "LEFT JOIN sys_user_role ur ON ur.role_id = r.id " +
            "WHERE ur.user_id = #{userId} " +
            "AND r.is_deleted = 0")
    List<SysRole> selectRolesByUserId(@Param("userId") Long userId);
}