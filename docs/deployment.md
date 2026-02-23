# Deployment Guide

This guide describes production deployment for the single-image `admin/transfileserver-app` using a private registry.

## Private Registry Deployment (Recommended)

### Prerequisites
- Docker installed on your server
- Access to `registry.zata.cafe` over HTTPS with a valid certificate
- Registry credentials with pull/push permissions

### 1. Login to Private Registry

```bash
docker login registry.zata.cafe
```

### 2. Build and Push Image

#### Option A: Multi-platform Build (Recommended)

```bash
chmod +x build-and-push-multiplatform.sh
REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push-multiplatform.sh latest linux/amd64,linux/arm64
```

Verify manifest:

```bash
docker buildx imagetools inspect registry.zata.cafe/admin/transfileserver-app:latest
```

#### Option B: Single Platform Build

```bash
chmod +x build-and-push.sh
REGISTRY_USERNAME=admin REGISTRY_PASSWORD=****** ./build-and-push.sh latest
```

### 3. Server Deployment with Compose

1. Create project directory on server:

```bash
mkdir -p transfileserver && cd transfileserver
```

2. Copy `docker-compose.prod.yml` from this repository.

3. Start service:

```bash
REGISTRY_HOST=registry.zata.cafe \
REGISTRY_REPOSITORY=admin/transfileserver-app \
APP_IMAGE_TAG=latest \
APP_PORT=8000 \
docker compose -f docker-compose.prod.yml up -d --pull always
```

4. Check status:

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f
```

### 4. CI/CD (GitHub Actions + Dokploy)

Workflow file: `.github/workflows/ci-cd.yml`

Required GitHub Secrets:
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`
- `DOKPLOY_PROD_DEPLOY_HOOK`

Optional GitHub Secret:
- `PROD_HEALTHCHECK_URL`

On `push` to `main`, the workflow pushes:
- `registry.zata.cafe/admin/transfileserver-app:<sha7>`
- `registry.zata.cafe/admin/transfileserver-app:latest`

### 5. Rollback

Rollback by pinning a previous SHA tag:

```bash
REGISTRY_HOST=registry.zata.cafe REGISTRY_REPOSITORY=admin/transfileserver-app APP_IMAGE_TAG=a1b2c3d docker compose -f docker-compose.prod.yml up -d --pull always
```

### 6. Remote Test Deployment Script (Legacy Two-Image Flow)

If you still maintain test images `transfileserver-backend:test` and `transfileserver-frontend:test`, use:

```bash
chmod +x deploy-remote-test.sh
./deploy-remote-test.sh <server-ip> <ssh-user> <image-prefix> [ssh-port] [backend-port] [frontend-port] [registry-host]
```

Example:

```bash
./deploy-remote-test.sh 47.94.199.65 root admin/transfileserver 22 8002 3003 registry.zata.cafe
```

## Security Checklist

- Restrict CORS origins in `main.py` for production.
- Use HTTPS termination in reverse proxy or platform ingress.
- Keep registry credentials only in environment variables or GitHub Secrets.
- Do not commit plaintext credentials.

## Health Verification

After deployment, verify:

1. `GET /healthz` returns `200`
2. Frontend homepage loads
3. Upload / download / list / delete APIs work
4. Chunk upload flow works
