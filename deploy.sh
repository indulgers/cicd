#!/bin/bash

# 配置变量
SERVER_USER="root"
SERVER_IP="116.205.163.50"
SERVER_PATH="/var/www/html/vue-app"
GIT_REPO="git@github.com:indulgers/cicd.git"
NGINX_SERVICE="nginx"
NODE_VERSION="18"

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

# Step 2: 连接服务器并检查环境
echo "连接到服务器并进行环境检查..."
ssh -tt "$SERVER_USER@$SERVER_IP" << EOF
  # Step 2.1: 添加 GitHub 到 known_hosts
  mkdir -p ~/.ssh
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts

  # Step 2.2: 检查项目路径是否存在
  if [ ! -d "$SERVER_PATH" ]; then
    echo "首次部署：创建项目目录并克隆代码仓库..."
    mkdir -p "$SERVER_PATH"
    git clone $GIT_REPO "$SERVER_PATH"
  else
    echo "项目目录已存在，拉取最新代码..."
    cd "$SERVER_PATH" || exit
    git pull origin main
  fi

  # Step 2.3: 检查是否安装了 Node.js 和 npm
  if ! command -v node &> /dev/null; then
    echo "Node.js 未安装，安装 NVM 和 Node.js $NODE_VERSION..."
    
    # 安装 NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    export NVM_DIR="\$HOME/.nvm"
    [ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # 加载 nvm

    # 安装指定版本的 Node.js
    nvm install $NODE_VERSION
    nvm use $NODE_VERSION
    nvm alias default $NODE_VERSION
  else
    echo "Node.js 已安装，跳过安装步骤。"
  fi

  # Step 2.4: 检查 Git 仓库是否存在 .git
  cd "$SERVER_PATH" || exit
  if [ ! -d ".git" ]; then
    echo "初始化 Git 仓库..."
    git init
    git remote add origin $GIT_REPO
  fi
  git pull origin main

  # Step 2.5: 安装项目依赖并构建项目
  echo "安装依赖并构建项目..."
  npm install -g pnpm
  pnpm install
  pnpm run build  

  # Step 2.6: 重启 Nginx 服务
  echo "重启 Nginx 服务..."
  sudo systemctl restart $NGINX_SERVICE
EOF

if [ $? -eq 0 ]; then
  echo "部署成功！Vue 项目已上线。"
else
  echo "部署失败，请检查服务器环境。"
fi
