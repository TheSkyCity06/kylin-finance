#!/bin/bash

# ==========================================
# 麒麟财务管理系统 - 自动化部署脚本
# ==========================================
# 用途：自动化执行代码拉取、编译打包、服务重启等操作
# 作者：DevOps Team
# 日期：2024-12-20
# ==========================================

set -e  # 遇到错误立即退出

# ==========================================
# 配置区域（请根据实际情况修改）
# ==========================================

# 项目配置
PROJECT_NAME="kylin-finance"
PROJECT_DIR="/opt/${PROJECT_NAME}"
BACKUP_DIR="/opt/backup/${PROJECT_NAME}"
LOG_DIR="/var/log/${PROJECT_NAME}"

# Git 配置
GIT_REPO_URL=""  # 如果为空，则从当前目录部署
GIT_BRANCH="main"  # 或 master

# 应用配置
APP_NAME="kylin-finance"
APP_JAR="${PROJECT_DIR}/application/target/${APP_NAME}-1.0.0.jar"
APP_PORT=8080
APP_PID_FILE="/var/run/${APP_NAME}.pid"

# Java 配置
JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
# JVM 参数说明：
# 2GB 内存服务器：-Xms512m -Xmx1536m（预留系统和其他服务内存）
# 4GB+ 内存服务器：-Xms2g -Xmx4g（推荐生产环境）
JVM_OPTS="-Xms512m -Xmx1536m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Dfile.encoding=UTF-8"

# 前端配置
FRONTEND_DIR="${PROJECT_DIR}/frontend/kylin-finance-ui"
FRONTEND_DIST="${FRONTEND_DIR}/dist"
NGINX_WEB_ROOT="/usr/share/nginx/html/${PROJECT_NAME}"

# 数据库配置（用于初始化检查）
DB_HOST="localhost"
DB_PORT=3306
DB_NAME="kylin_finance"
DB_USER="root"

# 通知配置（可选）
NOTIFY_EMAIL=""  # 部署通知邮箱
WEBHOOK_URL=""   # 企业微信/钉钉 Webhook

# ==========================================
# 颜色输出函数
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==========================================
# 工具函数
# ==========================================

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 未安装，请先安装"
        exit 1
    fi
}

# 创建目录
create_dirs() {
    log_info "创建必要的目录..."
    mkdir -p ${BACKUP_DIR}
    mkdir -p ${LOG_DIR}
    mkdir -p ${NGINX_WEB_ROOT}
    mkdir -p $(dirname ${APP_PID_FILE})
}

# 检查 Java 进程是否运行
is_app_running() {
    if [ -f "${APP_PID_FILE}" ]; then
        PID=$(cat ${APP_PID_FILE})
        if ps -p ${PID} > /dev/null 2>&1; then
            return 0
        else
            rm -f ${APP_PID_FILE}
            return 1
        fi
    fi
    return 1
}

# 停止应用
stop_app() {
    log_info "停止应用服务..."
    if is_app_running; then
        PID=$(cat ${APP_PID_FILE})
        log_info "正在停止进程 PID: ${PID}"
        kill ${PID} || true
        
        # 等待进程结束，最多等待 30 秒
        for i in {1..30}; do
            if ! ps -p ${PID} > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        
        # 如果还在运行，强制杀死
        if ps -p ${PID} > /dev/null 2>&1; then
            log_warn "进程未正常退出，强制终止..."
            kill -9 ${PID} || true
        fi
        
        rm -f ${APP_PID_FILE}
        log_info "应用已停止"
    else
        log_info "应用未运行，跳过停止步骤"
    fi
}

# 启动应用
start_app() {
    log_info "启动应用服务..."
    
    if [ ! -f "${APP_JAR}" ]; then
        log_error "应用 JAR 文件不存在: ${APP_JAR}"
        exit 1
    fi
    
    # 检查端口是否被占用
    if netstat -tuln | grep -q ":${APP_PORT} "; then
        log_error "端口 ${APP_PORT} 已被占用"
        exit 1
    fi
    
    # 启动应用
    cd ${PROJECT_DIR}
    nohup ${JAVA_HOME}/bin/java ${JVM_OPTS} \
        -jar ${APP_JAR} \
        --spring.profiles.active=prod \
        > ${LOG_DIR}/app.log 2>&1 &
    
    APP_PID=$!
    echo ${APP_PID} > ${APP_PID_FILE}
    
    log_info "应用启动中，PID: ${APP_PID}"
    
    # 等待应用启动
    log_info "等待应用启动..."
    for i in {1..60}; do
        if curl -s http://localhost:${APP_PORT}/actuator/health > /dev/null 2>&1; then
            log_info "应用启动成功！"
            return 0
        fi
        sleep 1
    done
    
    log_error "应用启动超时，请检查日志: ${LOG_DIR}/app.log"
    exit 1
}

# 备份旧版本
backup_old_version() {
    if [ -f "${APP_JAR}" ]; then
        log_info "备份旧版本..."
        BACKUP_FILE="${BACKUP_DIR}/${APP_NAME}-$(date +%Y%m%d_%H%M%S).jar"
        cp ${APP_JAR} ${BACKUP_FILE}
        log_info "备份完成: ${BACKUP_FILE}"
        
        # 只保留最近 5 个备份
        ls -t ${BACKUP_DIR}/${APP_NAME}-*.jar | tail -n +6 | xargs rm -f 2>/dev/null || true
    fi
}

