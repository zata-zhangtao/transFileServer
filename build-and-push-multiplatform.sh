#!/bin/bash

# 多平台构建和推送Docker镜像到Docker Hub
# 支持从ARM64 Mac构建x86镜像
# 使用方法: ./build-and-push-multiplatform.sh your-dockerhub-username
# 示例: ./build-and-push-multiplatform.sh zata latest linux/amd64,linux/arm64
# 示例: ./build-and-push-multiplatform.sh zata v1.0 linux/amd64

if [ -z "$1" ]; then
    echo "用法: $0 <your-dockerhub-username> [version] [platforms]"
    echo "示例: $0 myusername latest linux/amd64,linux/arm64"
    echo "示例: $0 myusername v1.0 linux/amd64"
    exit 1
fi

USERNAME=$1
VERSION=${2:-latest}
PLATFORMS=${3:-"linux/amd64,linux/arm64"}

echo "🏗️  设置Docker Buildx..."
# 创建并使用支持多平台的builder
docker buildx create --name multiplatform-builder --use --bootstrap 2>/dev/null || \
docker buildx use multiplatform-builder

echo "📋 构建信息："
echo "  用户名: $USERNAME"
echo "  版本: $VERSION"
echo "  平台: $PLATFORMS"
echo ""

echo "🔨 构建并推送后端镜像 ($PLATFORMS)..."
docker buildx build \
    --platform $PLATFORMS \
    --tag $USERNAME/transfileserver-backend:$VERSION \
    --push \
    .

echo "🔨 构建并推送前端镜像 ($PLATFORMS)..."
docker buildx build \
    --platform $PLATFORMS \
    --tag $USERNAME/transfileserver-frontend:$VERSION \
    --push \
    ./frontend

echo "✅ 多平台镜像构建并推送完成！"
echo ""
echo "🔍 查看镜像信息："
echo "docker buildx imagetools inspect $USERNAME/transfileserver-backend:$VERSION"
echo "docker buildx imagetools inspect $USERNAME/transfileserver-frontend:$VERSION"
echo ""
echo "📋 服务器部署："
echo "1. 在服务器上下载 docker-compose.prod.yml"
echo "2. 修改其中的 your-dockerhub-username 为 $USERNAME"
echo "3. 修改 your-server-domain 为您的服务器域名/IP"
echo "4. 运行: docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo "💡 提示: 镜像已支持 ARM64 和 x86_64 架构，可在任意平台部署！" 