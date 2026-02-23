# PRD: 基于 Dokploy 的 CI/CD 自动部署（单镜像方案）

## 1. Introduction & Goals

本需求旨在将当前 `transFileServer` 项目从“手动构建 + 手动部署”升级为“GitHub Actions 自动构建发布 + Dokploy 自动部署”，并按你的选择采用**单镜像部署**（后端与前端静态资源合并到一个容器）。

### 目标（可衡量）
- 将 `main` 分支变更自动发布到 `production` 环境。
- 每次发布生成可追溯镜像标签（`git sha` + 环境标签）。
- 部署全流程无手工 SSH 登录服务器操作。
- 发布失败可在 10 分钟内定位到“构建失败 / 推镜像失败 / Dokploy部署失败”中的具体阶段。
- 保持现有上传、分片上传、relay 传输能力不回归。

## 2. Implementation Guide (Technical Specs)

### 2.1 现状分析（基于代码）
- 后端为 FastAPI，核心 API 在 `main.py`。
- 前端为 CRA React，当前独立容器部署，参考 `frontend/Dockerfile`。
- 现有生产部署依赖双服务 compose，参考 `docker-compose.prod.yml`。
- 当前构建推送脚本为双镜像模型，参考 `build-and-push.sh` 与 `build-and-push-multiplatform.sh`。
- 仓库当前无 `.github/workflows`，尚未具备 CI/CD workflow。

### 2.2 目标架构（按已确认决策）
- CI/CD 平台：`GitHub Actions`（构建/测试/推镜像） + `Dokploy`（部署）。
- 镜像策略：**单镜像**（`transfileserver-app`）。
- 环境策略：仅 `production` 单环境。
- 部署接入：Dokploy 管理 Compose（单服务），CI 在推镜像后触发 Dokploy 重新部署。
- 质量门禁：基础门禁（后端可启动+健康检查、前端可构建、镜像可构建）通过后才允许部署。

### 2.3 Core Logic（数据与发布流）
1. 开发者 push 到 `main`。
2. GitHub Actions 执行：
   - 后端依赖安装与基础可用性检查。
   - 前端 `npm ci && npm run build`。
   - 单镜像多阶段构建并推送 Docker Hub：
     - `your-dockerhub/transfileserver-app:<git-sha>`
     - `your-dockerhub/transfileserver-app:latest`
3. CI 调用 Dokploy Deploy Hook（或 API）触发环境重部署。
4. Dokploy 拉取新标签镜像并滚动重启。
5. CI 轮询健康检查 URL，成功则标记发布完成。

### 2.4 单镜像技术方案
- 使用根目录 `Dockerfile` 改为多阶段：
  - Stage A: 构建 React 静态文件（来自 `frontend/`）。
  - Stage B: Python 运行时安装 FastAPI 依赖。
  - 将前端 build 产物复制到后端镜像内固定目录（如 `/app/frontend_build`）。
- 后端 `main.py` 新增静态资源挂载：
  - 提供 `/` 及 SPA fallback 到 `index.html`。
  - API 仍保留 `/upload` `/download/{id}` `/files` `/relay/*`。
- 新增健康检查端点 `/healthz` 供 Dokploy 与 CI 验证。
- `docker-compose.prod.yml` 收敛为单服务（`app`），暴露单端口（如 `8000`）。

### 2.5 Database / State Changes
- 无数据库或持久化 schema 变更。
- 保留现有 volume 映射用于 `uploads/` 数据持久化。
- 运行时状态（relay session）仍为内存态，不纳入本次改造范围。

### 2.6 Affected Files（预计修改）
- `Dockerfile`
- `main.py`
- `docker-compose.prod.yml`
- `build-and-push.sh`
- `build-and-push-multiplatform.sh`
- `DEPLOYMENT.md`
- `README.md`
- `frontend/Dockerfile`（可能标记为 legacy 或删除）
- `frontend/docker-entrypoint.sh`（单镜像后可能不再需要）
- `.github/workflows/ci-cd.yml`（新增）
- `.dockerignore`（新增或完善）

### 2.7 CI/CD Workflow 设计

#### 触发规则
- `pull_request` 到 `main`：只跑校验（不部署）。
- `push` 到 `main`：发布 `production`。

#### Job 划分
- `validate`:
  - Python 依赖安装与语法/启动检查。
  - Frontend build 检查。
- `build_and_push`:
  - `docker/login-action` 登录 Docker Hub。
  - `docker/build-push-action` 构建单镜像并推送双标签。
