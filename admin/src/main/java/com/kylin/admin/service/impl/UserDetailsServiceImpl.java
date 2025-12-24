package com.kylin.admin.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.kylin.admin.config.SecurityUser;
import com.kylin.admin.entity.*;
import com.kylin.admin.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Spring Security UserDetailsService 实现
 */
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final SysUserMapper sysUserMapper;
    private final SysUserRoleMapper sysUserRoleMapper;
    private final SysRoleMapper sysRoleMapper;
    private final SysRoleMenuMapper sysRoleMenuMapper;
    private final SysMenuMapper sysMenuMapper;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // 1. 查询用户
        SysUser user = sysUserMapper.selectOne(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getUsername, username)
        );

        if (user == null) {
            throw new UsernameNotFoundException("用户不存在: " + username);
        }

        // 2. 查询用户权限列表
        List<String> permissions = getUserPermissions(user.getId());

        // 3. 返回 SecurityUser
        return new SecurityUser(user, permissions);
    }

    /**
     * 获取用户权限列表
     * @param userId 用户ID
     * @return 权限字符串列表
     */
    public List<String> getUserPermissions(Long userId) {
        Set<String> permissionSet = new HashSet<>();

        // 1. 查询用户角色关联
        List<SysUserRole> userRoles = sysUserRoleMapper.selectList(
                new LambdaQueryWrapper<SysUserRole>()
                        .eq(SysUserRole::getUserId, userId)
        );

        if (userRoles.isEmpty()) {
            return new ArrayList<>();
        }

        // 2. 获取角色ID列表
        List<Long> roleIds = userRoles.stream()
                .map(SysUserRole::getRoleId)
                .collect(Collectors.toList());

        // 3. 查询角色菜单关联
        List<SysRoleMenu> roleMenus = sysRoleMenuMapper.selectList(
                new LambdaQueryWrapper<SysRoleMenu>()
                        .in(SysRoleMenu::getRoleId, roleIds)
        );

        if (roleMenus.isEmpty()) {
            return new ArrayList<>();
        }

        // 4. 获取菜单ID列表
        List<Long> menuIds = roleMenus.stream()
                .map(SysRoleMenu::getMenuId)
                .distinct()
                .collect(Collectors.toList());

        // 5. 查询菜单权限标识
        List<SysMenu> menus = sysMenuMapper.selectList(
                new LambdaQueryWrapper<SysMenu>()
                        .in(SysMenu::getId, menuIds)
                        .isNotNull(SysMenu::getPerms)
                        .ne(SysMenu::getPerms, "")
        );

        // 6. 提取权限标识
        for (SysMenu menu : menus) {
            if (menu.getPerms() != null && !menu.getPerms().trim().isEmpty()) {
                permissionSet.add(menu.getPerms());
            }
        }

        return new ArrayList<>(permissionSet);
    }
}

