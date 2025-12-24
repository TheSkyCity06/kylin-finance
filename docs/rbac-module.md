# RBAC 权限管理系统使用指南

## 概述

本系统实现了基于 RBAC（Role-Based Access Control）的权限管理，使用 Spring Security + JWT 进行认证和授权。

## 数据库设计

系统包含以下5张表：

1. **sys_user** - 系统用户表
2. **sys_role** - 系统角色表
3. **sys_menu** - 系统菜单/权限表
4. **sys_user_role** - 用户角色关联表（多对多）
5. **sys_role_menu** - 角色菜单关联表（多对多）

### 初始化数据库

执行 `database/rbac_tables.sql` 文件创建表结构和初始化数据。

默认管理员账号：
- 用户名：`admin`
- 密码：`admin123`（BCrypt加密存储）

## 核心功能

### 1. JWT 认证

- 登录成功后返回 JWT Token
- Token 默认有效期 24 小时（可在 `application.yml` 中配置）
- Token 存储在请求头：`Authorization: Bearer {token}`

### 2. 权限校验

#### 使用 @RequiresPermissions 注解

在 Controller 方法上添加注解进行权限校验：

```java
@PostMapping("/voucher/add")
@RequiresPermissions("finance:voucher:add")
public R<Void> addVoucher(@RequestBody VoucherDTO dto) {
    // 业务逻辑
}
```

#### 权限标识格式

权限标识采用三级格式：`模块:功能:操作`

示例：
- `finance:voucher:add` - 财务模块-凭证-新增
- `finance:voucher:query` - 财务模块-凭证-查询
- `finance:voucher:audit` - 财务模块-凭证-审核
- `finance:account:list` - 财务模块-科目-列表
- `*:*:*` - 超级管理员权限（拥有所有权限）

### 3. 权限查询逻辑

系统通过以下步骤查询用户权限：

1. 根据用户ID查询 `sys_user_role` 表获取角色ID列表
2. 根据角色ID查询 `sys_role_menu` 表获取菜单ID列表
3. 根据菜单ID查询 `sys_menu` 表获取权限标识（perms字段）
4. 返回权限标识集合

## 配置说明

### application.yml 配置

```yaml
jwt:
  secret: your-secret-key-minimum-256-bits  # JWT 密钥（生产环境请修改）
  expiration: 86400000  # Token 过期时间（毫秒），默认24小时
```

### Spring Security 配置

- 登录接口 `/admin/auth/login` 允许匿名访问
- 其他接口需要携带有效的 JWT Token
- 使用无状态会话（STATELESS）

## API 接口

### 1. 登录接口

**请求：**
```http
POST /admin/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

**响应：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "permissions": [
      "finance:voucher:add",
      "finance:voucher:query",
      "finance:account:list"
    ]
  }
}
```

### 2. 获取用户信息接口

**请求：**
```http
GET /admin/auth/info
Authorization: Bearer {token}
```

**响应：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "id": 1,
    "username": "admin",
    "nickname": "系统管理员",
    "email": "admin@kylin.com",
    "phone": "13800138000",
    "permissions": ["finance:voucher:add", ...]
  }
}
```

## 使用示例

### 在 Controller 中使用权限注解

```java
@RestController
@RequestMapping("/finance/voucher")
@RequiredArgsConstructor
public class VoucherController {

    @PostMapping("/add")
    @RequiresPermissions("finance:voucher:add")
    public R<Void> addVoucher(@RequestBody VoucherDTO dto) {
        // 只有拥有 finance:voucher:add 权限的用户才能访问
        return R.ok();
    }

    @PostMapping("/query")
    @RequiresPermissions("finance:voucher:query")
    public R<List<Voucher>> queryVoucher(@RequestBody QueryDTO dto) {
        // 只有拥有 finance:voucher:query 权限的用户才能访问
        return R.ok();
    }
}
```

### 获取当前登录用户信息

```java
@GetMapping("/current")
public R<Map<String, Object>> getCurrentUser() {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    
    if (authentication.getPrincipal() instanceof SecurityUser) {
        SecurityUser securityUser = (SecurityUser) authentication.getPrincipal();
        SysUser user = securityUser.getUser();
        // 使用 user 对象
    }
    
    return R.ok();
}
```

## 安全注意事项

1. **生产环境配置**
   - 修改 `application.yml` 中的 JWT secret 密钥
   - 使用强密码策略
   - 启用 HTTPS

2. **密码加密**
   - 使用 BCryptPasswordEncoder 加密存储密码
   - 默认管理员密码：`admin123`（BCrypt加密后存储在数据库中）

3. **Token 安全**
   - Token 过期时间建议根据业务需求调整
   - 前端应安全存储 Token（避免 XSS 攻击）
   - 考虑实现 Token 刷新机制

## 文件结构

```
admin/
├── src/main/java/com/kylin/admin/
│   ├── annotation/
│   │   └── RequiresPermissions.java      # 权限注解
│   ├── aspect/
│   │   └── PermissionAspect.java         # 权限校验 AOP 切面
│   ├── config/
│   │   ├── SecurityConfig.java           # Spring Security 配置
│   │   ├── SecurityUser.java             # Security 用户详情实现
│   │   └── MyMetaObjectHandler.java     # MyBatis-Plus 自动填充
│   ├── controller/
│   │   └── AuthController.java           # 认证控制器
│   ├── entity/
│   │   ├── SysUser.java                  # 用户实体
│   │   ├── SysRole.java                  # 角色实体
│   │   ├── SysMenu.java                  # 菜单实体
│   │   ├── SysUserRole.java              # 用户角色关联实体
│   │   └── SysRoleMenu.java              # 角色菜单关联实体
│   ├── filter/
│   │   └── JwtAuthenticationFilter.java   # JWT 认证过滤器
│   ├── mapper/
│   │   ├── SysUserMapper.java
│   │   ├── SysRoleMapper.java
│   │   ├── SysMenuMapper.java
│   │   ├── SysUserRoleMapper.java
│   │   └── SysRoleMenuMapper.java
│   ├── service/
│   │   ├── SysUserService.java           # 用户服务
│   │   └── impl/
│   │       └── UserDetailsServiceImpl.java  # UserDetailsService 实现
│   └── util/
│       └── JwtUtil.java                  # JWT 工具类
```

## 常见问题

### 1. 登录后提示权限不足

检查：
- 用户是否分配了角色
- 角色是否分配了菜单权限
- 菜单的 `perms` 字段是否正确设置

### 2. Token 过期

Token 默认24小时过期，过期后需要重新登录。

### 3. 权限注解不生效

确保：
- 已启用 AOP：`@EnableAspectJAutoProxy`
- 切面类已添加 `@Aspect` 和 `@Component` 注解
- Controller 方法上正确添加了 `@RequiresPermissions` 注解

## 扩展建议

1. **角色管理接口**：实现角色的增删改查
2. **菜单管理接口**：实现菜单的增删改查
3. **用户管理接口**：实现用户的增删改查和角色分配
4. **Token 刷新机制**：实现 Refresh Token
5. **权限缓存**：使用 Redis 缓存用户权限，提升性能

