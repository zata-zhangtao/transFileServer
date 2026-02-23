# Findings & Decisions

## Requirements
- 用户要求执行实际修改，不只是 PRD。
- 使用 `planning-with-files` 技能管理复杂多文件改造。
- 目标是 Dokploy + 内置 Traefik 代理接入（单域名 HTTPS）。

## Confirmed Choices
- 1A: 仅用 Dokploy 内置 Traefik
- 2A: 前后端共用一个域名
- 3A: Let's Encrypt 自动签发
- 4A: 关闭宿主机端口直出
- 5A: Host 路由

## Research Findings
- 当前生产 compose 仍有 `ports: "${APP_PORT:-8000}:8000"` 直出。
- 后端已提供 `/healthz`，适合用域名健康检查。
- 项目已是单镜像架构，适合 Traefik 同域反代。
- CI 已支持 `PROD_HEALTHCHECK_URL`，只需更新 Secret 值到域名。

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 从生产 compose 中移除 `ports` | 满足“仅通过 Traefik 暴露”安全目标 |
| 使用 `expose: ["8000"]` 明确内部端口 | 提升可读性与部署语义 |
| 文档统一改为域名入口 | 避免继续使用 `server:port` 的误配置 |
| 暂不改 workflow 逻辑 | 现有 deploy hook + healthcheck 机制已满足需求 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| 无 | - |

## Resources
- tasks/prd-dokploy-traefik-proxy.md
- docker-compose.prod.yml
- README.md
- DEPLOYMENT.md
- docs/deployment.md

## Additional Discovery (2026-02-23)
- `docker-compose.prod.yml` 仍包含 `APP_PORT` 直出，需要移除。
- README/DEPLOYMENT/docs 部署命令仍展示 `APP_PORT`，需改为 Traefik 域名入口。
- DEPLOYMENT 文档中的 Dokploy 配置需从“反向代理提示”升级为“Traefik 必选配置步骤”。

## Implementation Findings (2026-02-23)
- 已将生产 compose 改为内部 `expose: 8000`，不再对宿主机公开 `8000`。
- README 已改为域名访问示例（`https://<your-domain>`）。
- `DEPLOYMENT.md` 已补充 Dokploy Traefik 必配项：Host 路由、Let's Encrypt、目标端口 `8000`。
- `docs/deployment.md` 已同步英文部署手册并加入 Traefik 生产要求。
- `docker compose -f docker-compose.prod.yml config` 可解析通过（仅有 `version` 字段弃用 warning）。
