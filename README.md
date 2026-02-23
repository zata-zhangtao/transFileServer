# File Transfer Server

FastAPI + React 的文件传输服务，支持文件/文本上传、分片上传、大文件下载进度、文件列表与删除。

## Features

- 文件上传（`POST /upload`）
- 分片上传（`POST /upload-chunk` + `GET /upload-status/{file_id}`）
- 文件下载（`GET /download/{file_id}`）
- 文件列表（`GET /files`）
- 文件删除（`DELETE /delete/{file_id}`）
- 健康检查（`GET /healthz`）
- 生产环境单镜像（后端 + 前端静态资源）

## Local Development

### 1) Backend

```bash
pip install -r requirements.txt
python main.py
```

Backend: `http://localhost:8000`

### 2) Frontend

```bash
cd frontend
npm ci
npm start
```

Frontend: `http://localhost:3000`

## Production (Single Image)

### Build local image

```bash
docker build -t transfileserver-app:local .
```

### Run with compose

```bash
DOCKERHUB_USERNAME=your-dockerhub-username \
APP_IMAGE_TAG=latest \
APP_PORT=8000 \
docker compose -f docker-compose.prod.yml up -d --pull always
```

App URL: `http://<server>:8000`
Healthcheck: `http://<server>:8000/healthz`

## CI/CD (GitHub Actions + Dokploy)

已提供 workflow：`.github/workflows/ci-cd.yml`

- `pull_request -> main`：只执行 validate（不部署）
- `push -> main`：validate + build/push + deploy

必需 GitHub Secrets：

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `DOKPLOY_PROD_DEPLOY_HOOK`

可选 GitHub Secret：

- `PROD_HEALTHCHECK_URL`（例如 `https://your-domain/healthz`）

详细部署步骤见 `DEPLOYMENT.md`。
