# Task Plan: PRD Dokploy CI/CD Single Image 落地

## Goal
完成 `tasks/prd-dokploy-cicd-single-image.md` 中的改造：将项目改为单镜像部署，新增 GitHub Actions + Dokploy 自动部署链路，并补齐文档与配置说明。

## Current Phase
Phase 5

## Phases
### Phase 1: Requirements & Discovery
- [x] Understand user intent
- [x] Identify constraints and requirements
- [x] Document findings in findings.md
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

### Phase 2: Planning & Structure
- [x] Define technical approach
- [x] Create project structure if needed
- [x] Document decisions with rationale
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

### Phase 3: Implementation
- [x] Execute the plan step by step
- [x] Write code to files before executing
- [x] Test incrementally
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

### Phase 4: Testing & Verification
- [x] Verify all requirements met
- [x] Document test results in progress.md
- [x] Fix any issues found
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

### Phase 5: Delivery
- [x] Review all output files
- [x] Ensure deliverables are complete
- [x] Deliver to user
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

## Key Questions
1. 现有后端路由如何在不回归 API 的前提下新增 SPA 托管与 fallback？
2. GitHub Actions 与 Dokploy Hook 的最小可用配置是什么？

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 采用单镜像多阶段构建 | 符合 PRD 并降低 Dokploy 编排复杂度 |
| CI 分为 validate/build_and_push/deploy | 让失败阶段可快速定位 |
| 保留前端 dev 模式与后端 dev 模式并行 | 不破坏本地开发体验，生产仅单镜像 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |
| frontend build 写入 `frontend/build` 失败（EACCES） | 1 | 改为 `BUILD_PATH=build-ci npm run build` 完成校验 |
| Docker build 无法连接 daemon | 1 | 记录为环境限制，无法完成本机镜像实构验证 |

## Completion Summary
### FULL Format (for complex tasks)

#### Final Status
- **Completed:** YES
- **Completion Date:** 2026-02-23

#### Deliverables
| Deliverable | Location | Status |
|-------------|----------|--------|
| 单镜像 FastAPI + SPA 托管 | `main.py` | done |
| 多阶段单镜像 Dockerfile | `Dockerfile` | done |
| 单服务生产 compose | `docker-compose.prod.yml` | done |
| CI/CD 工作流 | `.github/workflows/ci-cd.yml` | done |
| 单镜像构建推送脚本 | `build-and-push.sh` | done |
| 多平台单镜像构建推送脚本 | `build-and-push-multiplatform.sh` | done |
| 构建上下文优化 | `.dockerignore` | done |
| 部署说明更新 | `DEPLOYMENT.md` | done |
| 使用说明更新 | `README.md` | done |

#### Key Achievements
- 完成从双镜像到单镜像的生产部署形态迁移。
- 建立 PR 校验与 main 自动发布流程，并接入 Dokploy Hook。
- 增加 `/healthz` 与部署后健康检查策略。

#### Challenges & Solutions
| Challenge | Solution Applied |
|-----------|------------------|
| `frontend/build` 目录权限导致构建失败 | 使用 `BUILD_PATH=build-ci` 完成前端构建校验 |
| 本机 Docker daemon 不可用 | 记录为环境限制，并通过 workflow 保留 Docker build 门禁 |

#### Lessons Learned
- 将前端构建物直接并入 FastAPI 容器，可显著简化 Dokploy 编排。
- 使用 `sha` + `latest` 双标签能同时满足追踪与便捷部署。

#### Follow-up Items
- [ ] 在 Dokploy 完成首轮线上部署后，补一次真实 e2e 冒烟记录（上传/下载/分片/删除）。

---

## Notes
- Update phase status as you progress: pending → in_progress → complete
- Re-read this plan before major decisions (attention manipulation)
- Log ALL errors - they help avoid repetition
