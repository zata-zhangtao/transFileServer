# Task Plan: Dokploy Traefik Proxy 落地

## Goal
根据 `tasks/prd-dokploy-traefik-proxy.md` 完成实际改造：在 Dokploy 中通过内置 Traefik 代理单域名 HTTPS 访问，关闭应用宿主机端口直出，并同步文档与发布验收说明。

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
- [x] Confirm affected files
- [x] Define validation checklist
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

### Phase 3: Implementation
- [x] Update production compose to remove direct host port exposure
- [x] Update deployment docs to Traefik/domain-based entrypoint
- [x] Keep CI health-check guidance aligned with domain mode
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

### Phase 4: Testing & Verification
- [x] Verify file changes and consistency
- [x] Review rendered commands/examples for correctness
- [x] Capture residual risks
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

### Phase 5: Delivery
- [x] Summarize changes with file references
- [x] List next operational steps for Dokploy config
- **Status:** complete
- **Started:** 2026-02-23
- **Completed:** 2026-02-23

## Key Questions
1. 是否只改文档+compose，还是连同应用代码（如 CORS）一起改？
2. `APP_PORT` 在生产文档中是否彻底移除，避免误导继续端口直出？

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 采用 Dokploy 内置 Traefik | 用户已明确选择 1A |
| 单域名承载前后端与 API | 用户已明确选择 2A，且项目已内置 SPA fallback |
| 使用 Let's Encrypt | 用户已明确选择 3A |
| 关闭宿主机端口直出 | 用户已明确选择 4A |
| Host 路由规则 | 用户已明确选择 5A |
| 本次不改动应用代码（如 CORS） | 用户当前诉求是代理接入与部署路径改造，先完成最小落地 |
| 生产说明彻底移除 `APP_PORT` 用法 | 避免继续沿用端口直出的旧操作方式 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |

## Notes
- 聚焦落地最小改动：`docker-compose.prod.yml` + `README.md` + `DEPLOYMENT.md` + `docs/deployment.md`。
- Dokploy 控制台配置项放在文档中，不写死到仓库中的 Traefik labels（由平台托管）。

## Completion Summary
- **Status:** ✅ Complete (2026-02-23)
- **Deliverables:** `docker-compose.prod.yml`, `README.md`, `DEPLOYMENT.md`, `docs/deployment.md`
- **Notes:** 生产入口已切到 Traefik 域名模式；`APP_PORT` 仅保留为“禁用直出”的说明文本。
