# 麒麟财务管理系统 - 安全加固指南

## 一、敏感配置脱敏处理

### 1.1 数据库密码管理

#### 问题
当前 `application.yml` 中数据库密码明文存储：
```yaml
spring:
  datasource:
    password: Sun050714  # ⚠️ 明文密码
```

#### 解决方案

**方案一：使用环境变量（推荐）**

1. 修改 `application.yml`：
```yaml
spring:
  datasource:
    password: ${DB_PASSWORD:default_password}  # 从环境变量读取
```

2. 在生产环境设置环境变量：
```bash
# 方式1: 系统环境变量
export DB_PASSWORD="your_secure_password"
export DB_USERNAME="kylin_db_user"

# 方式2: 在 systemd 服务文件中设置
# /etc/systemd/system/kylin-finance.service
[Service]
Environment="DB_PASSWORD=your_secure_password"
Environment="DB_USERNAME=kylin_db_user"
```

**方案二：使用 Spring Cloud Config（适合微服务架构）**

**方案三：使用阿里云 Secrets Manager（推荐生产环境）**

```bash
# 安装阿里云 CLI
pip install aliyun-python-sdk-core aliyun-python-sdk-kms

# 存储密钥
aliyun kms CreateSecret --SecretName kylin-finance-db-password --SecretData "your_password"
```

在应用中集成：
```java
// 使用阿里云 SDK 获取密钥
String password = secretsManagerClient.getSecretValue("kylin-finance-db-password");
```

**方案四：使用 Jasypt 加密（适合中小型项目）**

1. 添加依赖：
```xml
<dependency>
    <groupId>com.github.ulisesbocchio</groupId>
    <artifactId>jasypt-spring-boot-starter</artifactId>
    <version>3.0.5</version>
</dependency>
```

2. 加密密码：
```bash
java -cp jasypt-1.9.3.jar org.jasypt.intf.cli.JasyptPBEStringEncryptionCLI \
  input="your_password" password="encryption_key" algorithm=PBEWithMD5AndDES
```

3. 配置文件中使用：
```yaml
spring:
  datasource:
    password: ENC(encrypted_password_here)

jasypt:
  encryptor:
    password: ${JASYPT_ENCRYPTOR_PASSWORD}
```

### 1.2 API 密钥和令牌管理

#### JWT Secret Key
```yaml
# ❌ 错误做法
jwt:
  secret: "my-secret-key-12345"

# ✅ 正确做法
jwt:
  secret: ${JWT_SECRET:default_secret_change_in_production}
```

#### 第三方 API 密钥
```yaml
# ❌ 错误做法
aliyun:
  access-key-id: "LTAI5t..."
  access-key-secret: "abc123..."

# ✅ 正确做法
aliyun:
  access-key-id: ${ALIYUN_ACCESS_KEY_ID}
  access-key-secret: ${ALIYUN_ACCESS_KEY_SECRET}
```

### 1.3 配置文件权限控制

```bash
# 设置配置文件权限（仅所有者可读）
chmod 600 application/src/main/resources/application-prod.yml

# 设置目录权限
chmod 700 /opt/kylin-finance/config
```

### 1.4 生产环境配置文件分离

创建 `application-prod.yml`：
```yaml
spring:
  datasource:
    url: jdbc:mysql://${DB_HOST:localhost}:3306/${DB_NAME:kylin_finance}?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=true
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 10

logging:
  level:
    root: INFO
    com.kylin: INFO
  file:
    path: /var/log/kylin-finance
```

## 二、阿里云安全组配置

### 2.1 需要开放的端口列表

| 端口 | 协议 | 方向 | 源地址 | 说明 |
|------|------|------|--------|------|
| 22 | TCP | 入站 | 您的办公IP/0.0.0.0 | SSH 管理（建议限制源IP） |
| 80 | TCP | 入站 | 0.0.0.0/0 | HTTP 访问 |
| 443 | TCP | 入站 | 0.0.0.0/0 | HTTPS 访问 |
| 8080 | TCP | 入站 | 内网IP段 | 后端API（仅内网，通过Nginx代理） |
| 3306 | TCP | 入站 | 内网IP段 | MySQL（仅内网，禁止公网访问） |

