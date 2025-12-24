#!/bin/bash

echo "=========================================="
echo "麒麟财务管理系统启动脚本 (Linux/Mac)"
echo "=========================================="
echo

echo "[1/4] 检查环境..."
java -version >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "错误: 未检测到Java环境，请先安装JDK 17+"
    exit 1
fi

node --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "错误: 未检测到Node.js环境，请先安装Node.js 18+"
    exit 1
fi

echo "环境检查通过"
echo

echo "[2/4] 检查数据库..."
mysql --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "警告: 未检测到MySQL客户端，请确保MySQL服务已启动"
    echo "数据库文件位置: database/schema/init.sql"
else
    echo "MySQL客户端检测通过"
fi
echo

echo "[3/4] 启动后端服务..."
echo "正在编译后端项目..."
mvn clean compile -q
if [ $? -ne 0 ]; then
    echo "错误: 后端编译失败"
    exit 1
fi

echo "正在启动后端服务..."
mvn spring-boot:run &
BACKEND_PID=$!
echo "后端服务PID: $BACKEND_PID"

echo "等待后端服务启动..."
sleep 10
echo

echo "[4/4] 启动前端服务..."
cd frontend/kylin-finance-ui
if [ ! -d "node_modules" ]; then
    echo "正在安装前端依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo "错误: 前端依赖安装失败"
        exit 1
    fi
fi

echo "正在启动前端开发服务器..."
npm run dev &
FRONTEND_PID=$!
echo "前端服务PID: $FRONTEND_PID"
cd ../..

echo
echo "=========================================="
echo "启动完成!"
echo "=========================================="
echo
echo "访问地址:"
echo "  前端界面: http://localhost:5173"
echo "  后端API:   http://localhost:8080"
echo
echo "数据库初始化:"
echo "  请手动执行: mysql -u root -p kylin_finance < database/schema/init.sql"
echo
echo "按 Ctrl+C 停止所有服务"
echo

# 等待用户中断
trap "echo '正在停止服务...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT
wait
