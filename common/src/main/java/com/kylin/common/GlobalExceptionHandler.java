package com.kylin.common;

import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理器
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 捕获自定义业务异常
     */
    @ExceptionHandler(BusinessException.class)
    public R<Void> handleBusinessException(BusinessException e) {
        log.error("业务异常: {}", e.getMessage());
        return R.error(e.getCode(), e.getMessage());
    }

    /**
     * 捕获认证异常
     */
    @ExceptionHandler(AuthenticationException.class)
    public R<Void> handleAuthenticationException(AuthenticationException e) {
        log.error("认证异常: {}", e.getMessage());
        return R.error(401, "认证失败：" + e.getMessage());
    }

    /**
     * 捕获权限不足异常
     */
    @ExceptionHandler(AccessDeniedException.class)
    public R<Void> handleAccessDeniedException(AccessDeniedException e) {
        log.error("权限不足: {}", e.getMessage());
        return R.error(403, "权限不足");
    }

    /**
     * 捕获所有未知的运行时异常
     */
    @ExceptionHandler(Exception.class)
    public R<Void> handleException(Exception e) {
        log.error("系统未知异常", e);
        return R.error("系统繁忙，请稍后重试");
    }
}
