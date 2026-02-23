# PRD: 私有镜像仓库迁移（registry.zata.cafe）

## 0. Clarifying Questions（待确认，含推荐）

1. 镜像仓库路径格式使用哪一种？
A. `registry.zata.cafe/transfileserver-app:<tag>`
B. `registry.zata.cafe/admin/transfileserver-app:<tag>`
C. `registry.zata.cafe/<team>/transfileserver-app:<tag>`（团队名可配置）
> **Recommended: B**（当前项目在 `build-and-push.sh`、`docker-compose.prod.yml` 都以“命名空间/镜像名”模式组织镜像，迁移成本最低）

2. 账号密码（`admin` / `123456`）如何使用？
A. 直接写入脚本和 workflow（明文）
B. 本地脚本通过环境变量读取，CI 通过 GitHub Secrets 读取
C. 完全不处理登录，要求操作者预先 `docker login`
> **Recommended: B**（现有 `.github/workflows/ci-cd.yml` 已使用 Secrets 模式，延续该安全模式）

3. 本次改造范围是否覆盖“所有发布入口”？
A. 仅改 `build-and-push*.sh`
B. 改脚本 + CI + `docker-compose.prod.yml` + 部署文档
C. 只改 CI workflow
> **Recommended: B**（当前推送入口分散在 `build-and-push*.sh`、`.github/workflows/ci-cd.yml`、`README.md`、`DEPLOYMENT.md`）

4. 对私有仓库证书策略采用哪种？
A. 仅支持 HTTPS + 有效证书
B. 支持 HTTP/自签名（需额外 Docker daemon 配置）
C. 两者都支持，默认 A，B 作为附加文档
> **Recommended: C**（默认安全；若内网仓库证书不完善，仍有落地路径）

5. 环境变量命名是否要保持兼容？
A. 全量替换 `DOCKERHUB_*` 为 `REGISTRY_*`
B. 兼容过渡：优先 `REGISTRY_*`，缺省回退 `DOCKERHUB_*`
C. 保持现状，仅手动替换字符串
> **Recommended: B**（避免现有 Dokploy 与脚本一次性中断，平滑迁移）

## 1. Introduction & Goals

将镜像构建与推送目标从 Docker Hub 迁移到私有仓库 `registry.zata.cafe`，并统一本地脚本、CI/CD、部署配置，保证发布链路可追溯、可回滚、可安全运维。

### 目标（可衡量）
- `main` 分支发布时，镜像推送地址变为 `registry.zata.cafe`。
- 本地脚本和 CI 都不再依赖 Docker Hub 专属变量命名。
- 凭据不写入仓库文件，全部通过环境变量或 Secrets 注入。
- Dokploy 部署可继续使用 `latest` + SHA 标签方式回滚。
- 迁移后上传/下载/分片上传功能零回归。

## 2. Implementation Guide (Technical Specs)

### 2.1 现状分析（基于代码）
- 镜像推送脚本固定使用 Docker Hub 用户名前缀：`build-and-push.sh`、`build-and-push-multiplatform.sh`。
- 生产 compose 镜像地址为 `${DOCKERHUB_USERNAME}/transfileserver-app:${APP_IMAGE_TAG}`：`docker-compose.prod.yml`。
- CI 使用 `DOCKERHUB_USERNAME` + `DOCKERHUB_TOKEN` 登录并推送：`.github/workflows/ci-cd.yml`。
- 文档中大量 Docker Hub 引导：`README.md`、`DEPLOYMENT.md`、`docs/deployment.md`。

### 2.2 Core Logic（迁移后发布流）
1. 开发者本地或 CI 构建单镜像 `transfileserver-app`。
2. 登录私有仓库 `registry.zata.cafe`。
3. 推送双标签：
   - `${REGISTRY_HOST}/${REGISTRY_NAMESPACE}/transfileserver-app:${GIT_SHA7}`
   - `${REGISTRY_HOST}/${REGISTRY_NAMESPACE}/transfileserver-app:latest`
4. Dokploy 拉取最新标签并部署。
5. 使用 `/healthz` 验证部署结果。

### 2.3 配置与变量设计
- 新增标准变量：
  - `REGISTRY_HOST`（默认：`registry.zata.cafe`）
  - `REGISTRY_NAMESPACE`（默认：`admin`）
  - `REGISTRY_USERNAME`
  - `REGISTRY_PASSWORD`
  - `APP_IMAGE_TAG`（保留）