- `deploy`:
  - 调用 Dokploy Hook（production）。
  - 等待并检查 `/healthz`。

#### 关键 Secrets
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `DOKPLOY_PROD_DEPLOY_HOOK`
- （可选）`PROD_HEALTHCHECK_URL`

### 2.8 Dokploy 配置要点
- 创建一个 production 应用：`transfileserver-prod`。
- 部署源选择 Docker Compose（单服务版本）。
- 镜像引用使用 `:latest`（或发布 tag）。
- 打开自动重启策略，配置健康检查路径 `/healthz`。

## 3. Global Definition of Done (DoD)
- [ ] Typecheck and Lint passes（在当前技术栈下至少保证基础语法检查与构建通过）
- [ ] Verify visually in browser（production 验证上传/下载/文件列表/relay 基本可用）
- [ ] Follows existing project coding standards
- [ ] No regressions in existing features
- [ ] `main` 合并后自动部署到 production 成功
- [ ] 镜像可通过 tag 回滚到上一个稳定版本

## 4. User Stories

### US-001: 建立单镜像运行形态
**Description:** 作为运维负责人，我希望系统可用单容器运行前后端，以降低 Dokploy 部署复杂度。  

**Acceptance Criteria:**
- [ ] 单镜像启动后可访问前端页面。
- [ ] API 路径与现有功能保持兼容。
- [ ] `uploads` 挂载持久化不受影响。

### US-002: 建立单环境生产发布流水线
**Description:** 作为开发者，我希望 `main` 分支变更可自动部署到生产环境，减少手工发布成本。  

**Acceptance Criteria:**
- [ ] `main` push 自动部署 production。
- [ ] PR 只校验不部署。

### US-003: 发布门禁与可观测性
**Description:** 作为团队成员，我希望失败发布能快速定位问题阶段，减少排障时间。  

**Acceptance Criteria:**
- [ ] CI 日志明确区分 validate/build/deploy 阶段。
- [ ] 部署后必须通过 `/healthz` 才标记成功。
- [ ] 部署失败时保留镜像 tag 与失败步骤信息。

### US-004: Dokploy 自动触发部署
**Description:** 作为平台管理员，我希望推镜像后 Dokploy 自动拉取并重启服务，无需手工点击。  

**Acceptance Criteria:**
- [ ] CI 能调用 Dokploy Hook 并收到成功响应。
- [ ] Dokploy 中可查看最近部署记录。
- [ ] 应用失败可手动回滚至上一 tag。

## 5. Functional Requirements
- FR-1: 系统必须提供 GitHub Actions workflow，实现 validate/build/push/deploy 全流程。
- FR-2: 系统必须将前后端整合为一个 Docker 镜像并在 Dokploy 中以单服务方式运行。
- FR-3: 系统必须支持 production 单环境的部署触发与镜像标签策略。
- FR-4: 系统必须在部署完成后执行健康检查（`/healthz`），失败则将流水线标记为失败。
- FR-5: 系统必须保留 `uploads` 的数据持久化挂载策略。
- FR-6: 系统必须支持使用 `git sha` 作为可追溯镜像版本。
- FR-7: 系统必须保证现有核心 API（上传、分片上传、下载、列表、删除、relay）行为不回归。
- FR-8: 文档必须包含本地验证、Secrets 配置、Dokploy 配置与回滚步骤。

## 6. Non-Goals
- 不在本次引入数据库或对象存储（如 S3/MinIO）替代本地文件系统。
- 不在本次引入完整 E2E 测试体系与安全扫描平台（仅基础门禁）。
- 不在本次改造 relay 会话持久化与多实例一致性问题。
- 不在本次将部署平台从 Dokploy 迁移到 Kubernetes。

## 7. Risks & Mitigations
- 风险: 单镜像导致镜像体积增大。  
  缓解: 多阶段构建 + `.dockerignore` + 仅复制 build 产物。
- 风险: React SPA 路由与 API 路由冲突。  
  缓解: 明确 `/api`（如后续重构）或先以现有 API 前缀白名单优先匹配。
- 风险: Dokploy hook 调用成功但应用未真正可用。  
  缓解: CI 追加健康检查轮询与超时失败策略。

## 8. Rollout Plan
1. 在 `main` 上完成单镜像改造与自动部署验证。
2. 连续通过 3 次发布后，将当前流程作为默认发布路径。
3. 首周保留手动回滚预案（指定上一个稳定镜像 tag）。
