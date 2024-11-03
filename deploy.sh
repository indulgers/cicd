#!/bin/bash

# 配置变量
SERVER_USER="root"
SERVER_IP="116.205.163.50"
SERVER_PATH="/var/www/html/"
GIT_REPO="git@github.com:indulgers/cicd.git"
NGINX_SERVICE="nginx"

# 部署流程
echo "开始部署 Vue 项目..."

# Step 1: 本地推送代码到 Git 仓库
echo "推送本地代码到 Git 仓库..."
git add .
git commit -m "deploy: 更新代码"
git push origin main

if [ $? -ne 0 ]; then
  echo "代码推送失败，请检查 Git 配置。"
  exit 1
fi

# Step 2: 拉取服务器最新代码
echo "连接到服务器并拉取最新代码..."
ssh "$SERVER_USER@$SERVER_IP" << EOF
  cd $SERVER_PATH || exit
  git pull origin main
  if [ $? -ne 0 ]; then
    echo "拉取代码失败，请检查服务器上的 Git 配置。"
    exit 1
  fi
EOF

# Step 3: 构建项目并重启 Nginx
echo "构建项目并重启 Nginx 服务..."
ssh "$SERVER_USER@$SERVER_IP" << EOF
  cd $SERVER_PATH || exit
  npm install
  npm run build
  sudo systemctl restart $NGINX_SERVICE
EOF

if [ $? -eq 0 ]; then
  echo "部署成功！Vue 项目已上线。"
else
  echo "部署失败，请检查服务器环境。"
fi
