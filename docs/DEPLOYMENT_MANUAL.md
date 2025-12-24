# 麒麟财务管理系统 - 阿里云 ECS 部署操作手册

## 目录
1. [准备工作](#一准备工作)
2. [服务器初始化](#二服务器初始化)
3. [环境安装](#三环境安装)
4. [数据库部署](#四数据库部署)
5. [应用部署](#五应用部署)
6. [Nginx 配置](#六nginx-配置)
7. [SSL 证书配置](#七ssl-证书配置)
8. [服务启动与验证](#八服务启动与验证)
9. [日常维护](#九日常维护)

---

## 一、准备工作

### 1.1 服务器信息确认

- **ECS 实例规格**: 2核2GB（最低配置）或 4核8GB（推荐生产环境）
- **操作系统**: Linux（CentOS 7/8、Ubuntu 20.04+、Alibaba Cloud Linux 2/3）
- **公网 IP**: `8.145.48.161`（示例，请替换为您的实际 IP）
- **私网 IP**: `172.20.30.136`（示例，请替换为您的实际 IP）
- **域名**: `your-domain.com`（可选，建议配置）
- **管理面板**: 宝塔 Linux 面板（如已安装）

**注意：** 如果您的服务器已安装宝塔面板，强烈建议使用 [宝塔面板部署指南](BT_PANEL_GUIDE.md)，可以大大简化部署流程。

### 1.2 本地准备

- **SSH 客户端**: Linux/Mac 内置终端，或 Windows 使用 PuTTY/WinSCP/MobaXterm
- **项目代码**: 已打包或 Git 仓库地址
- **文件传输工具**: `scp`、`rsync` 或 SFTP 客户端

---

## 二、服务器初始化

### 2.1 连接服务器

```bash
# 使用 SSH 连接（Linux/Mac 终端）
ssh root@8.145.48.161

# 或使用密钥文件
ssh -i /path/to/your-key.pem root@8.145.48.161

# 如果使用非 root 用户
ssh username@8.145.48.161

# 如果服务器使用宝塔面板，也可以通过面板的终端功能连接
# 访问：http://your-server-ip:8888（宝塔面板默认端口）
```

**注意：** 如果服务器安装了宝塔面板，也可以通过宝塔面板的"终端"功能进行操作。

### 2.2 更新系统

#### CentOS/Rocky Linux
```bash
# 更新系统
sudo yum update -y

# 安装基础工具
sudo yum install -y wget curl git vim net-tools
```

#### Ubuntu
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y wget curl git vim net-tools
```

### 2.3 创建应用用户

```bash
# 创建专用用户（非 root）
sudo useradd -m -s /bin/bash kylin-app
sudo passwd kylin-app  # 设置密码

# 添加到 sudo 组（可选）
sudo usermod -aG wheel kylin-app  # CentOS
sudo usermod -aG sudo kylin-app   # Ubuntu

# 切换到应用用户
su - kylin-app
```

### 2.4 创建目录结构

```bash
# 创建应用目录
sudo mkdir -p /opt/kylin-finance
sudo mkdir -p /opt/backup/kylin-finance
sudo mkdir -p /var/log/kylin-finance
sudo mkdir -p /etc/nginx/ssl

# 设置权限
sudo chown -R kylin-app:kylin-app /opt/kylin-finance
sudo chown -R kylin-app:kylin-app /var/log/kylin-finance
sudo chmod 755 /opt/kylin-finance
```

---

## 三、环境安装

### 3.1 安装 JDK 17

#### CentOS/Rocky Linux
```bash
# 安装 OpenJDK 17
sudo yum install -y java-17-openjdk java-17-openjdk-devel

# 验证安装
java -version
# 应显示：openjdk version "17.0.x"

# 设置 JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

#### Ubuntu
```bash
# 安装 OpenJDK 17
sudo apt install -y openjdk-17-jdk

# 验证安装
java -version

# 设置 JAVA_HOME
sudo update-alternatives --config java
# 选择 Java 17，然后设置环境变量
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### 3.2 安装 Maven

```bash
# 下载 Maven
cd /tmp
wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz

# 解压
sudo tar -xzf apache-maven-3.9.6-bin.tar.gz -C /opt

# 设置环境变量
echo 'export MAVEN_HOME=/opt/apache-maven-3.9.6' >> ~/.bashrc
echo 'export PATH=$MAVEN_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 验证安装
mvn -version
```

### 3.3 安装 Node.js 18

```bash
# 使用 NodeSource 仓库（推荐）
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -  # CentOS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -  # Ubuntu

# 安装 Node.js
sudo yum install -y nodejs  # CentOS
sudo apt install -y nodejs  # Ubuntu

# 验证安装
node -v  # 应显示：v18.x.x
npm -v   # 应显示：9.x.x
```

### 3.4 安装 MySQL 8.0

#### CentOS/Rocky Linux
```bash
# 下载 MySQL Yum 仓库
wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
sudo rpm -ivh mysql80-community-release-el7-3.noarch.rpm

# 安装 MySQL
sudo yum install -y mysql-server

# 启动 MySQL
sudo systemctl start mysqld
sudo systemctl enable mysqld

# 获取临时密码
sudo grep 'temporary password' /var/log/mysqld.log
```

#### Ubuntu
```bash
# 安装 MySQL
sudo apt install -y mysql-server

# 启动 MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# 运行安全配置
sudo mysql_secure_installation
```

### 3.5 配置 MySQL

```bash
# 登录 MySQL（使用临时密码或 root）
sudo mysql -u root -p

# 在 MySQL 中执行
CREATE DATABASE kylin_finance DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 创建应用用户
CREATE USER 'kylin_app'@'localhost' IDENTIFIED BY 'your_strong_password_here';
GRANT ALL PRIVILEGES ON kylin_finance.* TO 'kylin_app'@'localhost';
FLUSH PRIVILEGES;

# 导入初始化脚本
USE kylin_finance;
SOURCE /path/to/database/schema/init.sql;

# 退出
EXIT;
```

### 3.6 安装 Nginx

#### CentOS/Rocky Linux
```bash
# 安装 EPEL 仓库
sudo yum install -y epel-release

# 安装 Nginx
sudo yum install -y nginx

# 启动并设置开机自启
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### Ubuntu
```bash
# 安装 Nginx
sudo apt install -y nginx

# 启动并设置开机自启
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

## 四、数据库部署

### 4.1 数据库脚本目录结构

项目数据库脚本已重新组织，目录结构如下：

```
database/
├── schema/                    # 数据库表结构脚本
│   ├── init.sql              # 主初始化脚本（核心财务表，必需）
│   ├── rbac_tables.sql       # RBAC权限管理表（可选）
│   ├── biz_expense_claim.sql # 费用报销业务表（可选）
│   └── biz_receipt_payment.sql # 收付款业务表（可选）
├── scripts/                  # 数据库维护脚本
│   ├── fix_password_field.sql
│   └── test_idempotent.sql
└── seeds/                     # 测试数据和种子数据（仅开发/测试环境）
    ├── mock_data.sql
    ├── voucher_mock_data.sql
    └── ...
```

### 4.2 初始化数据库

**步骤一：导入主初始化脚本（必需）**

```bash
# 上传数据库初始化脚本
# 方式1: 使用 scp（从本地）
scp database/schema/init.sql kylin-app@your-server-ip:/tmp/

# 方式2: 直接在服务器上下载（如果代码在 Git）
cd /tmp
git clone your-git-repo-url
cd kylin-finance

# 导入主初始化脚本（包含核心财务表）
mysql -u kylin_app -p kylin_finance < database/schema/init.sql
```

**步骤二：导入可选模块（根据需要）**

```bash
# 如果需要权限管理功能，导入RBAC表
mysql -u kylin_app -p kylin_finance < database/schema/rbac_tables.sql

# 如果需要费用报销功能，导入费用报销表
mysql -u kylin_app -p kylin_finance < database/schema/biz_expense_claim.sql

# 如果需要收付款功能，导入收付款表
mysql -u kylin_app -p kylin_finance < database/schema/biz_receipt_payment.sql
```

**步骤三：导入测试数据（仅开发/测试环境）**

```bash
# 如果需要测试数据，导入种子数据
mysql -u kylin_app -p kylin_finance < database/seeds/mock_data.sql
```

**注意：**
- Docker 部署时，`docker-compose.yml` 已配置自动导入 `database/schema/init.sql`
- 生产环境建议只导入必需的核心表，避免导入测试数据

### 4.2 配置 MySQL 远程访问（可选，仅内网）

```bash
# 编辑 MySQL 配置
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf  # Ubuntu
sudo vim /etc/my.cnf  # CentOS

# 修改 bind-address（如果需要内网访问）
# bind-address = 0.0.0.0

# 重启 MySQL
sudo systemctl restart mysql  # Ubuntu
sudo systemctl restart mysqld  # CentOS
```

---

## 五、应用部署

### 5.1 方式一：使用部署脚本（推荐）

```bash
# 1. 上传项目代码到服务器
cd /opt/kylin-finance
git clone your-git-repo-url .  # 如果使用 Git
# 或使用 scp 上传整个项目目录

# 2. 修改部署脚本配置
vim deploy.sh
# 修改以下变量：
# - PROJECT_DIR
# - GIT_REPO_URL（如果使用）
# - JAVA_HOME
# - DB_HOST, DB_USER 等

# 3. 赋予执行权限
chmod +x deploy.sh

# 4. 执行部署
./deploy.sh deploy
```

### 5.2 方式二：手动部署

```bash
# 1. 上传代码
cd /opt/kylin-finance
# 上传项目代码...

# 2. 编译后端
mvn clean package -DskipTests

# 3. 编译前端
cd frontend/kylin-finance-ui
npm install
npm run build

# 4. 部署前端静态资源
sudo cp -r dist/* /usr/share/nginx/html/kylin-finance/

# 5. 创建生产环境配置文件
vim application/src/main/resources/application-prod.yml
# 配置数据库连接等信息

# 6. 启动应用
cd /opt/kylin-finance
java -Xms2g -Xmx4g -jar application/target/kylin-finance-1.0.0.jar \
  --spring.profiles.active=prod
```

### 5.3 方式三：使用 Docker（推荐生产环境）

```bash
# 1. 安装 Docker
curl -fsSL https://get.docker.com | sudo sh
sudo systemctl start docker
sudo systemctl enable docker

# 2. 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. 配置环境变量
vim .env
# 设置：
# MYSQL_ROOT_PASSWORD=your_strong_password
# MYSQL_PASSWORD=your_app_password
# DB_PASSWORD=your_app_password

# 4. 构建并启动
docker-compose up -d --build

# 5. 查看日志
docker-compose logs -f
```

### 5.4 配置 Systemd 服务（非 Docker 方式）

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
WorkingDirectory=/opt/kylin-finance
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
Environment="DB_PASSWORD=your_password_here"
# JVM 参数说明：
# -Xms512m -Xmx1536m 适用于 2GB 内存服务器（预留系统和其他服务内存）
# -Xms2g -Xmx4g 适用于 4GB+ 内存服务器（推荐生产环境）
ExecStart=/usr/bin/java -Xms512m -Xmx1536m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -jar /opt/kylin-finance/application/target/kylin-finance-1.0.0.jar --spring.profiles.active=prod
ExecStop=/bin/kill -15 $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=kylin-finance

[Install]
WantedBy=multi-user.target
```

启动服务：
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

---

## 六、Nginx 配置

### 6.1 方式一：手动配置（标准安装）

```bash
# 备份默认配置
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

# 复制项目 Nginx 配置
sudo cp /opt/kylin-finance/nginx/nginx.conf /etc/nginx/nginx.conf

# 或使用项目配置作为站点配置（推荐）
sudo cp /opt/kylin-finance/nginx/nginx.conf /etc/nginx/conf.d/kylin-finance.conf
```

### 6.2 方式二：使用宝塔面板配置（如果使用宝塔）

1. **登录宝塔面板**：`http://your-server-ip:8888`

2. **创建网站**：
   - 点击"网站" → "添加站点"
   - 域名：填写您的域名或 IP
   - 根目录：`/www/wwwroot/kylin-finance`（或自定义）
   - PHP 版本：选择"纯静态"（前端静态资源）

3. **配置反向代理**：
   - 进入网站设置 → "反向代理"
   - 添加反向代理：
     - 代理名称：`kylin-finance-api`
     - 目标URL：`http://127.0.0.1:8080`
     - 发送域名：`$host`
     - 代理目录：`/api/`

4. **配置 SSL 证书**（如需要）：
   - 进入网站设置 → "SSL"
   - 选择"Let's Encrypt"免费证书或上传自有证书

5. **修改配置文件**（高级用户）：
   - 进入网站设置 → "配置文件"
   - 参考项目中的 `nginx/nginx.conf` 进行配置

### 6.3 修改配置

**手动编辑配置文件：**
```bash
sudo vim /etc/nginx/nginx.conf
# 或
sudo vim /etc/nginx/conf.d/kylin-finance.conf

# 宝塔面板配置文件位置（如果使用宝塔）
sudo vim /www/server/panel/vhost/nginx/your-domain.com.conf
```

**重要修改项**：
1. 修改 `server_name` 为您的域名或 IP
2. 确认 SSL 证书路径（宝塔面板通常自动配置）
3. 确认后端代理地址：
   - Docker 部署：`http://backend:8080`
   - 传统部署：`http://127.0.0.1:8080`
4. 确认静态资源路径：
   - 标准安装：`/usr/share/nginx/html/kylin-finance`
   - 宝塔面板：`/www/wwwroot/kylin-finance`

### 6.4 测试并重载配置

**标准安装方式：**
```bash
# 测试配置
sudo nginx -t

# 如果测试通过，重载配置
sudo systemctl reload nginx

# 查看状态
sudo systemctl status nginx
```

**宝塔面板方式：**
- 在宝塔面板中点击"重载配置"或"重启 Nginx"
- 或在终端执行：
```bash
# 测试配置
sudo /www/server/nginx/sbin/nginx -t

# 重载配置
sudo /etc/init.d/nginx reload
# 或
sudo systemctl reload nginx
```

---

## 七、SSL 证书配置

### 7.1 使用 Let's Encrypt（免费）

```bash
# 安装 certbot
sudo yum install certbot python3-certbot-nginx -y  # CentOS
sudo apt install certbot python3-certbot-nginx -y   # Ubuntu

# 申请证书（需要域名已解析到服务器IP）
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 测试自动续期
sudo certbot renew --dry-run

# 设置自动续期（certbot 会自动配置 cron）
```

### 7.2 使用阿里云 SSL 证书

```bash
# 1. 在阿里云控制台申请 SSL 证书
# 2. 下载证书文件（Nginx 格式）
# 3. 上传到服务器
sudo mkdir -p /etc/nginx/ssl
sudo scp cert.pem key.pem root@your-server-ip:/etc/nginx/ssl/

# 4. 设置权限
sudo chmod 600 /etc/nginx/ssl/*
sudo chown root:root /etc/nginx/ssl/*

# 5. 在 Nginx 配置中指定证书路径
# ssl_certificate /etc/nginx/ssl/cert.pem;
# ssl_certificate_key /etc/nginx/ssl/key.pem;
```

---

## 八、服务启动与验证

### 8.1 启动所有服务

```bash
# 1. 启动 MySQL
sudo systemctl start mysqld  # CentOS
sudo systemctl start mysql   # Ubuntu

# 2. 启动后端应用
sudo systemctl start kylin-finance
# 或使用 Docker: docker-compose up -d

# 3. 启动 Nginx
sudo systemctl start nginx

# 4. 检查所有服务状态
sudo systemctl status mysqld
sudo systemctl status kylin-finance
sudo systemctl status nginx
```

### 8.2 验证部署

```bash
# 1. 检查后端 API
curl http://localhost:8080/actuator/health

# 2. 检查前端页面
curl http://localhost

# 3. 检查数据库连接
mysql -u kylin_app -p -e "USE kylin_finance; SHOW TABLES;"

# 4. 检查端口监听
sudo netstat -tuln | grep -E '80|443|8080|3306'
```

### 8.3 浏览器访问测试

1. 打开浏览器访问：`http://your-server-ip` 或 `https://your-domain.com`
2. 检查前端页面是否正常加载
3. 尝试登录功能
4. 检查 API 请求是否正常

---

## 九、日常维护

### 9.1 日志查看

```bash
# 应用日志
tail -f /var/log/kylin-finance/app.log
# 或
sudo journalctl -u kylin-finance -f

# Nginx 日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# MySQL 日志
sudo tail -f /var/log/mysqld.log  # CentOS
sudo tail -f /var/log/mysql/error.log  # Ubuntu
```

### 9.2 备份数据库

```bash
# 创建备份脚本
vim /opt/scripts/backup-db.sh
```

备份脚本内容：
```bash
#!/bin/bash
BACKUP_DIR="/opt/backup/kylin-finance/db"
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
0 2 * * * /opt/scripts/backup-db.sh
```

### 9.3 更新部署

```bash
# 使用部署脚本更新
cd /opt/kylin-finance
./deploy.sh deploy

# 或手动更新
git pull  # 拉取最新代码
mvn clean package -DskipTests  # 重新编译
sudo systemctl restart kylin-finance  # 重启服务
```

### 9.4 监控和告警

```bash
# 安装监控工具（可选）
# 1. 使用阿里云云监控
# 2. 安装 Prometheus + Grafana
# 3. 配置日志收集（ELK Stack）
```

### 9.5 性能优化

```bash
# 1. 调整 JVM 参数（根据服务器配置）
# 编辑 systemd 服务文件或启动脚本

# 2. 优化 MySQL 配置
sudo vim /etc/my.cnf
# 调整 innodb_buffer_pool_size 等参数

# 3. 优化 Nginx 配置
# 调整 worker_processes, worker_connections 等
```

---

## 十、故障排查

### 10.1 应用无法启动

```bash
# 检查日志
sudo journalctl -u kylin-finance -n 100

# 检查端口占用
sudo netstat -tuln | grep 8080

# 检查 Java 进程
ps aux | grep java

# 检查配置文件
cat /opt/kylin-finance/application/src/main/resources/application-prod.yml
```

### 10.2 数据库连接失败

```bash
# 检查 MySQL 服务
sudo systemctl status mysql

# 测试数据库连接
mysql -u kylin_app -p -h localhost kylin_finance

# 检查防火墙
sudo firewall-cmd --list-all  # CentOS
sudo ufw status  # Ubuntu
```

### 10.3 Nginx 502 错误

```bash
# 检查后端服务是否运行
curl http://localhost:8080/actuator/health

# 检查 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# 检查 Nginx 配置
sudo nginx -t
```

---

## 十一、安全加固检查清单

- [ ] 修改默认数据库密码
- [ ] 配置防火墙规则
- [ ] 设置 SSH 密钥认证
- [ ] 配置 SSL 证书
- [ ] 设置应用运行用户（非 root）
- [ ] 配置日志轮转
- [ ] 设置数据库备份
- [ ] 配置安全组规则
- [ ] 启用 fail2ban
- [ ] 定期更新系统补丁

---

## 十二、常用命令速查

```bash
# 服务管理
sudo systemctl start/stop/restart/status kylin-finance
sudo systemctl start/stop/restart/status nginx
sudo systemctl start/stop/restart/status mysql

# 日志查看
sudo journalctl -u kylin-finance -f
sudo tail -f /var/log/nginx/access.log

# 进程管理
ps aux | grep java
kill -9 <PID>

# 端口检查
sudo netstat -tuln | grep 8080
sudo ss -tuln | grep 8080

# 磁盘空间
df -h
du -sh /opt/kylin-finance/*

# 内存使用
free -h
top
```

---

**部署完成后，请务必：**
1. 修改所有默认密码
2. 配置 SSL 证书
3. 设置防火墙规则
4. 配置自动备份
5. 设置监控告警

如有问题，请参考：
- [环境分析文档](DEPLOYMENT_ENVIRONMENT.md)
- [安全加固指南](SECURITY_HARDENING.md)


