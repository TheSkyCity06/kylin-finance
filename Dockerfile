# ==========================================
# 麒麟财务管理系统 - Dockerfile
# ==========================================
# 多阶段构建：构建阶段 + 运行阶段
# ==========================================

# ==========================================
# 阶段 1: 后端构建
# ==========================================
FROM maven:3.9-eclipse-temurin-17 AS backend-builder

WORKDIR /build

# 复制 pom.xml 文件（利用 Docker 缓存）
COPY pom.xml .
COPY common/pom.xml ./common/
COPY admin/pom.xml ./admin/
COPY finance/pom.xml ./finance/
COPY application/pom.xml ./application/

# 下载依赖（利用 Docker 缓存）
RUN mvn dependency:go-offline -B

# 复制源代码
COPY . .

# 构建应用
RUN mvn clean package -DskipTests -B

# ==========================================
# 阶段 2: 前端构建
# ==========================================
FROM node:18-alpine AS frontend-builder

WORKDIR /build

# 复制前端 package.json
COPY frontend/kylin-finance-ui/package*.json ./frontend/kylin-finance-ui/

# 安装依赖
WORKDIR /build/frontend/kylin-finance-ui
RUN npm ci --only=production

# 复制前端源代码
COPY frontend/kylin-finance-ui/ .

# 构建前端
RUN npm run build

# ==========================================
# 阶段 3: 运行阶段
# ==========================================
FROM eclipse-temurin:17-jre-alpine

# 设置维护者信息
LABEL maintainer="kylin-finance-team"
LABEL description="麒麟财务管理系统"

# 安装必要的工具
RUN apk add --no-cache \
    curl \
    tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

# 创建应用用户（非 root 用户运行）
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 设置工作目录
WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=backend-builder /build/application/target/kylin-finance-1.0.0.jar app.jar

# 从构建阶段复制前端静态资源
COPY --from=frontend-builder /build/frontend/kylin-finance-ui/dist ./static

# 创建日志目录
RUN mkdir -p /app/logs && chown -R appuser:appgroup /app

# 切换到非 root 用户
USER appuser

# 暴露端口
EXPOSE 8080

# JVM 参数
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Dfile.encoding=UTF-8"

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar --spring.profiles.active=prod"]