# 拉取代码
pull_code() {
    if [ -n "${GIT_REPO_URL}" ]; then
        log_info "从 Git 仓库拉取代码..."
        if [ ! -d "${PROJECT_DIR}/.git" ]; then
            log_info "首次克隆仓库..."
            git clone -b ${GIT_BRANCH} ${GIT_REPO_URL} ${PROJECT_DIR}
        else
            cd ${PROJECT_DIR}
            git fetch origin
            git reset --hard origin/${GIT_BRANCH}
            git clean -fd
        fi
    else
        log_info "使用当前目录代码（未配置 Git 仓库）"
    fi
}

# 编译后端
build_backend() {
    log_info "编译后端项目..."
    cd ${PROJECT_DIR}
    
    # 检查 Maven
    check_command mvn
    
    # 清理并编译
    mvn clean package -DskipTests
    
    if [ ! -f "${APP_JAR}" ]; then
        log_error "后端编译失败，JAR 文件不存在"
        exit 1
    fi
    
    log_info "后端编译完成: ${APP_JAR}"
}

# 编译前端
build_frontend() {
    log_info "编译前端项目..."
    cd ${FRONTEND_DIR}
    
    # 检查 Node.js
    check_command node
    check_command npm
    
    # 安装依赖（如果需要）
    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        npm install
    fi
    
    # 构建前端
    npm run build
    
    if [ ! -d "${FRONTEND_DIST}" ]; then
        log_error "前端编译失败，dist 目录不存在"
        exit 1
    fi
    
    log_info "前端编译完成"
}

# 部署前端
deploy_frontend() {
    log_info "部署前端静态资源..."
    rm -rf ${NGINX_WEB_ROOT}/*
    cp -r ${FRONTEND_DIST}/* ${NGINX_WEB_ROOT}/
    log_info "前端部署完成: ${NGINX_WEB_ROOT}"
}

# 检查数据库连接
check_database() {
    log_info "检查数据库连接..."
    if command -v mysql &> /dev/null; then
        if mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -e "USE ${DB_NAME};" 2>/dev/null; then
            log_info "数据库连接正常"
        else
            log_warn "数据库连接失败，请检查配置"
        fi
    else
        log_warn "未安装 mysql 客户端，跳过数据库检查"
    fi
}

# 重启 Nginx
reload_nginx() {
    log_info "重新加载 Nginx 配置..."
    if command -v nginx &> /dev/null; then
        nginx -t && systemctl reload nginx
        log_info "Nginx 重新加载完成"
    else
        log_warn "Nginx 未安装，跳过重新加载"
    fi
}

# 发送通知（可选）
send_notification() {
    local status=$1
    local message=$2
    
    if [ -n "${WEBHOOK_URL}" ]; then
        curl -X POST ${WEBHOOK_URL} \
            -H 'Content-Type: application/json' \
            -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"${PROJECT_NAME} 部署${status}: ${message}\"}}" \
            > /dev/null 2>&1 || true
    fi
}

# ==========================================
# 主函数
# ==========================================

main() {
    log_info "=========================================="
    log_info "开始部署 ${PROJECT_NAME}"
    log_info "=========================================="
    
    # 检查必要的命令
    check_command java
    check_command mvn
    
    # 创建目录
    create_dirs
    
    # 拉取代码
    pull_code
    
    # 备份旧版本
    backup_old_version
    
    # 停止旧服务
    stop_app
    
    # 编译后端
    build_backend
    
    # 编译前端
    build_frontend
    
    # 部署前端
    deploy_frontend
    
    # 启动新服务
    start_app
    
    # 检查数据库
    check_database
    
    # 重新加载 Nginx
    reload_nginx
    
    log_info "=========================================="
    log_info "部署完成！"
    log_info "应用访问地址: http://localhost:${APP_PORT}"
    log_info "前端访问地址: http://localhost"
    log_info "=========================================="
    
    # 发送通知
    send_notification "成功" "部署完成"
}

# ==========================================
# 脚本入口
# ==========================================

case "${1:-deploy}" in
    deploy)
        main
        ;;
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        stop_app
        sleep 2
        start_app
        ;;
    status)
        if is_app_running; then
            PID=$(cat ${APP_PID_FILE})
            log_info "应用正在运行，PID: ${PID}"
            ps aux | grep ${PID} | grep -v grep
        else
            log_info "应用未运行"
        fi
        ;;
    logs)
        tail -f ${LOG_DIR}/app.log
        ;;
    *)
        echo "用法: $0 {deploy|start|stop|restart|status|logs}"
        echo ""
        echo "命令说明:"
        echo "  deploy  - 完整部署（拉取代码、编译、重启服务）"
        echo "  start   - 启动应用"
        echo "  stop    - 停止应用"
        echo "  restart - 重启应用"
        echo "  status  - 查看应用状态"
        echo "  logs    - 查看应用日志"
        exit 1
        ;;
esac


