# Dokploy + GitHub Actions 自动部署指南（单镜像）

本文档对应当前仓库的单镜像部署方案：`transfileserver-app`。

## 1. 架构说明

- CI/CD：GitHub Actions
- 镜像仓库：私有仓库 `registry.zata.cafe`
- 部署平台：Dokploy
- 运行模式：单容器（FastAPI + React build 静态资源）

镜像标签策略：

- `${GIT_SHA7}`（可回滚）
- `latest`（默认追踪）

## 2. 你需要先配置什么

### A. 私有镜像仓库（registry.zata.cafe）

1. 确保仓库路径可用（例如 `registry.zata.cafe/admin/transfileserver-app`）
2. 准备可推送凭据（用户名 + 密码）
### B. GitHub Repository Secrets（仓库级）

在 GitHub 仓库 `Settings → Secrets and variables → Actions` 中新增以下 **Repository Secrets**：

1. `REGISTRY_USERNAME` = 私有仓库用户名（例如 `admin`）
2. `REGISTRY_PASSWORD` = 私有仓库密码
3. `DOKPLOY_PROD_DEPLOY_HOOK` = Dokploy 提供的部署 Hook URL
4. `PROD_HEALTHCHECK_URL`（可选）= 线上健康检查地址（建议配置）

> 说明：以上密钥只需配置在仓库层面即可，工作流运行时会自动注入，无需为每个环境单独设置 Environment Secrets。
示例：

- `PROD_HEALTHCHECK_URL=https://files.example.com/healthz`

### C. Dokploy 应用配置

在 Dokploy 新建应用（建议名：`transfileserver-prod`）：

1. 类型选择：`Docker Compose`
2. Compose 内容使用仓库根目录的 `docker-compose.prod.yml`
3. 环境变量建议：
   - `REGISTRY_HOST=registry.zata.cafe`
   - `REGISTRY_REPOSITORY=admin/transfileserver-app`
   - `APP_IMAGE_TAG=latest`
   - `APP_PORT=8000`（或你想暴露的端口）
4. 持久化目录：确保 `uploads`（以及可选 `chunks`）映射到持久卷
5. 健康检查：路径 `/healthz`
6. 重启策略：`unless-stopped`

> 提示：如果使用域名，请在 Dokploy/反向代理层将外部域名转发到容器 `8000` 端口。

## 3. Workflow 行为

工作流文件：`.github/workflows/ci-cd.yml`

- `pull_request` 到 `main`：
  - Python 依赖安装
  - 后端语法与启动健康检查
  - 前端构建检查
  - Docker 构建检查
- `push` 到 `main`：
  - 执行上述校验
  - 构建并推送
    - `registry.zata.cafe/admin/transfileserver-app:<sha7>`
    - `registry.zata.cafe/admin/transfileserver-app:latest`
  - 调用 `DOKPLOY_PROD_DEPLOY_HOOK`
  - 轮询 `PROD_HEALTHCHECK_URL`（若配置）

## 4. 手动构建/推送（可选）

### 单平台

```bash
REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push.sh v1.0.0
```

### 多平台

```bash
REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push-multiplatform.sh v1.0.0 linux/amd64,linux/arm64
```

## 5. 回滚方案

### 推荐：回滚到历史 SHA 标签

1. 在私有仓库找到上一个稳定标签（如 `a1b2c3d`）
2. 在 Dokploy 将 `APP_IMAGE_TAG` 改为该标签
3. 重新部署（Deploy）

或在服务器上手动：

```bash
REGISTRY_HOST=registry.zata.cafe REGISTRY_REPOSITORY=admin/transfileserver-app APP_IMAGE_TAG=a1b2c3d docker compose -f docker-compose.prod.yml up -d --pull always
```

## 6. 验证清单

部署成功后至少验证：

1. `GET /healthz` 返回 200
2. 前端首页可访问
3. 上传文件、下载文件、文件列表、删除可用
4. 分片上传可用
