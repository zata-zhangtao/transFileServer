# PRD: Dokploy 内置 Traefik 反向代理接入（单域名 HTTPS）

## 0. Clarifying Questions（已确认）

1. 路由层选择：A（仅 Dokploy 内置 Traefik）
2. 域名策略：A（前后端共用一个域名）
3. TLS 策略：A（Let's Encrypt 自动签发）
4. 端口暴露策略：A（关闭宿主机端口直出）
5. 路由规则：A（Host 规则）

---

## 1. Introduction & Goals

本需求目标是在现有单镜像部署（FastAPI + React 静态文件）基础上，接入 Dokploy 内置 Traefik 作为统一入口，实现单域名 HTTPS 访问，并移除宿主机端口直出，提升生产安全性与可维护性。

### 目标（可衡量）

- 将生产访问入口从 `http://<server>:8000` 切换为 `https://<your-domain>`。
- Dokploy 中启用 Traefik Host 路由（单域名）并自动申请/续期 Let's Encrypt 证书。
- 生产 Compose 不再使用 `ports` 对外暴露容器 `8000`。
- 部署后 `GET /healthz` 可通过域名返回 `200`。
- 现有上传、下载、分片上传、文件列表、删除功能零回归。

---

## 2. Implementation Guide (Technical Specs)

### 2.1 现状分析（基于仓库）

- 当前为单服务生产 compose：`docker-compose.prod.yml`（服务名 `app`）。
- 当前通过 `ports: "${APP_PORT:-8000}:8000"` 直接暴露宿主机端口。
- 后端已提供健康检查：`GET /healthz`（`main.py`）。
- 前端已由后端同容器托管（`main.py` 的 `/` 和 SPA fallback 路由）。
- CI 已支持 Dokploy deploy hook 与可选健康检查 URL（`.github/workflows/ci-cd.yml`）。

### 2.2 目标架构（确认后的方案）

流量路径：
1. 用户访问 `https://files.example.com`（示例）。
2. DNS 指向 Dokploy/Traefik 所在公网入口。
3. Traefik 根据 `Host(files.example.com)` 将请求转发至 `app:8000`。
4. 应用同域返回前端页面与 API 响应。
5. Dokploy 管理证书（Let's Encrypt）与路由规则。

### 2.3 Core Logic（改造重点）

- **入口收敛**：将外部入口统一到 Traefik，容器只在内部网络暴露 `8000`。
- **同域访问**：前端与 API 维持同源，不新增跨域链路。
- **证书自动化**：依赖 Dokploy 内置 Traefik 的 LE 自动签发与续期。
- **发布链路兼容**：CI 触发 Dokploy 部署流程保持不变，仅健康检查 URL 切换到域名。

### 2.4 配置变更清单

#### A. Dokploy 平台配置（必做）
- 应用类型继续使用 Docker Compose（现有 `docker-compose.prod.yml`）。
- 在 Dokploy 应用中绑定域名（如 `files.example.com`）。
- 路由规则使用 Host（`files.example.com`）。
- 开启 HTTPS（Let's Encrypt）。
- 容器目标端口设置为 `8000`（内部端口）。
- 健康检查路径维持 `/healthz`。

#### B. Compose 变更（必做）
- 删除对外 `ports` 映射（关闭 `APP_PORT:8000` 直出）。
- 增加 `expose: ["8000"]`（可选但推荐，明确内部暴露语义）。
- 维持 `volumes`、`healthcheck`、`restart` 现有策略。

#### C. CI/CD 与文档（必做）
- 将 `PROD_HEALTHCHECK_URL` 更新为 `https://<your-domain>/healthz`。
- 文档中的生产访问地址更新为域名而非 `server:port`。

#### D. 应用代码（可选增强）
- `main.py` 当前 `CORS allow_origins=["*"]`，建议生产收敛为域名白名单。
- 该项不阻塞 Traefik 代理接入，但属于安全加固建议。

### 2.5 Affected Files（预计影响）

