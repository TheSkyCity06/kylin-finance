package com.kylin.admin.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * 密码哈希值生成工具类
 * 用于生成 BCrypt 密码哈希值
 */
public class PasswordGenerator {
    
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        
        // 生成 admin123 的 BCrypt 哈希值
        String password = "admin123";
        String hash = encoder.encode(password);
        
        System.out.println("========================================");
        System.out.println("明文密码: " + password);
        System.out.println("BCrypt 哈希值: " + hash);
        System.out.println("哈希值长度: " + hash.length());
        System.out.println("========================================");
        
        // 验证生成的哈希值
        boolean matches = encoder.matches(password, hash);
        System.out.println("验证结果: " + matches);
        System.out.println("========================================");
        
        // 生成 SQL 更新语句
        System.out.println("\n【SQL 更新语句】");
        System.out.println("UPDATE `sys_user` SET `password` = '" + hash + "', `update_time` = NOW() WHERE `username` = 'admin';");
    }
}

