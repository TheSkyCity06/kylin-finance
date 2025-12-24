package com.kylin.admin.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.admin.entity.SysMenu;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 菜单表 数据层
 */
@Mapper
public interface SysMenuMapper extends BaseMapper<SysMenu> {

    /**
     * 根据用户ID查询权限标识（去重）
     * 关联逻辑：sys_menu (m) -> sys_role_menu (rm) -> sys_user_role (ur)
     * * 解释：
     * 1. ur 表关联用户和角色
     * 2. rm 表关联角色和菜单
     * 3. m 表获取具体的权限字符串 (如 finance:account:add)
     */
    @Select("SELECT DISTINCT m.perms " +
            "FROM sys_menu m " +
            "LEFT JOIN sys_role_menu rm ON m.id = rm.menu_id " +
            "LEFT JOIN sys_user_role ur ON rm.role_id = ur.role_id " +
            "WHERE ur.user_id = #{userId} " +
            "AND m.is_deleted = 0 " +
            "AND m.status = 1 " + // 菜单状态需为正常
            "AND m.perms IS NOT NULL " +
            "AND m.perms != ''")
    List<String> selectPermsByUserId(@Param("userId") Long userId);
}
