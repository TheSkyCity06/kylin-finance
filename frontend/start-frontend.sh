#!/bin/bash

echo "=========================================="
echo "麒麟财务管理系统前端启动脚本"
echo "=========================================="

cd kylin-finance-ui

echo "正在安装依赖..."
npm install

if [ $? -ne 0 ]; then
    echo "依赖安装失败，请检查网络连接"
    exit 1
fi

echo "正在启动开发服务器..."
npm run dev
