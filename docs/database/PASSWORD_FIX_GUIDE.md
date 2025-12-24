# 密码修复指南

## 问题分析

从日志可以看到：
- 输入的明文密码：`admin123`
- 数据库中的Hash值：`$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy`
- Hash值格式正确（以`$2a$`开头，长度60）
- **但是密码比对结果是 false**

**根本原因**：数据库中的BCrypt哈希值不是由密码`admin123`生成的，或者生成时使用了不同的BCrypt配置。

## 解决方案

### 方法1：使用工具端点生成正确的哈希值（推荐）

1. **启动应用后，访问工具端点**：
   ```
   http://localhost:8080/admin/tool/generate-password?password=admin123
   ```

2. **获取返回的JSON结果**：
   ```json
   {
     "plainPassword": "admin123",
     "bcryptHash": "$2a$10$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
     "hashLength": 60,
     "verification": true,
     "sql": "UPDATE `sys_user` SET `password` = '...', `update_time` = NOW() WHERE `username` = 'admin';"
   }
   ```

3. **执行返回的SQL语句**：
   复制 `sql` 字段中的SQL语句，在MySQL中执行。

### 方法2：使用Java工具类生成

1. **运行 PasswordGenerator 工具类**：
   ```bash
   # 在IDE中运行 admin/src/main/java/com/kylin/admin/util/PasswordGenerator.java
   ```

2. **复制输出的SQL语句并执行**

### 方法3：直接在代码中生成（临时方案）

在 `SysUserService` 中添加一个临时方法：

```java
public void resetAdminPassword() {
    BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    String hash = encoder.encode("admin123");
    
    sysUserMapper.update(null, 
        new LambdaUpdateWrapper<SysUser>()
            .eq(SysUser::getUsername, "admin")
            .set(SysUser::getPassword, hash)
    );
    
    System.out.println("Admin密码已重置，新Hash值: " + hash);
}
```

然后调用这个方法重置密码。

## 执行步骤

### 步骤1：修改字段长度（如果还未执行）

```sql
USE kylin_finance;
ALTER TABLE `sys_user` 
MODIFY COLUMN `password` VARCHAR(100) NOT NULL COMMENT '密码（BCrypt加密，至少60字符）';
```

### 步骤2：生成正确的BCrypt哈希值

使用上述方法1或方法2生成正确的哈希值。

### 步骤3：更新数据库

执行生成的SQL语句，例如：
```sql
UPDATE `sys_user` 
SET `password` = '$2a$10$[新生成的哈希值]', 
    `update_time` = NOW() 
WHERE `username` = 'admin';
```

### 步骤4：验证

重新尝试登录，应该可以成功。

## 注意事项

1. **BCrypt特性**：BCrypt每次加密的结果都不同，但同一个明文密码生成的哈希值都可以通过`matches()`方法验证。

2. **字段长度**：确保`password`字段长度至少为60字符（推荐100字符）。

3. **工具端点安全**：`PasswordToolController`是临时工具，生产环境应删除或添加访问限制。

4. **密码安全**：生产环境中，密码重置应该通过安全的流程进行，而不是直接修改数据库。

## 验证SQL

执行以下SQL验证修复结果：

```sql
-- 检查字段长度
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'kylin_finance'
  AND TABLE_NAME = 'sys_user'
  AND COLUMN_NAME = 'password';

-- 检查admin用户的密码哈希值
SELECT 
    username,
    LENGTH(password) AS password_length,
    LEFT(password, 4) AS password_prefix
FROM sys_user
WHERE username = 'admin';
```