### 2.2 安全组配置步骤

1. **登录阿里云控制台**
   - 进入 ECS 实例管理
   - 选择您的实例 → 安全组 → 配置规则

2. **添加入站规则**

```
规则方向: 入方向
授权策略: 允许
协议类型: 自定义TCP
端口范围: 22/22
授权对象: 您的办公IP/32（例如：123.45.67.89/32）
描述: SSH管理端口
```

```
规则方向: 入方向
授权策略: 允许
协议类型: 自定义TCP
端口范围: 80/80
授权对象: 0.0.0.0/0
描述: HTTP访问
```

```
规则方向: 入方向
授权策略: 允许
协议类型: 自定义TCP
端口范围: 443/443
授权对象: 0.0.0.0/0
描述: HTTPS访问
```

3. **添加出站规则（默认允许所有，建议限制）**

```
规则方向: 出方向
授权策略: 允许
协议类型: 全部
端口范围: -1/-1
授权对象: 0.0.0.0/0
描述: 允许所有出站流量
```

### 2.3 安全建议

1. **SSH 端口限制**
   - 仅允许特定IP访问SSH端口
   - 考虑修改SSH默认端口（22 → 2222）

2. **数据库端口**
   - **禁止**在安全组中开放3306端口到公网
   - 仅允许内网IP访问（如：172.16.0.0/12）

3. **使用阿里云安全组白名单**
   - 配置IP白名单，限制管理端口访问

## 三、应用安全加固

### 3.1 Spring Boot 安全配置

#### 禁用不必要的端点
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info  # 仅暴露必要的端点
      base-path: /actuator
  endpoint:
    health:
      show-details: when-authorized  # 健康检查详情仅授权用户可见
```

#### 启用 HTTPS
```yaml
server:
  ssl:
    enabled: true
    key-store: classpath:keystore.p12
    key-store-password: ${KEYSTORE_PASSWORD}
    key-store-type: PKCS12
  port: 8443
```

### 3.2 数据库安全

#### 1. 创建专用数据库用户（最小权限原则）
```sql
-- 创建应用专用用户
CREATE USER 'kylin_app'@'localhost' IDENTIFIED BY 'strong_password_here';
CREATE USER 'kylin_app'@'127.0.0.1' IDENTIFIED BY 'strong_password_here';

-- 授予最小权限
GRANT SELECT, INSERT, UPDATE, DELETE ON kylin_finance.* TO 'kylin_app'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON kylin_finance.* TO 'kylin_app'@'127.0.0.1';

-- 禁止危险操作
REVOKE DROP, CREATE, ALTER ON *.* FROM 'kylin_app'@'localhost';
FLUSH PRIVILEGES;
```

#### 2. 启用 SSL 连接
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/kylin_finance?useSSL=true&requireSSL=true&verifyServerCertificate=true
```

#### 3. 数据库备份加密
```bash
# 备份时加密
mysqldump -u root -p kylin_finance | gpg --encrypt --recipient backup@example.com > backup.sql.gpg
```

### 3.3 日志安全

#### 1. 避免记录敏感信息
```yaml
logging:
  level:
    org.springframework.web: INFO
  pattern:
    # 不记录请求体（可能包含密码）
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
```

#### 2. 日志文件权限
```bash
chmod 640 /var/log/kylin-finance/*.log
chown appuser:appgroup /var/log/kylin-finance/
```

### 3.4 文件上传安全

```java
// 限制文件类型和大小
@PostMapping("/upload")
public R upload(@RequestParam("file") MultipartFile file) {
    // 检查文件类型
    String contentType = file.getContentType();
    if (!ALLOWED_TYPES.contains(contentType)) {
        throw new BusinessException("不支持的文件类型");
    }
    
    // 检查文件大小（10MB）
    if (file.getSize() > 10 * 1024 * 1024) {
        throw new BusinessException("文件大小超过限制");
    }
    
    // 扫描病毒（集成 ClamAV）
    // ...
}
```

