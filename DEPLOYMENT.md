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
   - `zata/transfileserver-backend:latest` → `your-dockerhub-username/transfileserver-backend:latest`
   - `zata/transfileserver-frontend:latest` → `your-dockerhub-username/transfileserver-frontend:latest`
   - `<backend-port>` → 您想要的后端端口号（如：8000）
   - `<frontend-port>` → 您想要的前端端口号（如：80）
   - `<backend-port>` in REACT_APP_API_URL → 与上面后端端口号相同
   
   **重要**：确保 `REACT_APP_API_URL` 中的URL是从用户浏览器可以访问的地址：
   - 如果使用域名：`http://your-domain.com:8000`
   - 如果使用IP：`http://your-server-ip:8000`
   - 如果本地测试：`http://localhost:8000`

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

#### 前端环境变量说明

前端镜像现在支持运行时环境变量配置。`REACT_APP_API_URL` 环境变量会在容器启动时动态替换到构建好的JavaScript文件中。

**重要提示**：
- 前端是在用户浏览器中运行的，所以API URL必须是浏览器可以访问的地址
- 不能使用Docker内部服务名（如 `http://backend:8000`）
- 必须使用外部可访问的地址

#### 使用 .env 文件管理环境变量

您可以创建 `.env` 文件来管理环境变量：

```env
DOCKERHUB_USERNAME=your-username
SERVER_DOMAIN=your-domain.com
BACKEND_PORT=8000
FRONTEND_PORT=80
API_URL=http://your-domain.com:8000
```

然后在 `docker-compose.prod.yml` 中使用：
```yaml
services:
  backend:
    image: ${DOCKERHUB_USERNAME}/transfileserver-backend:latest
    ports:
      - "${BACKEND_PORT}:8000"
  
  frontend:
    image: ${DOCKERHUB_USERNAME}/transfileserver-frontend:latest
    ports:
      - "${FRONTEND_PORT}:80"
    environment:
      - REACT_APP_API_URL=${API_URL}
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