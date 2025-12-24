# 麒麟财务管理系统 - 部署文档总览

## 📚 文档目录

本目录包含完整的部署相关文档，帮助您将麒麟财务管理系统部署到阿里云 ECS 服务器。

### 核心文档

1. **[环境分析文档](DEPLOYMENT_ENVIRONMENT.md)**
   - 系统环境要求
   - 依赖版本说明
   - 端口和资源要求
   - 环境检查命令

2. **[部署操作手册](DEPLOYMENT_MANUAL.md)** ⭐ **推荐先看**
   - 从零开始的完整部署步骤
   - 详细的命令和配置说明
   - 故障排查指南
   - 日常维护操作

3. **[安全加固指南](SECURITY_HARDENING.md)**
   - 敏感配置脱敏处理
   - 阿里云安全组配置
   - 应用安全加固
   - 应急响应流程

4. **[宝塔面板部署指南](BT_PANEL_GUIDE.md)** ⭐ **推荐使用宝塔面板的用户**
   - 宝塔面板专用部署步骤
   - 图形化界面配置说明
   - 宝塔面板优化建议

## 🚀 快速开始

### 方式一：传统部署（推荐新手）

1. **如果使用宝塔面板**：阅读 [宝塔面板部署指南](BT_PANEL_GUIDE.md)
2. **如果使用命令行**：阅读 [部署操作手册](DEPLOYMENT_MANUAL.md)
3. 按照步骤逐一执行
4. 参考 [安全加固指南](SECURITY_HARDENING.md) 进行安全配置

### 方式二：Docker 部署（推荐生产环境）

```bash
# 1. 配置环境变量
cp .env.example .env
vim .env  # 修改数据库密码等配置

# 2. 启动服务
docker-compose up -d --build

# 3. 查看日志
docker-compose logs -f
```

### 方式三：使用部署脚本

```bash
# 1. 配置 deploy.sh 中的变量
vim deploy.sh

# 2. 执行部署
chmod +x deploy.sh
./deploy.sh deploy
```

## 📋 部署前检查清单

- [ ] 确认服务器规格（推荐 4核8GB）
- [ ] 确认操作系统版本（CentOS 7+ 或 Ubuntu 20.04+）
- [ ] 准备域名（可选，建议配置）
- [ ] 准备 SSL 证书（或使用 Let's Encrypt）
- [ ] 确认安全组规则
- [ ] 准备数据库密码（强密码）
- [ ] 阅读 [环境分析文档](DEPLOYMENT_ENVIRONMENT.md)

## 🔧 部署文件说明

### 根目录文件

- `deploy.sh` - 自动化部署脚本
- `Dockerfile` - Docker 镜像构建文件
- `docker-compose.yml` - Docker Compose 编排配置
- `.env.example` - 环境变量配置示例

### Nginx 配置

- `nginx/nginx.conf` - Nginx 主配置文件
- `nginx/conf.d/` - 站点配置文件目录
- `nginx/ssl/` - SSL 证书目录（需自行配置）

### 应用配置

- `application/src/main/resources/application-prod.yml` - 生产环境配置模板

### 数据库脚本

- `database/schema/` - 数据库表结构脚本
  - `init.sql` - 主初始化脚本（核心财务表，必需）
  - `rbac_tables.sql` - RBAC权限管理表（可选）
  - `biz_expense_claim.sql` - 费用报销业务表（可选）
  - `biz_receipt_payment.sql` - 收付款业务表（可选）
- `database/scripts/` - 数据库维护脚本
- `database/seeds/` - 测试数据和种子数据（仅开发/测试环境）

## 🔒 安全注意事项

⚠️ **重要**：部署前请务必阅读 [安全加固指南](SECURITY_HARDENING.md)

1. **修改所有默认密码**
   - 数据库 root 密码
   - 应用数据库用户密码
   - JWT Secret Key

2. **配置安全组**
   - 仅开放必要端口（80, 443, 22）
   - 限制 SSH 端口访问源 IP
   - **禁止**公网访问数据库端口（3306）

3. **使用环境变量**
   - 不要将敏感信息硬编码在配置文件中
   - 使用环境变量或密钥管理服务

4. **配置 SSL 证书**
   - 生产环境必须使用 HTTPS
   - 推荐使用 Let's Encrypt 免费证书

## 📞 获取帮助

### 常见问题

1. **部署失败**
   - 查看日志：`sudo journalctl -u kylin-finance -n 100`
   - 检查端口占用：`sudo netstat -tuln | grep 8080`
   - 参考 [部署操作手册 - 故障排查](DEPLOYMENT_MANUAL.md#十故障排查)

2. **数据库连接失败**
   - 检查 MySQL 服务：`sudo systemctl status mysql`
   - 测试连接：`mysql -u kylin_app -p`
   - 检查防火墙规则

3. **Nginx 502 错误**
   - 检查后端服务：`curl http://localhost:8080/actuator/health`
   - 查看 Nginx 错误日志：`sudo tail -f /var/log/nginx/error.log`

### 文档更新

如果发现文档有误或需要补充，请：
1. 提交 Issue
2. 提交 Pull Request

## 📝 部署后验证

部署完成后，请验证以下内容：

- [ ] 前端页面可以正常访问
- [ ] API 接口可以正常调用
- [ ] 数据库连接正常
- [ ] SSL 证书配置正确
- [ ] 日志正常记录
- [ ] 备份脚本正常工作
- [ ] 监控告警配置完成

## 🎯 下一步

部署完成后，建议：

1. **性能优化**
   - 调整 JVM 参数
   - 优化数据库配置
   - 配置 CDN（如需要）

2. **监控告警**
   - 配置阿里云云监控
   - 设置异常告警
   - 配置日志收集

3. **备份策略**
   - 配置数据库自动备份
   - 配置应用代码备份
   - 测试备份恢复流程

4. **安全审计**
   - 定期检查日志
   - 定期更新依赖
   - 定期进行安全扫描

---

**祝您部署顺利！** 🎉

如有问题，请参考相应文档或提交 Issue。


