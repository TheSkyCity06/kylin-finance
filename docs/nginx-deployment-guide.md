# Nginx 配置修正指南

## 🔍 问题分析

您的配置存在以下问题：

### 1. **重复配置冲突** ⚠️
- 主配置文件和反向代理文件都定义了 `/dev-api/` 的 location
- Nginx 会使用第一个匹配的 location，可能导致配置冲突
- 建议：只在一个地方配置 `/dev-api/`

### 2. **CORS 配置重复** ⚠️
- 两个文件都配置了 CORS 响应头
- 可能导致重复的响应头，某些浏览器可能报错
- 建议：统一在一个地方配置 CORS

### 3. **静态资源路径优化** 💡
- `/assets/` 配置基本正确，但可以使用 `alias` 替代 `root` 更精确
- 建议：添加其他静态资源文件的匹配规则

### 4. **配置顺序问题** ⚠️
- 主配置文件通过 `include` 包含了反向代理文件
- 如果两个文件都有 `/dev-api/` 配置，后加载的会覆盖先加载的
- 建议：明确配置的优先级

## ✅ 解决方案

### 方案一：只使用主配置文件（推荐）

**优点：**
- 配置集中管理，易于维护
- 避免配置冲突
- 更清晰的配置结构

**操作步骤：**

1. **修改主配置文件** (`/www/server/panel/vhost/8.145.48.161.conf`)
   - 使用 `docs/nginx-config-fixed.conf` 中的内容
   - 确保 `/dev-api/` 配置完整

2. **清空或删除反向代理文件中的 `/dev-api/` 配置**
   - 编辑 `/www/server/panel/vhost/rewrite/8.145.48.161.conf`
   - 删除 `#PROXY-START/` 和 `#PROXY-END/` 之间的所有内容
   - 或者保留文件为空（只保留注释）

3. **重新加载 Nginx 配置**
   ```bash
   nginx -t  # 测试配置
   nginx -s reload  # 重新加载
   ```

### 方案二：只使用反向代理文件

**优点：**
- 利用宝塔面板的配置管理功能
- 便于通过面板修改

**操作步骤：**

1. **修改反向代理文件** (`/www/server/panel/vhost/rewrite/8.145.48.161.conf`)
   - 使用 `docs/nginx-proxy-fixed.conf` 中的内容

2. **删除主配置文件中的 `/dev-api/` 配置**
   - 编辑 `/www/server/panel/vhost/8.145.48.161.conf`
   - 删除 `location /dev-api/` 块

3. **重新加载 Nginx 配置**

## 📋 配置要点说明

### 1. 静态资源配置

```nginx
location /assets/ {
    alias /www/wwwroot/kylin-web/assets/;  # 使用 alias 更精确
    expires 30d;
    add_header Cache-Control "public, no-transform";
}
```

**为什么使用 `alias` 而不是 `root`？**
- `root` 会将 location 路径追加到 root 路径后
- `alias` 会直接替换 location 路径
- 对于 `/assets/` 这样的精确路径，`alias` 更合适

### 2. API 反向代理配置

```nginx
location /dev-api/ {
    proxy_pass http://127.0.0.1:8080/;  # 末尾斜杠很重要！
    # ... 其他配置
}
```

**为什么 `proxy_pass` 末尾要有斜杠？**
- 有斜杠：`/dev-api/user/login` → `http://127.0.0.1:8080/user/login`（剥离前缀）
- 无斜杠：`/dev-api/user/login` → `http://127.0.0.1:8080/dev-api/user/login`（保留前缀）
- 您的后端 context-path 是 `/`，所以需要剥离 `/dev-api/` 前缀

### 3. CORS 配置

```nginx
# OPTIONS 预检请求
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' '$http_origin' always;
    # ... 其他 CORS 头
    return 204;
}

# 正常请求的 CORS 响应头
add_header 'Access-Control-Allow-Origin' '$http_origin' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
```

**为什么使用 `$http_origin` 而不是 `*`？**
- `*` 不能与 `Access-Control-Allow-Credentials: true` 同时使用
- `$http_origin` 动态获取请求的 Origin，更安全灵活

### 4. Authorization 头部透传

```nginx
proxy_set_header Authorization $http_authorization;
```

**为什么必须透传 Authorization？**
- Spring Security 需要 Authorization 头部进行身份验证
- 如果不透传，后端无法获取 token，导致 401 未授权错误

## 🔧 验证步骤

### 1. 检查配置语法

```bash
nginx -t
```

应该输出：
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 2. 重新加载配置

```bash
nginx -s reload
# 或
systemctl reload nginx
```

### 3. 测试静态资源

访问：`http://8.145.48.161/assets/index-xxx.js`
- 应该能正常加载 JS 文件
- 检查响应头中是否有 `Cache-Control: public, no-transform`

### 4. 测试 API 接口

在浏览器控制台执行：
```javascript
fetch('http://8.145.48.161/dev-api/admin/auth/login', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({username: 'test', password: 'test'})
})
.then(r => r.json())
.then(console.log)
```

检查：
- 请求是否成功到达后端（查看后端日志）
- 响应头中是否有正确的 CORS 头
- 是否有 401/403 错误（如果有，检查 Authorization 头部是否透传）

### 5. 检查错误日志

```bash
tail -f /www/wwwlogs/8.145.48.161.error.log
```

查看是否有相关错误信息。

## 🐛 常见问题排查

### 问题1：静态资源 404

**可能原因：**
- 文件路径不正确
- 文件权限问题
- Nginx 用户没有读取权限

**解决方法：**
```bash
# 检查文件是否存在
ls -la /www/wwwroot/kylin-web/assets/

# 检查文件权限
chown -R www:www /www/wwwroot/kylin-web
chmod -R 755 /www/wwwroot/kylin-web
```

### 问题2：API 请求 502 Bad Gateway

**可能原因：**
- 后端服务未启动
- 后端端口不是 8080
- 防火墙阻止连接

**解决方法：**
```bash
# 检查后端是否运行
netstat -tlnp | grep 8080

# 检查后端日志
tail -f /path/to/backend/logs/application.log

# 测试后端连接
curl http://127.0.0.1:8080/actuator/health
```

### 问题3：CORS 错误

**可能原因：**
- CORS 配置不正确
- 响应头重复
- 预检请求未正确处理

**解决方法：**
- 检查浏览器控制台的 Network 标签
- 查看 OPTIONS 请求的响应头
- 确保只有一个地方配置了 CORS

### 问题4：401 未授权

**可能原因：**
- Authorization 头部未透传
- Token 格式不正确
- 后端安全配置问题

**解决方法：**
- 检查 Nginx 配置中是否有 `proxy_set_header Authorization $http_authorization;`
- 检查浏览器请求头中是否包含 Authorization
- 查看后端日志确认是否收到 Authorization 头部

## 📝 最终推荐配置

**建议使用方案一（只使用主配置文件）**，配置如下：

1. 主配置文件包含完整的 `/dev-api/` 配置
2. 反向代理文件为空或只包含注释
3. 所有配置集中管理，避免冲突

这样可以：
- ✅ 避免配置冲突
- ✅ 统一管理 CORS
- ✅ 更清晰的配置结构
- ✅ 便于维护和调试