- 兼容策略（推荐）：
  - 若 `REGISTRY_*` 未设置，则回退 `DOCKERHUB_*`，确保平滑迁移。

### 2.4 Affected Files（预计修改）
- `.github/workflows/ci-cd.yml`
- `build-and-push.sh`
- `build-and-push-multiplatform.sh`
- `docker-compose.prod.yml`
- `README.md`
- `DEPLOYMENT.md`
- `docs/deployment.md`
- `deploy-remote-test.sh`（仅在确认需覆盖测试双镜像路径时改）

### 2.5 Database / State Changes
- 无数据库变更。
- 无 API 协议变更。
- 文件持久化目录（`uploads`、`chunks`）保持不变。

### 2.6 关键实现细节
- CI 登录步骤从 Docker Hub 命名语义改为通用 Registry 语义。
- `docker-compose.prod.yml` 镜像地址改为私有仓库路径模板。
- 构建脚本参数由 `<dockerhub-username>` 改为 `<registry-namespace>` 或通用 `<image-repo-prefix>`。
- 文档统一更新为私有仓库示例，补充“自签证书/HTTP 仓库”的 daemon 配置说明（如适用）。

## 3. Global Definition of Done (DoD)
- [ ] Typecheck and Lint passes
- [ ] Verify visually in browser (if UI related)
- [ ] Follows existing project coding standards
- [ ] No regressions in existing features
- [ ] `docker build` + 本地推送脚本可成功推送到 `registry.zata.cafe`
- [ ] `push -> main` 后 CI 可成功登录并推送私有仓库镜像
- [ ] Dokploy 可成功拉取新镜像并通过 `/healthz`

## 4. User Stories

### US-001: 统一镜像命名与推送前缀
**Description:** 作为运维负责人，我希望镜像地址统一为私有仓库前缀，避免 Docker Hub 绑定。  

**Acceptance Criteria:**
- [ ] 脚本与 compose 不再硬编码 Docker Hub 用户名前缀
- [ ] 镜像标签规则保持 `latest` + `sha` 双标签

### US-002: 安全凭据注入
**Description:** 作为平台管理员，我希望账号密码通过环境变量/Secrets 注入，避免明文泄漏。  

**Acceptance Criteria:**
- [ ] 仓库内无明文 `admin/123456`
- [ ] CI 使用 GitHub Secrets 登录私有仓库
- [ ] 本地脚本支持环境变量注入登录

### US-003: CI/CD 私有仓库发布
**Description:** 作为开发者，我希望 push main 后自动推送到私有仓库并触发部署。  

**Acceptance Criteria:**
- [ ] CI 构建并推送 `registry.zata.cafe/...` 镜像
- [ ] Dokploy hook 正常触发
- [ ] 健康检查失败时流水线失败

### US-004: 文档与运维流程一致
**Description:** 作为团队成员，我希望文档示例与真实部署参数一致，减少操作错误。  

**Acceptance Criteria:**
- [ ] README/DEPLOYMENT/docs 中仓库地址、变量名、命令统一
- [ ] 提供回滚示例（指定 SHA tag）

## 5. Functional Requirements
- FR-1: 系统必须支持将镜像推送到 `registry.zata.cafe`。
- FR-2: 系统必须支持通过 `REGISTRY_USERNAME`/`REGISTRY_PASSWORD` 登录私有仓库。
- FR-3: 系统必须保留 `latest` 与 `sha` 双标签推送策略。
- FR-4: 系统必须在 `docker-compose.prod.yml` 中支持私有仓库镜像地址模板化配置。
- FR-5: 系统必须避免在仓库文件中存储明文凭据。
- FR-6: 系统必须保证 `push main` 的自动部署链路可用（build/push/deploy/healthcheck）。
- FR-7: 系统必须保证现有 API 能力不受镜像仓库迁移影响。
- FR-8: 系统必须提供兼容过渡方案（`REGISTRY_*` 优先，`DOCKERHUB_*` 回退）。

## 6. Non-Goals
- 不在本次改造中调整业务 API 逻辑。
- 不在本次改造中引入新编排平台（如 Kubernetes）。
- 不在本次改造中重构 `deploy-remote-test.sh` 的双镜像部署模型（除非明确纳入范围）。
- 不在本次改造中处理镜像漏洞扫描/签名体系（如 Trivy/Cosign）。
