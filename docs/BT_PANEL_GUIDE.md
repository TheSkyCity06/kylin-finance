# 宝塔 Linux 面板部署指南

## 📋 概述

本指南专门针对使用宝塔 Linux 面板的服务器，提供详细的部署步骤和配置说明。

## 🔧 宝塔面板环境准备

### 1. 确认宝塔面板版本

```bash
# 查看宝塔面板版本
bt version

# 或登录面板查看：http://your-server-ip:8888
```

### 2. 宝塔面板常用目录

- **网站根目录**: `/www/wwwroot/`
- **Nginx 配置**: `/www/server/nginx/conf/nginx.conf`
- **站点配置**: `/www/server/panel/vhost/nginx/`
- **SSL 证书**: `/www/server/panel/vhost/cert/`
- **日志目录**: `/www/wwwlogs/`
- **MySQL 数据**: `/www/server/data/`

## 🚀 部署步骤

### 步骤一：安装必要软件

#### 1.1 安装 Java 17

**方式一：通过宝塔面板安装**
1. 登录宝塔面板
2. 进入"软件商店" → "运行环境"
3. 搜索"Java"并安装 OpenJDK 17

**方式二：命令行安装**
```bash
# CentOS/Alibaba Cloud Linux
sudo yum install -y java-17-openjdk java-17-openjdk-devel

# Ubuntu
sudo apt install -y openjdk-17-jdk

# 验证安装
java -version
```

#### 1.2 安装 Maven

```bash
# 下载 Maven
cd /tmp
wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz

# 解压到 /opt
sudo tar -xzf apache-maven-3.9.6-bin.tar.gz -C /opt

# 设置环境变量
echo 'export MAVEN_HOME=/opt/apache-maven-3.9.6' >> ~/.bashrc
echo 'export PATH=$MAVEN_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 验证
mvn -version
```

#### 1.3 安装 Node.js

**通过宝塔面板安装（推荐）：**
1. 进入"软件商店" → "运行环境"
2. 搜索"Node.js"并安装 Node.js 18 LTS

**命令行安装：**
```bash
# 使用 NodeSource 仓库
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 验证
node -v
npm -v
```

#### 1.4 安装 MySQL

**通过宝塔面板安装（推荐）：**
1. 进入"软件商店" → "数据库"
2. 安装 MySQL 8.0
3. 设置 root 密码（请使用强密码）

**命令行安装：**
```bash
# CentOS/Alibaba Cloud Linux
sudo yum install -y mysql-server
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Ubuntu
sudo apt install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql
```

### 步骤二：部署应用代码

#### 2.1 上传项目文件

**方式一：使用宝塔面板文件管理器**
1. 登录宝塔面板
2. 进入"文件"管理
3. 上传项目压缩包到 `/www/wwwroot/`
4. 解压文件

**方式二：使用 Git（推荐）**
```bash
cd /www/wwwroot
git clone your-git-repo-url kylin-finance
cd kylin-finance
```

**方式三：使用 SCP**
```bash
# 从本地服务器上传
scp -r /path/to/kylin-finance root@your-server-ip:/www/wwwroot/
```

#### 2.2 设置目录权限

```bash
# 创建应用用户（如果不存在）
sudo useradd -m -s /bin/bash kylin-app

# 设置目录权限
sudo chown -R kylin-app:kylin-app /www/wwwroot/kylin-finance
sudo chmod -R 755 /www/wwwroot/kylin-finance

# 创建日志目录
sudo mkdir -p /www/wwwlogs/kylin-finance
sudo chown -R kylin-app:kylin-app /www/wwwlogs/kylin-finance
```

### 步骤三：配置数据库

#### 3.1 创建数据库

**通过宝塔面板：**
1. 进入"数据库" → "添加数据库"
2. 数据库名：`kylin_finance`
3. 用户名：`kylin_app`
4. 密码：设置强密码
5. 访问权限：本地服务器

**命令行方式：**
```bash
mysql -u root -p

CREATE DATABASE kylin_finance DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'kylin_app'@'localhost' IDENTIFIED BY 'your_strong_password';
GRANT ALL PRIVILEGES ON kylin_finance.* TO 'kylin_app'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### 3.2 导入数据库脚本

```bash
# 导入核心表
mysql -u kylin_app -p kylin_finance < /www/wwwroot/kylin-finance/database/schema/init.sql

