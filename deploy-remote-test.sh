#!/bin/bash

# 远程SSH部署脚本 - 用于快速部署test版本
# 支持删除旧版本和部署新版本
# 使用方法: ./deploy-remote-test.sh <server-ip> <ssh-user> <image-prefix> [ssh-port] [backend-port] [frontend-port] [registry-host]
# 示例: ./deploy-remote-test.sh 192.168.1.100 root admin/transfileserver
# 示例: ./deploy-remote-test.sh 47.94.199.65 root admin/transfileserver 22 8002 8003 registry.zata.cafe

# 检查参数
if [ $# -lt 3 ]; then
    echo "❌ 参数不足"
    echo "用法: $0 <server-ip> <ssh-user> <image-prefix> [ssh-port] [backend-port] [frontend-port] [registry-host]"
    echo "示例: $0 47.94.199.65 root admin/transfileserver"
    echo "示例: $0 47.94.199.65 root admin/transfileserver 22 8002 8003 registry.zata.cafe"
    exit 1
fi

# 参数设置
SERVER_IP=$1
SSH_USER=$2
IMAGE_PREFIX=$3
SSH_PORT=${4:-22}
BACKEND_PORT=${5:-8002}
FRONTEND_PORT=${6:-3003}
REGISTRY_HOST=${7:-registry.zata.cafe}

echo "🚀 远程部署test版本配置："
echo "  服务器IP: $SERVER_IP"
echo "  SSH用户: $SSH_USER"
echo "  SSH端口: $SSH_PORT"
echo "  Registry Host: $REGISTRY_HOST"
echo "  Image Prefix: $IMAGE_PREFIX"
echo "  后端端口: $BACKEND_PORT"
echo "  前端端口: $FRONTEND_PORT"
echo ""

# 检查SSH连接
echo "🔍 检查SSH连接..."
if ! ssh -p $SSH_PORT -o ConnectTimeout=5 -o StrictHostKeyChecking=no $SSH_USER@$SERVER_IP "echo 'SSH连接成功'" 2>/dev/null; then
    echo "❌ SSH连接失败，请检查："
    echo "  1. 服务器IP是否正确"
    echo "  2. SSH用户和密钥是否正确"
    echo "  3. 网络是否可达"
    exit 1
fi

# 创建远程部署脚本
REMOTE_SCRIPT=$(cat <<'EOF'
#!/bin/bash

# 设置变量
IMAGE_PREFIX="$1"
BACKEND_PORT="$2"
FRONTEND_PORT="$3"
SERVER_IP="$4"
REGISTRY_HOST="$5"

echo "🗑️  清理旧的test版本..."

# 停止并删除旧的test版本容器
docker ps -a | grep "transfileserver.*:test" | awk '{print $1}' | xargs -r docker stop
docker ps -a | grep "transfileserver.*:test" | awk '{print $1}' | xargs -r docker rm

# 删除旧的test版本镜像
docker images | grep "$REGISTRY_HOST/$IMAGE_PREFIX-.*:test" | awk '{print $3}' | xargs -r docker rmi

echo "📥 拉取新的test版本镜像..."
docker pull $REGISTRY_HOST/$IMAGE_PREFIX-backend:test
docker pull $REGISTRY_HOST/$IMAGE_PREFIX-frontend:test

echo "🚀 启动新的test版本..."

# 创建临时的docker-compose文件
cat > docker-compose.test.yml << EOL
version: '3.8'

services:
  backend-test:
    image: $REGISTRY_HOST/$IMAGE_PREFIX-backend:test
    ports:
      - "$BACKEND_PORT:8000"
    volumes:
      - ./uploads-test:/app/uploads
    environment:
      - PYTHONUNBUFFERED=1
    restart: unless-stopped

  frontend-test:
    image: $REGISTRY_HOST/$IMAGE_PREFIX-frontend:test
    ports:
      - "$FRONTEND_PORT:80"
    depends_on:
      - backend-test
    environment:
      - REACT_APP_API_URL=http://$SERVER_IP:$BACKEND_PORT
    restart: unless-stopped

volumes:
  uploads-test:
    driver: local
EOL

# 启动服务
docker-compose -f docker-compose.test.yml up -d --force-recreate

echo "✅ Test版本部署完成！"
echo ""
echo "🔗 访问地址："
echo "  前端: http://$SERVER_IP:$FRONTEND_PORT"
echo "  后端API: http://$SERVER_IP:$BACKEND_PORT"
echo ""
echo "📋 管理命令："
echo "  查看日志: docker-compose -f docker-compose.test.yml logs -f"
echo "  停止服务: docker-compose -f docker-compose.test.yml down"
echo "  重启服务: docker-compose -f docker-compose.test.yml restart"
EOF
)

echo "📤 上传部署脚本到远程服务器..."
echo "$REMOTE_SCRIPT" | ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "cat > deploy-test.sh && chmod +x deploy-test.sh"

echo "🚀 在远程服务器上执行部署..."
ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "./deploy-test.sh '$IMAGE_PREFIX' '$BACKEND_PORT' '$FRONTEND_PORT' '$SERVER_IP' '$REGISTRY_HOST'"

echo ""
echo "✅ 远程部署完成！"
echo ""
echo "🔗 Test版本访问地址："
echo "  前端: http://$SERVER_IP:$FRONTEND_PORT"
echo "  后端API: http://$SERVER_IP:$BACKEND_PORT"
echo ""
echo "📋 远程管理命令："
echo "  查看容器状态: ssh -p $SSH_PORT $SSH_USER@$SERVER_IP 'docker ps'"
echo "  查看日志: ssh -p $SSH_PORT $SSH_USER@$SERVER_IP 'docker logs transfileserver-backend-test'"
echo "  停止test版本: ssh -p $SSH_PORT $SSH_USER@$SERVER_IP 'docker-compose -f docker-compose.test.yml down'"
echo ""
echo "💡 提示: 脚本已保存在远程服务器的 deploy-test.sh 文件中，可直接在服务器上重复使用" 
