package com.kylin.admin.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 权限校验注解
 * 使用示例：@RequiresPermissions("finance:voucher:add")
 */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface RequiresPermissions {
    /**
     * 权限标识，支持多个权限（只要有一个匹配即可）
     */
    String[] value();
}