# 导入可选模块（根据需要）
mysql -u kylin_app -p kylin_finance < /www/wwwroot/kylin-finance/database/schema/rbac_tables.sql
```

### 步骤四：编译和部署应用

#### 4.1 编译后端

```bash
cd /www/wwwroot/kylin-finance

# 编译项目
mvn clean package -DskipTests

# 检查编译结果
ls -lh application/target/kylin-finance-1.0.0.jar
```

#### 4.2 编译前端

```bash
cd /www/wwwroot/kylin-finance/frontend/kylin-finance-ui

# 安装依赖
npm install

# 构建生产版本
npm run build

# 检查构建结果
ls -lh dist/
```

#### 4.3 部署前端静态资源

```bash
# 创建网站目录
sudo mkdir -p /www/wwwroot/kylin-finance-web

# 复制前端构建文件
sudo cp -r /www/wwwroot/kylin-finance/frontend/kylin-finance-ui/dist/* /www/wwwroot/kylin-finance-web/

# 设置权限
sudo chown -R www:www /www/wwwroot/kylin-finance-web
```

### 步骤五：配置 Nginx

#### 5.1 在宝塔面板中创建网站

1. 登录宝塔面板
2. 进入"网站" → "添加站点"
3. 填写信息：
   - **域名**：您的域名或 IP（如：`8.145.48.161`）
   - **根目录**：`/www/wwwroot/kylin-finance-web`
   - **PHP 版本**：选择"纯静态"
4. 点击"提交"

#### 5.2 配置反向代理

1. 进入网站设置 → "反向代理"
2. 点击"添加反向代理"
3. 配置如下：
   - **代理名称**：`kylin-finance-api`
   - **目标URL**：`http://127.0.0.1:8080`
   - **发送域名**：`$host`
   - **代理目录**：`/api/`
   - **缓存**：关闭
4. 点击"提交"

#### 5.3 修改 Nginx 配置（高级）

如果需要更精细的控制，可以编辑网站配置文件：

```bash
# 编辑网站配置文件
sudo vim /www/server/panel/vhost/nginx/your-domain.com.conf
```

参考配置模板：
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /www/wwwroot/kylin-finance-web;
    index index.html;

    # 前端静态资源
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 静态资源缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

保存后，在宝塔面板中点击"重载配置"。

### 步骤六：配置 SSL 证书（推荐）

#### 6.1 使用 Let's Encrypt 免费证书

1. 进入网站设置 → "SSL"
2. 选择"Let's Encrypt"
3. 填写邮箱地址
4. 点击"申请"
5. 申请成功后，开启"强制 HTTPS"

#### 6.2 上传自有证书

1. 进入网站设置 → "SSL"
2. 选择"其他证书"
3. 上传证书文件（.pem 和 .key）
4. 保存并开启 HTTPS

### 步骤七：配置应用服务

#### 7.1 创建 Systemd 服务

```bash
# 创建服务文件
sudo vim /etc/systemd/system/kylin-finance.service
```

服务文件内容：
```ini
[Unit]
Description=Kylin Finance Application
After=network.target mysql.service

[Service]
Type=simple
User=kylin-app
Group=kylin-app
WorkingDirectory=/www/wwwroot/kylin-finance
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
Environment="DB_PASSWORD=your_password_here"
# 2GB 内存服务器使用较小 JVM 参数
ExecStart=/usr/bin/java -Xms512m -Xmx1536m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -jar /www/wwwroot/kylin-finance/application/target/kylin-finance-1.0.0.jar --spring.profiles.active=prod
ExecStop=/bin/kill -15 $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=kylin-finance

[Install]
WantedBy=multi-user.target
```

#### 7.2 启动服务

```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start kylin-finance

# 设置开机自启
sudo systemctl enable kylin-finance

# 查看状态
sudo systemctl status kylin-finance

# 查看日志
sudo journalctl -u kylin-finance -f
```

### 步骤八：配置应用配置文件

#### 8.1 创建生产环境配置

```bash
# 复制生产环境配置模板
cp /www/wwwroot/kylin-finance/application/src/main/resources/application-prod.yml \
   /www/wwwroot/kylin-finance/application/src/main/resources/application-prod.yml

# 编辑配置
vim /www/wwwroot/kylin-finance/application/src/main/resources/application-prod.yml
```

修改数据库连接信息：
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/kylin_finance?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false
    username: kylin_app
    password: ${DB_PASSWORD}  # 使用环境变量
```

#### 8.2 设置环境变量

```bash
# 编辑服务文件，添加环境变量
sudo vim /etc/systemd/system/kylin-finance.service

# 在 [Service] 部分添加：
Environment="DB_PASSWORD=your_actual_password"
```

## 🔒 安全配置

### 1. 配置防火墙

**通过宝塔面板：**
1. 进入"安全" → "防火墙"
2. 开放端口：
   - 80（HTTP）
   - 443（HTTPS）
   - 22（SSH，建议限制 IP）
   - 8080（后端 API，仅内网，不对外开放）

**命令行方式：**
```bash
# CentOS/Alibaba Cloud Linux
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Ubuntu
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 2. 修改宝塔面板端口

```bash
# 修改宝塔面板端口（默认 8888）
bt default

# 或手动修改
bt 14
```

### 3. 配置 SSH 安全

```bash
# 编辑 SSH 配置
sudo vim /etc/ssh/sshd_config

# 修改以下配置：
# PermitRootLogin no
# PasswordAuthentication no  # 使用密钥认证
# PubkeyAuthentication yes

# 重启 SSH
sudo systemctl restart sshd
```

## 📊 监控和维护

### 1. 查看应用日志

```bash
# Systemd 日志
sudo journalctl -u kylin-finance -f

# 应用日志文件（如果配置了文件日志）
tail -f /www/wwwlogs/kylin-finance/app.log
```

### 2. 查看 Nginx 日志

**通过宝塔面板：**
- 进入"网站" → 选择网站 → "日志"

**命令行方式：**
```bash
# 访问日志
tail -f /www/wwwlogs/your-domain.com.log

# 错误日志
tail -f /www/wwwlogs/your-domain.com.error.log
```

### 3. 数据库备份

**通过宝塔面板：**
1. 进入"数据库" → 选择数据库 → "备份"
2. 设置自动备份计划

**命令行方式：**
```bash
# 创建备份脚本
vim /www/server/scripts/backup-db.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/www/backup/kylin-finance"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

mysqldump -u kylin_app -p'your_password' kylin_finance | gzip > $BACKUP_DIR/kylin_finance_$DATE.sql.gz

# 删除 30 天前的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
```

设置定时任务：
```bash
# 编辑 crontab
crontab -e

# 添加每天凌晨 2 点备份
0 2 * * * /www/server/scripts/backup-db.sh
```

## 🎯 常见问题

### Q1: 宝塔面板无法访问

**检查：**
1. 防火墙是否开放 8888 端口
2. 宝塔面板服务是否运行：`bt status`
3. 查看面板日志：`bt logs`

### Q2: Nginx 502 错误

**检查：**
1. 后端服务是否运行：`sudo systemctl status kylin-finance`
2. 端口是否正确：`netstat -tuln | grep 8080`
3. 查看 Nginx 错误日志

### Q3: 数据库连接失败

**检查：**
1. MySQL 服务状态：`sudo systemctl status mysql`
2. 数据库用户权限
3. 防火墙是否阻止连接

### Q4: 内存不足

**对于 2GB 内存服务器：**
1. 优化 JVM 参数：`-Xms512m -Xmx1536m`
2. 关闭不必要的服务
3. 优化 MySQL 配置
4. 考虑升级服务器配置

## 📝 资源优化建议

### 2GB 内存服务器优化

```bash
# JVM 参数
-Xms512m -Xmx1536m -XX:+UseG1GC

# MySQL 配置（/etc/my.cnf）
[mysqld]
innodb_buffer_pool_size=512M
max_connections=50
```

### 宝塔面板优化

1. 关闭不必要的软件
2. 定期清理日志文件
3. 使用宝塔面板的"计划任务"进行自动维护

---

**提示：** 更多详细信息请参考 [部署操作手册](DEPLOYMENT_MANUAL.md)

