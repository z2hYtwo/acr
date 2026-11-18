# AI Comic Studio — P0 工程基线

本仓库目前仅实现 **P0/M0**：三端骨架、PostgreSQL、基础响应/任务契约、健康检查和内部认证。没有项目 CRUD、任务调度、供应商模型调用或漫剧生成能力。

## 技术与默认端口

| 服务 | 技术 | 地址 |
|---|---|---|
| 前端 | React 19.1.0 / TypeScript 5.8.3 / Vite 6.3.5 | http://127.0.0.1:5173 |
| Java | JDK 17 / Maven 3.8.8+ / Spring Boot 3.5.7 | http://127.0.0.1:8080 |
| AI Engine | Python 3.12.12 / FastAPI 0.115.12 / Pydantic 2.11.4 | http://127.0.0.1:8000 |
| 数据库 | PostgreSQL 17.6 / Compose V2 | 127.0.0.1:5432 |

所有服务仅绑定 loopback；不适合直接暴露公网。前端仅通过 Vite 的 `/api` 代理调用 Java，不携带内部 Token，也不直接访问 Python。Java 是数据库唯一管理方。

## Windows 11 快速启动

需要已安装 JDK 17、Maven 3.8.8+、Node 22/24 LTS、Docker Desktop（Linux 引擎）、FFmpeg 和一个可运行的 Python（用于本地工具引导）。

从项目根运行：

```powershell
# 首次安装本地 Python 3.12、Compose V2，生成随机开发配置
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap-local.ps1
# 检查环境；JAVA_HOME 错指向 21 时尝试使用 PATH 中的 JDK 17
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-env.ps1
# 首次依赖下载/构建，再启动数据库和三端
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start-dev.ps1
# 后续已构建工程可加 -SkipBuild
# 完整测试 + 重启 + HTTP 验收（会停止本工程记录的应用进程后重新启动）
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-p0.ps1
# 停止应用，保留数据库和卷
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stop-dev.ps1
# 同时停止数据库（不删卷）：加 -StopDatabase
```

若 JDK 未在 PATH：在当前 PowerShell 设置 `$env:ACS_JAVA_HOME='你的 JDK 17 目录'`。脚本只修正进程环境，不修改系统 JAVA_HOME。

工具下载位于 `.tools/`（已忽略）；Compose V2 2.39.4 来自官方 GitHub release 并校验 SHA256。为保持现有 Docker context 可用，本地工具配置复制用户 Docker config/contexts，不写回用户配置；这些本地副本同样忽略。

首次下载失败可以重试 bootstrap；已有 `.env` 不覆盖。默认开发密码和 Token 使用随机值，**无需真实模型 API Key**。不要使用 `.env.example` 中的占位符启动。

## Linux 启动（脚本已做语法检查，尚未实机验收）

安装 JDK 17、Maven 3.8.8+、Node 22/24、Python 3.12、Docker Compose V2、FFmpeg、curl、iproute2（ss）、procps（ps）。

```bash
cp .env.example .env
# 编辑 .env，将两个 replace-with-* 占位符改成独立随机值，例如 openssl rand -hex 32
python3.12 -m venv ai-engine/.venv
ai-engine/.venv/bin/python -m pip install -r ai-engine/requirements-lock.txt
bash scripts/check-env.sh
bash scripts/start-dev.sh
bash scripts/verify-p0.sh
bash scripts/stop-dev.sh
```

`.env` 使用简单的 `KEY=value`，不加引号，不写 shell 表达式；路径包含空格也按字面读取。启动脚本等待 PostgreSQL 健康和 HTTP ready，不以固定 sleep 或启动顺序代替就绪检查。应用后台日志及进程记录位于 `.run/`；停止脚本核对 PID 创建时间，避免误杀复用 PID，不删除媒体或数据库卷。

## 配置说明

| 变量 | 用途 |
|---|---|
| POSTGRES_DB / POSTGRES_USER / POSTGRES_PASSWORD | Compose 数据库与 Java 连接配置；密码仅本地注入 |
| DB_PORT | 数据库宿主端口，默认 5432 |
| BACKEND_PORT / AI_ENGINE_PORT / FRONTEND_PORT | 默认 8080 / 8000 / 5173；端口被占用则启动失败 |
| AI_ENGINE_TOKEN | Java/Python 内部 Bearer Token；缺失/空值不允许启动 |
| AI_ENGINE_BASE_URL | 后续 Java RestClient 使用的 AI 地址，默认 http://127.0.0.1:8000；P0 无生成调用 |
| STORAGE_ROOT | Python 媒体存储根，默认 ../storage（从 ai-engine 运行）；P0 不生成文件 |

已有数据库卷初始化后，修改 POSTGRES_* 不会自动修改数据库用户/密码。不要为修正配置删除卷；后续按数据库管理流程处理。

供应商能力清单：LLM / 图像 / 视频 / 音频均 **未配置、未验证**，P0 不接入、不付费调用、不假设供应商能力。相关 Adapter 和模型配置属于后续阶段。

## 契约与测试

- [公共 API](contracts/public-api.yaml)、[内部 AI API](contracts/ai-engine-api.yaml)、[契约说明](contracts/README.md)。仅 OpenAPI `paths` 内的健康端点已实现；任务/执行 schemas 是后续基线。
- Java `GET /api/v1/health` 实际检查数据库；Java/Python `GET /internal/v1/health` 必须带 `Authorization: Bearer <AI_ENGINE_TOKEN>`。无/错误 Token 均返回 401。
- 统一响应 `{code,message,data}`；内部 Token 不进入前端构建。
- 十个 Maven 模块：comic-common、project、story、script、storyboard、asset、generation、task、model、boot；业务模块暂为空骨架。
- Flyway 基线位于规定目录；`ddl-auto=validate`，数据库定义见 [schema.md](database/schema.md)。不使用 H2 冒充 PostgreSQL 验证。
- Python 直接依赖在 requirements*.txt，完整版本在 requirements-lock.txt；前端用 package-lock.json，后端依赖由固定 Spring Boot BOM 管理。

单独验证（先加载 `.env` 并使用 JDK 17）：

```powershell
. ./scripts/common.ps1
Import-LocalEnvironment
Set-ToolEnvironment
docker compose config --quiet
docker compose up -d --wait --wait-timeout 150
mvn.cmd -f backend/pom.xml verify
Push-Location frontend
npm.cmd ci
npm.cmd run typecheck
npm.cmd run lint
npm.cmd run test -- --run
npm.cmd run build
Pop-Location
Push-Location ai-engine
./.venv/Scripts/python.exe -m pytest -q
Pop-Location
```

Windows 在 Vite 运行时执行 `npm ci` 会因 esbuild.exe 被占用而失败；完整验收脚本会先停止本工程进程再安装/测试，之后重新启动。不要通过关闭无关项目进程处理锁文件。

## 证据与限制

实际验收见 [docs/acceptance-p0.md](docs/acceptance-p0.md)，环境记录见 [docs/environment-p0.md](docs/environment-p0.md)。运行日志 `.run/` 为本机证据，不提交真实配置；持久卷不随应用停止删除。

根 AGENTS.md 在第 10 节截断：已获用户同意以现有文件为基线，本阶段不补写或修改。此次只做 P0，不代表 V1.0 产品验收通过。
