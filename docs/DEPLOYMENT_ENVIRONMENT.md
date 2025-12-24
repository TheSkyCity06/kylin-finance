# 麒麟财务管理系统 - 环境分析文档

## 一、运行环境要求

### 1.1 后端环境

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| JDK | 17+ | 推荐使用 OpenJDK 17 或 Oracle JDK 17 |
| Maven | 3.6+ | 用于项目构建和依赖管理 |
| Spring Boot | 3.2.0 | 框架版本 |
| MySQL | 8.0+ | 数据库服务器 |

### 1.2 前端环境

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| Node.js | 18+ | 推荐使用 Node.js 18 LTS 或更高版本 |
| npm | 9+ | Node.js 包管理器 |
| Vite | 5.2.8 | 构建工具（已包含在项目中） |

### 1.3 数据库环境

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| MySQL | 8.0+ | 推荐使用 MySQL 8.0.30+ |
| 字符集 | utf8mb4 | 支持完整的 Unicode 字符集 |
| 排序规则 | utf8mb4_unicode_ci | 推荐排序规则 |

### 1.4 Web 服务器

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| Nginx | 1.20+ | 用于反向代理和静态资源服务 |

### 1.5 容器化环境（可选）

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| Docker | 20.10+ | 容器运行时 |
| Docker Compose | 2.0+ | 容器编排工具 |

## 二、系统资源要求

### 2.1 最低配置（测试/小规模使用）

- **CPU**: 2 核
- **内存**: 2GB（需优化 JVM 参数）
- **磁盘**: 40GB SSD
- **网络**: 5Mbps

**注意：** 2GB 内存服务器需要：
- JVM 参数：`-Xms512m -Xmx1536m`（预留系统和其他服务内存）
- 关闭不必要的服务
- 使用轻量级数据库配置

### 2.2 推荐配置（生产环境）

- **CPU**: 4 核或以上
- **内存**: 8GB 或以上
- **磁盘**: 100GB+ SSD
- **网络**: 10Mbps 或以上

### 2.3 资源优化建议

**对于 2GB 内存服务器：**
```bash
# JVM 参数
-Xms512m -Xmx1536m -XX:+UseG1GC

# MySQL 配置优化
innodb_buffer_pool_size=512M
max_connections=50
```

### 2.3 数据库资源要求

- **内存**: 至少 2GB（推荐 4GB+）
- **磁盘**: 至少 50GB（根据数据量调整）
- **连接数**: 支持至少 100 个并发连接

## 三、端口要求

| 服务 | 端口 | 协议 | 说明 |
|------|------|------|------|
| 后端 API | 8080 | HTTP | Spring Boot 应用端口 |
| MySQL | 3306 | TCP | 数据库端口（建议仅内网访问） |
| Nginx | 80 | HTTP | HTTP 访问端口 |
| Nginx | 443 | HTTPS | HTTPS 访问端口 |
| SSH | 22 | TCP | 服务器管理端口 |

## 四、依赖检查命令

### 4.1 检查 Java 版本
```bash
java -version
# 应显示：openjdk version "17" 或更高版本
```

### 4.2 检查 Maven 版本
```bash
mvn -version
# 应显示：Apache Maven 3.6.x 或更高版本
```

### 4.3 检查 Node.js 版本
```bash
node -v
# 应显示：v18.x.x 或更高版本

npm -v
# 应显示：9.x.x 或更高版本
```

### 4.4 检查 MySQL 版本
```bash
mysql --version
# 应显示：mysql Ver 8.0.x 或更高版本
```

### 4.5 检查 Nginx 版本
```bash
nginx -v
# 应显示：nginx version: nginx/1.20.x 或更高版本
```

### 4.6 检查 Docker 版本（如果使用容器化部署）
```bash
docker --version
# 应显示：Docker version 20.10.x 或更高版本

docker-compose --version
# 应显示：Docker Compose version 2.x.x
```

## 五、操作系统兼容性

### 5.1 推荐操作系统

- **CentOS 7/8** 或 **Rocky Linux 8/9**
- **Ubuntu 20.04 LTS** 或 **Ubuntu 22.04 LTS**
- **Alibaba Cloud Linux 2/3**

### 5.2 系统依赖安装

#### CentOS/Rocky Linux
```bash
# 安装基础工具
sudo yum install -y wget curl git

# 安装编译工具
sudo yum groupinstall -y "Development Tools"
```

#### Ubuntu/Debian
```bash
# 安装基础工具
sudo apt-get update
sudo apt-get install -y wget curl git

# 安装编译工具
sudo apt-get install -y build-essential
```

## 六、防火墙配置

### 6.1 需要开放的端口

- **80**: HTTP 访问（必需）
- **443**: HTTPS 访问（必需）
- **22**: SSH 管理（必需）
- **8080**: 后端 API（仅内网，通过 Nginx 代理）

### 6.2 防火墙命令示例

#### CentOS/Rocky Linux (firewalld)
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

#### Ubuntu (ufw)
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 七、时区配置

系统时区应设置为 **Asia/Shanghai**：

```bash
# 设置时区
sudo timedatectl set-timezone Asia/Shanghai

# 验证时区
timedatectl
```

## 八、环境变量建议

建议在生产环境中设置以下环境变量：

```bash
# Java 环境变量
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Maven 环境变量（如果未全局安装）
export MAVEN_HOME=/opt/maven
export PATH=$MAVEN_HOME/bin:$PATH

# Node.js 环境变量（如果使用 nvm）
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

## 九、性能优化建议

### 9.1 JVM 参数建议

生产环境 JVM 启动参数：
```bash
-Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200
```

### 9.2 MySQL 配置建议

在 `/etc/my.cnf` 中添加：
```ini
[mysqld]
max_connections=200
innodb_buffer_pool_size=2G
innodb_log_file_size=256M
```

### 9.3 Nginx 性能优化

参考 `nginx.conf` 中的性能优化配置。


