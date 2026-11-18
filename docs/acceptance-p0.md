# P0 / M0 验收记录

**日期：** 2026-11-18（Asia/Shanghai）  
**范围：** 仅 P0，不代表 V1.0 业务功能或真实模型验收通过。  
**环境：** Windows 11 / JDK 17.0.1 / Maven 3.8.8 / Node 22.22.1 / Python 3.12.12 / PostgreSQL 17.6 / Compose V2 2.39.4。

## 验收结果

| 验收项 | 实际执行 | 结果 |
|---|---|---|
| 环境检查 | scripts/check-env.ps1 | 通过；Maven 实际使用 JDK 17 |
| Compose 解析 | docker compose config --quiet | 通过；未打印展开后的密钥配置 |
| PostgreSQL 就绪 | docker compose up -d --wait --wait-timeout 150 | healthy；仅绑定 127.0.0.1:5432 |
| Java 验证/打包 | mvn -f backend/pom.xml verify -B | BUILD SUCCESS；10 个子模块成功；6 tests，0 failures，0 errors |
| 数据库集成 | HealthIntegrationTest | PostgreSQL 17；Flyway V1 成功；platform_baseline=P0；Hibernate validate 已执行 |
| 前端干净安装 | npm ci --no-audit --no-fund | 成功，376 packages |
| 前端类型/lint | npm run typecheck / npm run lint | 通过 |
| 前端测试 | npm run test -- --run | 3 tests passed：加载/成功/失败 |
| 前端构建 | npm run build | 成功，dist/index.html 与 JS/CSS 产物 |
| Python 测试 | Python 3.12 虚拟环境 python -m pytest -q | 19 tests passed；健康、认证、配置、契约、状态、schema、环境脚本 |
| OpenAPI | openapi-spec-validator | public-api.yaml / ai-engine-api.yaml 均可解析并验证 |
| 实际启动 | scripts/start-dev.ps1 -SkipBuild | Java/FastAPI/Vite ready |
| 完整验收 | scripts/verify-p0.ps1 | 退出码 0；安装、全部测试、构建、重启、HTTP 均通过 |
| 应用停止/重启 | stop-dev.ps1 / start-dev.ps1 -SkipBuild | 应用拥有进程及子进程停止；重启成功，数据库卷保留 |
| 迁移幂等与持久化 | 重启前后 SQL 对比 | Flyway 仍只有 V1 一条成功记录；platform_baseline 含相同 created_at；日志报告 No migration necessary |
| PowerShell 脚本语法 | PowerShell Parser.ParseFile | 全部 .ps1 无解析错误 |
| Bash 脚本语法 | Git Bash bash -n | common/check-env/start-dev/stop-dev/verify-p0.sh 通过 |

## HTTP 实测（9 项）

| 请求 | 认证 | 结果 |
|---|---|---|
| Java GET /api/v1/health | 无 | 200，OK/backend/UP，实际数据库探测 |
| Vite GET / | 无 | 200 |
| Vite GET /api/v1/health | 无 | 200，代理访问 Java |
| Java GET /internal/v1/health | 正确 Token | 200 |
| Java GET /internal/v1/health | 缺失 Token | 401 |
| Java GET /internal/v1/health | 错误 Token | 401 |
| Python GET /internal/v1/health | 正确 Token | 200，OK/ai-engine/UP |
| Python GET /internal/v1/health | 缺失 Token | 401 |
| Python GET /internal/v1/health | 错误 Token | 401 |

统一响应为 `{code,message,data}`，认证失败为 UNAUTHORIZED/data=null。浏览器代码不读取内部 Token，也没有访问供应商的实现。Python 测试另验证受保护的未知内部路径、禁用 /docs、缺少/空 Token 配置拒绝、UUID/progress/sequence 的校验。

## 本机证据路径（已忽略，不提交）

- `.run/backend-red.log`：Java 骨架实现前，测试因没有 SpringBootConfiguration 失败。
- `.run/ai-red.log`：Python 健康/认证/schema 实现前因缺少模块失败。
- `.run/frontend-red.log`：修正测试配置后，页面与 API 缺失导致测试失败。
- `.run/backend-green.log`：Java 集成测试和完整构建通过。
- `.run/final-verification.log`：最终统一验收通过，含 6/3/19 测试与 HTTP 结果。
- `.run/http-checks.json`：9 项 URL、预期和实际状态，不包含 Token。
- `.run/database-before-restart.txt` / `.run/database-after-restart.txt`：迁移与基线记录相同。
- `.run/backend.log`、`.run/ai-engine.log`、`.run/frontend.log`：实际服务日志。
- `.tools/docker/compose.sha256`：Compose 官方 checksum；下载工具均为本地忽略文件。

## 自审与剩余限制

- 三端分层符合规范；P1 业务模块仅骨架，不实现项目/模型/媒体 CRUD。
- 任务/执行契约只有 schemas 与后续端点说明，无调度、执行、回报的假实现。
- PostgreSQL schema 不由 Hibernate 自动更新；首个迁移仅基础设施记录。
- .env、.tools、.run、虚拟环境、node_modules、target、storage 内容被忽略；真实供应商密钥未使用。
- Linux 仅语法检查，未完成 Linux 运行/迁移/测试链路，不标为实机通过。
- Vite 提示单个 bundle 超过 500 kB；P0 只有状态页面，暂保留，后续页面增加时拆包。
- 旧版 FastAPI 配套 Starlette 测试工具触发一条 anyio 弃用警告，不影响测试结果；没有未经确认随意升级核心技术。
- Git 分支为 chore/p0-bootstrap；已按用户提供的信息配置仓库本地提交身份，用户已授权提交并推送 P0 基线至 origin。提交与远端状态以 git log / git status 为准。
- 保留当前本地运行服务供检查：http://127.0.0.1:5173。用 stop-dev.ps1 停止，数据库卷不删除。
- 未配置 LLM/图像/视频/音频供应商；无真实付费调用。P1～P8 仍未开始。