## 四、系统安全加固

### 4.1 操作系统安全

#### 1. 更新系统补丁
```bash
# CentOS/Rocky Linux
sudo yum update -y

# Ubuntu
sudo apt update && sudo apt upgrade -y
```

#### 2. 配置防火墙（iptables/firewalld）
```bash
# 仅允许必要端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="YOUR_OFFICE_IP" port protocol="tcp" port="22" accept'
sudo firewall-cmd --reload
```

#### 3. 禁用 root 登录
```bash
# 编辑 /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no  # 使用密钥认证
PubkeyAuthentication yes

# 重启 SSH
sudo systemctl restart sshd
```

#### 4. 配置 fail2ban（防止暴力破解）
```bash
# 安装
sudo yum install fail2ban -y  # CentOS
sudo apt install fail2ban -y  # Ubuntu

# 配置
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# 编辑 jail.local，设置 SSH 和 Web 防护规则
```

### 4.2 应用运行用户

```bash
# 创建专用用户
sudo useradd -r -s /bin/false kylin-app

# 使用非 root 用户运行应用
sudo -u kylin-app java -jar app.jar
```

### 4.3 文件系统安全

```bash
# 设置应用目录权限
sudo chown -R kylin-app:kylin-app /opt/kylin-finance
sudo chmod -R 750 /opt/kylin-finance

# 配置文件权限
sudo chmod 600 /opt/kylin-finance/config/*.yml
```

## 五、网络安全

### 5.1 使用 HTTPS

#### 获取 SSL 证书（Let's Encrypt）
```bash
# 安装 certbot
sudo yum install certbot python3-certbot-nginx -y

# 申请证书
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 自动续期
sudo certbot renew --dry-run
```

### 5.2 WAF（Web 应用防火墙）

阿里云 WAF 配置建议：
- 启用 SQL 注入防护
- 启用 XSS 防护
- 启用 CC 攻击防护
- 配置 IP 白名单/黑名单

### 5.3 DDoS 防护

- 启用阿里云 DDoS 基础防护（免费）
- 配置流量清洗规则
- 设置异常流量告警

## 六、监控和审计

### 6.1 日志审计

```bash
# 配置日志轮转
sudo vim /etc/logrotate.d/kylin-finance

/var/log/kylin-finance/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 kylin-app kylin-app
}
```

### 6.2 安全监控

- 配置阿里云云监控告警
- 异常登录告警
- 异常流量告警
- 数据库连接异常告警

### 6.3 定期安全检查清单

- [ ] 检查系统补丁更新
- [ ] 检查日志中的异常访问
- [ ] 检查数据库用户权限
- [ ] 检查 SSL 证书有效期
- [ ] 检查备份文件完整性
- [ ] 检查敏感配置文件权限
- [ ] 检查安全组规则
- [ ] 检查应用依赖漏洞（使用 OWASP Dependency-Check）

## 七、应急响应

### 7.1 安全事件处理流程

1. **发现安全事件**
   - 异常登录
   - 数据泄露
   - 服务中断

2. **立即响应**
   ```bash
   # 隔离受影响系统
   sudo systemctl stop kylin-finance
   
   # 备份日志
   sudo tar -czf /opt/backup/logs-$(date +%Y%m%d).tar.gz /var/log/kylin-finance
   
   # 通知相关人员
   ```

3. **调查分析**
   - 查看日志
   - 分析攻击路径
   - 评估影响范围

4. **恢复和加固**
   - 修复漏洞
   - 恢复服务
   - 加强防护

### 7.2 联系信息

- **安全团队**: security@example.com
- **运维团队**: ops@example.com
- **阿里云工单**: https://workorder.console.aliyun.com

---

**重要提醒**：
1. 定期更新所有依赖和系统补丁
2. 使用强密码策略（至少16位，包含大小写字母、数字、特殊字符）
3. 启用多因素认证（MFA）
4. 定期进行安全审计和渗透测试
5. 建立完善的安全事件响应机制


