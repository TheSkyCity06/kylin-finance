@echo off
echo ==========================================
echo 麒麟财务管理系统前端启动脚本
echo ==========================================

cd kylin-finance-ui

echo 正在安装依赖...
npm install

if %errorlevel% neq 0 (
    echo 依赖安装失败，请检查网络连接
    pause
    exit /b 1
)

echo 正在启动开发服务器...
npm run dev

pause
