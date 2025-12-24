package com.kylin.admin.controller;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 密码工具控制器（临时工具，生产环境应删除）
 * 用于生成 BCrypt 密码哈希值
 */
@RestController
@RequestMapping("/admin/tool")
public class PasswordToolController {

    /**
     * 生成密码哈希值
     * 访问示例：http://localhost:8080/admin/tool/generate-password?password=admin123
     */
    @GetMapping("/generate-password")
    public Map<String, Object> generatePassword(@RequestParam(defaultValue = "admin123") String password) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String hash = encoder.encode(password);
        
        // 验证生成的哈希值
        boolean matches = encoder.matches(password, hash);
        
        Map<String, Object> result = new HashMap<>();
        result.put("plainPassword", password);
        result.put("bcryptHash", hash);
        result.put("hashLength", hash.length());
        result.put("verification", matches);
        result.put("sql", "UPDATE `sys_user` SET `password` = '" + hash + "', `update_time` = NOW() WHERE `username` = 'admin';");
        
        return result;
    }
}

