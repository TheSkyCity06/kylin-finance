package com.kylin.admin.controller;

import com.kylin.admin.annotation.RequiresPermissions;
import com.kylin.admin.config.SecurityUser;
import com.kylin.admin.dto.LoginDTO;
import com.kylin.admin.service.SysUserService;
import com.kylin.admin.util.JwtUtil;
import com.kylin.common.R;
import com.kylin.admin.entity.SysUser;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/admin/auth")
@RequiredArgsConstructor
public class AuthController {

    private final SysUserService sysUserService;
    private final JwtUtil jwtUtil;

    /**
     * 登录接口
     */
    @PostMapping("/login")
    public R<Map<String, Object>> login(@RequestBody LoginDTO loginBody) {
        // 1. 执行登录，获取 JWT Token
        String token = sysUserService.login(loginBody.getUsername(), loginBody.getPassword());

        // 2. 从 Token 中获取用户ID
        Long userId = jwtUtil.getUserIdFromToken(token);

        // 3. 获取该用户的权限集合
        Set<String> permissions = sysUserService.getUserPermissions(userId);

        // 4. 构建返回结果
        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("permissions", permissions); // 前端根据这个数组判断显示哪些按钮

        return R.ok(result);
    }

    /**
     * 获取当前用户信息接口
     * 注意：这里暂时不添加权限校验，因为用户登录后需要能获取自己的信息
     */
    @GetMapping("/info")
    public R<Map<String, Object>> getInfo() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        
        if (authentication == null || !(authentication.getPrincipal() instanceof SecurityUser)) {
            return R.error("未登录或登录已过期");
        }

        SecurityUser securityUser = (SecurityUser) authentication.getPrincipal();
        SysUser user = securityUser.getUser();

        // 获取权限列表
        List<String> permissions = securityUser.getAuthorities().stream()
                .map(authority -> authority.getAuthority())
                .collect(Collectors.toList());

        Map<String, Object> result = new HashMap<>();
        result.put("id", user.getId());
        result.put("username", user.getUsername());
        result.put("nickname", user.getNickname());
        result.put("email", user.getEmail());
        result.put("phone", user.getPhone());
        result.put("permissions", permissions);

        return R.ok(result);
    }
}