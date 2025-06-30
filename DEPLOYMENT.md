# Docker Hub 部署指南

## 📋 部署流程

### 1. 准备工作

1. 注册 [Docker Hub](https://hub.docker.com/) 账号
2. 本地登录 Docker Hub：
   ```bash
   docker login
   ```

### 2. 构建并推送镜像

#### 方法一：多平台构建（推荐 - 支持ARM64 Mac构建x86镜像）

1. 给脚本执行权限：
   ```bash
   chmod +x build-and-push-multiplatform.sh
   ```

2. 构建并推送多平台镜像：
   ```bash
   # 构建支持ARM64和x86_64的镜像
   ./build-and-push-multiplatform.sh your-username
   
   # 或者只构建x86_64版本（适用于x86服务器）
   ./build-and-push-multiplatform.sh your-username latest linux/amd64
   
   # 或者指定特定版本
   ./build-and-push-multiplatform.sh your-username v1.0 linux/amd64,linux/arm64
   ```

3. 验证多平台支持：
   ```bash
   docker buildx imagetools inspect your-username/transfileserver-backend:latest
   ```

#### 方法二：单平台构建

1. 给脚本执行权限：
   ```bash
   chmod +x build-and-push.sh
   ```

2. 构建并推送镜像：
   ```bash
   ./build-and-push.sh your-username
   ```

   或者手动构建：
   ```bash
   # 构建镜像
   docker build -t your-username/transfileserver-backend:latest .
   docker build -t your-username/transfileserver-frontend:latest ./frontend
   
   # 推送镜像
   docker push your-username/transfileserver-backend:latest
   docker push your-username/transfileserver-frontend:latest
   ```

### 3. 服务器部署

1. 在服务器上创建项目目录：
   ```bash
   mkdir transfileserver && cd transfileserver
   ```

2. 下载生产环境配置文件：
   ```bash
   wget https://raw.githubusercontent.com/your-repo/transfileserver/main/docker-compose.prod.yml
   ```

3. 编辑配置文件：
   ```bash
   nano docker-compose.prod.yml
   ```
   
   修改以下内容：
   - `your-dockerhub-username` → 您的Docker Hub用户名
   - `your-server-domain` → 您的服务器域名或IP地址

4. 启动服务：
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

5. 查看运行状态：
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   docker-compose -f docker-compose.prod.yml logs
   ```

### 4. 域名和反向代理配置（可选）

如果使用域名，建议配置Nginx反向代理：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 5. 更新部署

当代码更新时：

1. 重新构建并推送镜像：
   ```bash
   ./build-and-push.sh your-username
   ```

2. 在服务器上拉取最新镜像并重启：
   ```bash
   docker-compose -f docker-compose.prod.yml pull
   docker-compose -f docker-compose.prod.yml up -d
   ```

### 6. 环境变量配置

您可以创建 `.env` 文件来管理环境变量：

```env
DOCKERHUB_USERNAME=your-username
SERVER_DOMAIN=your-domain.com
BACKEND_PORT=8000
FRONTEND_PORT=80
```

然后在 `docker-compose.prod.yml` 中使用：
```yaml
image: ${DOCKERHUB_USERNAME}/transfileserver-backend:latest
environment:
  - REACT_APP_API_URL=http://${SERVER_DOMAIN}:${BACKEND_PORT}
```

## 🚀 优势

- ✅ 无需在服务器上构建，部署快速
- ✅ 版本管理方便
- ✅ 易于扩展到多服务器
- ✅ 支持自动化CI/CD

## 🔧 故障排除

1. **镜像推送失败**：检查Docker Hub登录状态
2. **服务无法启动**：检查端口占用和权限
3. **文件上传失败**：检查uploads目录权限 