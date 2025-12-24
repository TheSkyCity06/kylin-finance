@echo off
chcp 65001 >nul
echo ==========================================
echo 麒麟财务管理系统启动脚本 (Windows)
echo ==========================================
echo.

echo [1/4] 检查环境...
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未检测到Java环境，请先安装JDK 17+
    pause
    exit /b 1
)

node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未检测到Node.js环境，请先安装Node.js 18+
    pause
    exit /b 1
)

echo 环境检查通过
echo.

echo [2/4] 检查数据库...
mysql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 警告: 未检测到MySQL客户端，请确保MySQL服务已启动
    echo 数据库文件位置: database\schema\init.sql
) else (
    echo MySQL客户端检测通过
)
echo.

echo [3/4] 启动后端服务...
echo 正在编译后端项目...
call mvn clean compile -q
if %errorlevel% neq 0 (
    echo 错误: 后端编译失败
    pause
    exit /b 1
)

echo 正在启动后端服务...
start "KylinFinance-Backend" cmd /k "mvn spring-boot:run"
timeout /t 10 /nobreak >nul
echo.

echo [4/4] 启动前端服务...
cd frontend\kylin-finance-ui
if not exist node_modules (
    echo 正在安装前端依赖...
    call npm install
    if %errorlevel% neq 0 (
        echo 错误: 前端依赖安装失败
        pause
        exit /b 1
    )
)

echo 正在启动前端开发服务器...
start "KylinFinance-Frontend" cmd /k "npm run dev"
cd ..\..

echo.
echo ==========================================
echo 启动完成!
echo ==========================================
echo.
echo 访问地址:
echo   前端界面: http://localhost:5173
echo   后端API:   http://localhost:8080
echo.
echo 数据库初始化:
echo   请手动执行: mysql -u root -p kylin_finance ^< database\schema\init.sql
echo.
echo 按任意键关闭此窗口...
pause >nul