- `docker-compose.prod.yml`（移除 `ports`，改内部暴露策略）
- `DEPLOYMENT.md`（Dokploy + Traefik 域名/TLS 操作说明）
- `README.md`（生产访问方式更新）
- `docs/deployment.md`（部署手册改为域名入口）
- `main.py`（可选：CORS 白名单收敛）
- `.github/workflows/ci-cd.yml`（通常无需改代码；仅更新 Secret 值）

### 2.6 Database / State Changes

- 无数据库变更。
- 无 API 协议变更。
- 文件持久化目录 `uploads`/`chunks` 保持不变。

---

## 3. Global Definition of Done (DoD)

- [ ] Typecheck and Lint passes
- [ ] Verify visually in browser (if UI related)
- [ ] Follows existing project coding standards
- [ ] No regressions in existing features
- [ ] 域名 `https://<your-domain>` 可访问前端首页
- [ ] `https://<your-domain>/healthz` 返回 `200`
- [ ] 宿主机不再开放应用直出端口（仅 Traefik 对外）
- [ ] 上传/下载/分片上传/列表/删除功能验证通过

---

## 4. User Stories

### US-001: 接入 Traefik 单域名路由
**Description:** 作为终端用户，我希望通过一个 HTTPS 域名访问系统，从而获得稳定与安全的入口。

**Acceptance Criteria:**
- [ ] 配置 `Host(<your-domain>)` 路由成功
- [ ] HTTPS 证书签发成功且可续期
- [ ] 前端页面与 API 均可通过同域访问

### US-002: 关闭应用端口直出
**Description:** 作为运维人员，我希望应用不直接暴露宿主机端口，以减少攻击面。

**Acceptance Criteria:**
- [ ] `docker-compose.prod.yml` 不再包含 `ports` 对外映射
- [ ] 应用仅通过 Traefik 暴露到公网
- [ ] 不影响 Dokploy 内部转发到 `app:8000`

### US-003: 保持自动部署链路可用
**Description:** 作为开发者，我希望 push main 后仍可自动部署并验收健康状态。

**Acceptance Criteria:**
- [ ] Dokploy deploy hook 继续可用
- [ ] `PROD_HEALTHCHECK_URL` 指向域名 `/healthz`
- [ ] 部署失败时 workflow 明确失败

### US-004: 文档与真实配置一致
**Description:** 作为团队成员，我希望部署文档直接反映 Traefik 方案，避免误操作。

**Acceptance Criteria:**
- [ ] README/DEPLOYMENT/docs 中均使用域名访问示例
- [ ] 文档包含 Dokploy 域名、TLS、健康检查设置说明
- [ ] 文档说明生产不再建议端口直出

---

## 5. Functional Requirements

- FR-1: 系统必须支持 Dokploy 内置 Traefik 进行 Host 路由转发。
- FR-2: 系统必须支持单域名承载前端与 API。
- FR-3: 系统必须支持 Let's Encrypt 自动签发与续期 HTTPS 证书。
- FR-4: 生产 compose 必须移除宿主机 `ports` 直出映射。
- FR-5: 应用必须继续监听容器内 `8000` 供 Traefik 转发。
- FR-6: 部署后健康检查必须可通过 `https://<domain>/healthz` 验证。
- FR-7: 现有核心 API（上传/下载/分片上传/列表/删除）必须保持行为一致。
- FR-8: CI/CD 流程必须继续支持 Dokploy Hook 自动部署。
- FR-9: 部署文档必须明确 DNS、域名绑定、TLS 与回滚流程。
- FR-10: 系统应支持可选安全加固（CORS 白名单）且不影响主流程上线。

---

## 6. Non-Goals

- 不在本次改造中更换部署平台（如迁移到 Kubernetes）。
- 不在本次改造中引入新网关或独立 Traefik 集群。
- 不在本次改造中重构业务 API 与文件存储模型。
- 不在本次改造中引入额外认证体系（如 OAuth/WAF）。
- 不在本次改造中处理多活或跨区域容灾架构。
