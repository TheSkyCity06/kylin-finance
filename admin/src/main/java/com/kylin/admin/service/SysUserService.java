package com.kylin.admin.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.kylin.admin.entity.*;
import com.kylin.admin.mapper.*;
import com.kylin.admin.util.JwtUtil;
import com.kylin.common.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SysUserService extends ServiceImpl<SysUserMapper, SysUser> {

    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final SysUserMapper sysUserMapper;
    private final SysUserRoleMapper sysUserRoleMapper;
    private final SysRoleMenuMapper sysRoleMenuMapper;
    private final SysMenuMapper sysMenuMapper;

    /**
     * 用户登录
     * @param username 用户名
     * @param password 密码（明文）
     * @return JWT Token
     */
    public String login(String username, String password) {
        System.out.println("========================================");
        System.out.println("【登录开始】用户名: " + username);
        System.out.println("【前端传来的密码原文】: [" + password + "]");
        System.out.println("【密码原文长度】: " + (password != null ? password.length() : "null"));
        
        // 1. 根据用户名查询用户
        SysUser user = sysUserMapper.selectOne(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getUsername, username)
        );

        // 2. 校验用户是否存在
        if (user == null) {
            System.out.println("【查询结果】用户不存在");
            System.out.println("========================================");
            throw new BusinessException("用户不存在");
        }

        System.out.println("【查询结果】用户存在，用户ID: " + user.getId());
        
        // 获取数据库中的密码哈希值
        String dbPasswordHash = user.getPassword();
        System.out.println("【数据库中的密码Hash值】: [" + dbPasswordHash + "]");
        System.out.println("【Hash值长度】: " + (dbPasswordHash != null ? dbPasswordHash.length() : "null"));
        System.out.println("【Hash值是否为空】: " + (dbPasswordHash == null || dbPasswordHash.trim().isEmpty()));
        
        // 检查 Hash 值格式
        if (dbPasswordHash != null) {
            System.out.println("【Hash值格式检查】");
            System.out.println("  - 是否以 $2a$ 开头: " + dbPasswordHash.startsWith("$2a$"));
            System.out.println("  - 是否以 $2b$ 开头: " + dbPasswordHash.startsWith("$2b$"));
            System.out.println("  - 是否以 $2y$ 开头: " + dbPasswordHash.startsWith("$2y$"));
        }

        // 3. 打印调试日志（关键！）
        log.info("登录调试 - 用户名: {}, 输入明文: [{}], 数据库Hash: [{}]", username, password, dbPasswordHash);
        System.out.println("【准备进行密码比对】");
        System.out.println("  - 比对方法: passwordEncoder.matches(rawPassword, encodedPassword)");
        System.out.println("  - 参数1 (rawPassword): [" + password + "]");
        System.out.println("  - 参数2 (encodedPassword): [" + dbPasswordHash + "]");

        // 4. 核心比对（必须使用 matches 方法）
        // ⚠️ 代码审计结果：正确使用了 passwordEncoder.matches() 方法
        // ⚠️ 严禁使用 String.equals() 进行密码比对！
        // matches 方法参数顺序：
        //   参数1 (rawPassword): 前端传来的明文密码
        //   参数2 (encodedPassword): 数据库查出来的以 $2a$ 开头的 Hash 字符串
        boolean passwordMatches = passwordEncoder.matches(password, dbPasswordHash);
        
        System.out.println("【密码比对结果】: " + passwordMatches);
        System.out.println("【比对结果类型】: " + (passwordMatches ? "匹配成功 ✓" : "匹配失败 ✗"));
        
        if (!passwordMatches) {
            System.out.println("【错误】密码匹配失败！");
            System.out.println("========================================");
            log.error("密码匹配失败！用户名: {}, 输入明文: [{}], 数据库Hash: [{}]", username, password, dbPasswordHash);
            throw new BusinessException("密码错误");
        }

        System.out.println("【密码验证通过】✓");

        // 5. 检查用户状态
        if (user.getStatus() == 0) {
            System.out.println("【错误】用户已被停用");
            System.out.println("========================================");
            throw new BusinessException("用户已被停用");
        }

        System.out.println("【用户状态检查】正常");

        // 6. 校验通过，生成 Token 并返回
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());
        System.out.println("【Token生成成功】");
        System.out.println("【登录成功】用户ID: " + user.getId() + ", 用户名: " + user.getUsername());
        System.out.println("========================================");
        
        log.info("登录成功 - 用户名: {}, 用户ID: {}", username, user.getId());
        
        return token;
    }

    /**
     * 获取用户权限列表
     * @param userId 用户ID
     * @return 权限字符串集合
     */
    public Set<String> getUserPermissions(Long userId) {
        Set<String> permissionSet = new HashSet<>();

        // 1. 查询用户角色关联
        List<SysUserRole> userRoles = sysUserRoleMapper.selectList(
                new LambdaQueryWrapper<SysUserRole>()
                        .eq(SysUserRole::getUserId, userId)
        );

        if (userRoles.isEmpty()) {
            return permissionSet;
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
            return permissionSet;
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

        return permissionSet;
    }
}