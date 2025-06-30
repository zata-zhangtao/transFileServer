#!/bin/bash

# 构建和推送Docker镜像到Docker Hub
# 使用方法: ./build-and-push.sh your-dockerhub-username

if [ -z "$1" ]; then
    echo "用法: $0 <your-dockerhub-username>"
    echo "示例: $0 myusername"
    exit 1
fi

USERNAME=$1
VERSION=${2:-latest}

echo "🔨 构建后端镜像..."
docker build -t $USERNAME/transfileserver-backend:$VERSION .

echo "🔨 构建前端镜像..."
docker build -t $USERNAME/transfileserver-frontend:$VERSION ./frontend

echo "📤 推送后端镜像到Docker Hub..."
docker push $USERNAME/transfileserver-backend:$VERSION

echo "📤 推送前端镜像到Docker Hub..."
docker push $USERNAME/transfileserver-frontend:$VERSION

echo "✅ 镜像推送完成！"
echo ""
echo "📋 下一步："
echo "1. 在服务器上下载 docker-compose.prod.yml"
echo "2. 修改其中的 your-dockerhub-username 为 $USERNAME"
echo "3. 修改 your-server-domain 为您的服务器域名/IP"
echo "4. 运行: docker-compose -f docker-compose.prod.yml up -d" 