package com.kylin.admin.aspect;

import com.kylin.admin.annotation.RequiresPermissions;
import com.kylin.common.BusinessException;
import lombok.RequiredArgsConstructor;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 权限校验 AOP 切面
 */
@Aspect
@Component
@RequiredArgsConstructor
public class PermissionAspect {

    @Before("@annotation(com.kylin.admin.annotation.RequiresPermissions)")
    public void checkPermission(JoinPoint joinPoint) {
        // 获取方法上的注解
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        RequiresPermissions annotation = signature.getMethod().getAnnotation(RequiresPermissions.class);

        if (annotation == null) {
            return;
        }

        String[] requiredPermissions = annotation.value();
        if (requiredPermissions.length == 0) {
            return;
        }

        // 获取当前用户权限
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new BusinessException("未登录或登录已过期");
        }

        Collection<? extends GrantedAuthority> authorities = authentication.getAuthorities();
        Set<String> userPermissions = authorities.stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toSet());

        // 检查是否有超级管理员权限
        if (userPermissions.contains("*:*:*")) {
            return;
        }

        // 检查是否有任一所需权限
        boolean hasPermission = false;
        for (String requiredPermission : requiredPermissions) {
            if (userPermissions.contains(requiredPermission)) {
                hasPermission = true;
                break;
            }
        }

        if (!hasPermission) {
            throw new BusinessException("权限不足，需要权限：" + String.join(", ", requiredPermissions));
        }
    }
}

