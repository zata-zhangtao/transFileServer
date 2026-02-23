# Findings & Decisions

## Requirements
- 读取 `tasks/prd-dokploy-cicd-single-image.md` 并完成其中落地任务。
- 实现单镜像（前后端合并）部署形态。
- 增加 GitHub Actions：PR 校验、main push 构建推送并触发 Dokploy 部署。
- 增加 `/healthz` 健康检查并在部署后验证。
- 更新文档并明确用户需要配置的项目项（Secrets、Dokploy 配置）。

## Research Findings
- 项目已有 `Dockerfile`、`docker-compose.prod.yml`、`build-and-push*.sh`，但当前仍是双镜像思路。
- 仓库尚无 `.github/workflows`。
- `main.py` 当前没有 `/healthz`，也没有静态页面挂载逻辑。
- `frontend/src/App.tsx` 通过 `REACT_APP_API_URL` 访问 API，默认 `http://localhost:8000`。
- 代码库未找到 `relay` 路由实现（仅 PRD 提到），当前可验证的是上传/分片/下载/列表/删除。
- 当前仓库已有 `.gitignore` 和 `tasks/prd-dokploy-cicd-single-image.md` 的 staged 变更，不属于本次任务新增。

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 在 `main.py` 内直接托管 `frontend/build` 静态资源 | 避免新增反向代理组件，保持单容器结构 |
| CI 使用 jobs: validate -> build_and_push -> deploy | 日志阶段清晰，满足 PRD 可定位失败阶段要求 |
| deploy 后健康检查采用可选 secret `PROD_HEALTHCHECK_URL` | 兼容不同域名/端口环境，不硬编码 URL |
| `docker-compose.prod.yml` 使用 `DOCKERHUB_USERNAME` + `APP_IMAGE_TAG` | 便于 Dokploy 切换 `latest` 与回滚 tag |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
|       |            |
| frontend/build 目录权限导致 npm build 失败 | 使用 `BUILD_PATH=build-ci` 规避目录权限问题 |
| 本机 Docker daemon 不可用 | 无法做镜像实构，保留 CI 中 docker build 作为门禁 |

## Resources
- tasks/prd-dokploy-cicd-single-image.md
- main.py
- Dockerfile
- docker-compose.prod.yml

## Visual/Browser Findings
- 无
