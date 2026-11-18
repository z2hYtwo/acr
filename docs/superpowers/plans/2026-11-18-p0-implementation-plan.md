# P0 工程初始化与启动验证 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking. 不使用并行 Agent，除非用户明确授权。

**Goal:** 仅交付 P0/M0：可复现环境、三端工程骨架、PostgreSQL 17、基础契约和真实启动验证。

**Architecture:** 浏览器只调用 Java；Java 是数据库唯一写入方；Python 提供认证的内部接口，不连接业务数据库。PostgreSQL 由 Compose 管理，Java 使用 Flyway 迁移与 JPA validate，三个应用在本机启动。

**Tech Stack:** JDK 17、Maven 3.8.8+、Spring Boot 3.5.x、PostgreSQL 17、React 19、TypeScript、Vite、Ant Design、Lucide React、React Router、Zustand、TanStack Query、Axios、Python 3.12、FastAPI、Pydantic Settings、HTTPX、Pytest、FFmpeg、Docker Compose V2。

**Spec:** `SRS-V1.0.MD`、四份 `AGENTS.md`、`docs/superpowers/plans/2026-11-18-ai-comic-studio-development-plan.md` 的 Task P0。

## Global Constraints

- Windows 11 优先，兼容 Linux；保持既定技术栈与顶层目录。
- 不进入 P1～P8；不实现项目 CRUD、模型调用、任务调度或生成流程。
- Python 不得绕过 Java 修改业务数据库；前端不直接调用 Python 或供应商。
- 内部接口必须认证；真实 `.env`、Token、供应商密钥不提交、不打印。
- Flyway 路径固定为 `backend/comic-boot/src/main/resources/db/migration/`；`ddl-auto=validate`。
- 状态固定为 PENDING、QUEUED、RUNNING、WAITING、RETRYING、REVIEWING、SUCCEEDED、FAILED、CANCELLED。
- 长任务契约仅定义接受语义，不建立阻塞式生成 API。
- 所有自动化测试不得产生付费模型调用；无模型密钥仍可启动。
- 不修改截断的根 AGENTS.md，不补写推测的规范。
- 没有 Git，确认前不初始化、不提交；确认初始化后使用 `chore/p0-bootstrap` 分支。

## 0. 实际环境检查（2026-11-18）

| 工具 | 实测 | 处置 |
|---|---|---|
| JDK | PATH 为 17.0.1；javac 存在 | 启动/验证脚本显式核对 JDK 17 |
| Maven | 3.8.8；JAVA_HOME 指向 JDK 21.0.2 | 仅进程级设置 JAVA_HOME 到现有 JDK 17，不改全局 |
| Node / npm | 22.22.1 / 11.12.1 | 满足初始化要求；Windows 使用 npm.cmd |
| Python | 默认 3.13.11；py 登记的 3.12 路径 E:/python/python.exe 不存在 | 确认后安装项目本地 Python 3.12 并创建 ai-engine/.venv，不用 3.13 替代 |
| Docker | CLI/引擎 29.2.1，可访问 Linux 引擎 | 使用现有引擎 |
| Compose | docker compose version 失败；Docker 安装目录未找到插件 | 确认后下载官方 Compose V2 至项目本地工具目录，脚本通过 DOCKER_CONFIG 加载，不覆盖用户配置 |
| FFmpeg | 8.1 essentials | 仅核对工具，不执行媒体生产 |
| Git | 工具存在；项目无 .git | 等待初始化方案确认 |
| 端口 | 检查时 5173/8080/8000/5432 未发现监听 | 启动前再次检查 |

**已确认：** 用户同意现有截断规范作为本次基线、项目本地补齐 Python/Compose 并初始化 Git。供应商能力清单本阶段标记“未配置/未验证”，不假定真实供应商能力。

## Task 1：配置、依赖与测试入口

**Files:** `.gitignore`、`.env.example`、`docker-compose.yml`、`scripts/check-env.ps1`、`scripts/check-env.sh`、`README.md`、`docs/environment-p0.md`。

**Interfaces:** PostgreSQL `127.0.0.1:5432`；Java `127.0.0.1:8080`；AI `127.0.0.1:8000`；Vite `127.0.0.1:5173`。环境项至少包含数据库用户/密码/名称、内部 Token、AI 地址和 STORAGE_ROOT。

- [x] 获得边界确认；按确认范围补齐本地工具，不覆盖全局配置。
- [x] 初始化 Git、设置安全忽略规则和工作分支；未配置提交身份时先报告，不擅设身份。
- [x] 固定实际可下载的依赖版本，并记录补丁版本选择。
- [x] Compose 使用 PostgreSQL 17 固定标签、持久卷、pg_isready 健康检查、loopback 端口绑定。
- [x] 创建本地 `.env` 时生成随机开发 Token/密码；不使用真实模型密钥。
- [x] 执行环境脚本、`docker compose config --quiet` 和数据库 readiness 检查；不输出展开后的密钥配置。

## Task 2：跨服务基础契约

**Files:** `contracts/public-api.yaml`、`contracts/ai-engine-api.yaml`、`contracts/README.md`、`ai-engine/tests/test_contracts.py`、`frontend/src/types/api.ts`、`frontend/src/types/task.ts`、`ai-engine/app/schemas/common.py`、`ai-engine/app/schemas/task.py`、`backend/comic-common/src/main/java/com/comicstudio/common/ApiResponse.java`、`backend/comic-common/src/main/java/com/comicstudio/common/TaskStatus.java`。

**Interfaces:** 响应 `{code,message,data}`；UUID 字符串；UTC ISO8601；`GET /api/v1/health`；`GET /internal/v1/health`，内部统一 `Authorization: Bearer <token>`。任务请求字段按项目计划第 4 节定义。

- [x] 先写契约解析、状态枚举一致性与健康响应断言，确认缺少契约/实现导致失败。
- [x] 写 OpenAPI 契约，明确 200/401/403/422/500 的响应与错误码。
- [x] 定义任务、执行请求、回报与分页等基础 schemas；P1/P2 端点标记“规划，P0 未实现”，不伪造已可用接口。
- [x] 同步 Java/TypeScript/Pydantic 的响应与状态；运行 OpenAPI 校验器和字段一致性测试。

## Task 3：Java 多模块与真实 PostgreSQL 迁移

**Files:** `backend/pom.xml`；`backend/comic-{boot,common,project,story,script,storyboard,asset,generation,task,model}/pom.xml`；`backend/comic-boot/src/main/java/com/comicstudio/ComicStudioApplication.java`；`backend/comic-boot/src/main/java/com/comicstudio/config/InternalAuthFilter.java`；`backend/comic-boot/src/main/java/com/comicstudio/health/HealthController.java`；`backend/comic-boot/src/main/resources/application.yml`；`backend/comic-boot/src/main/resources/db/migration/V1__platform_baseline.sql`；`backend/comic-boot/src/test/java/com/comicstudio/HealthIntegrationTest.java`；`database/schema.md`。

**Interfaces:** 公共健康接口与认证内部健康接口返回统一响应。首个迁移只建立基础设施版本记录，不提前建立 P1/P2 业务表。

- [x] 建立 Maven 测试配置，先写健康响应、无 Token/错误 Token 拒绝访问测试并观察失败。
- [x] 建立所有规定 Maven 模块；业务模块为空骨架，避免提前实现功能。
- [x] 实现最小健康 Controller、统一响应和内部认证；Actuator 不暴露敏感详情。
- [x] 建立 Flyway 基线和对应 JPA 映射，使用 validate。
- [x] PostgreSQL 集成测试验证迁移、健康与鉴权，不以 H2 替代。
- [x] 执行 `mvn -f backend/pom.xml verify`，确认 Surefire/Failsafe 实际执行测试及迁移；记录数据库版本和 flyway_schema_history。

## Task 4：FastAPI 最小认证服务

**Files:** `ai-engine/requirements.txt`、`ai-engine/requirements-dev.txt`、`ai-engine/pytest.ini`、`ai-engine/main.py`、`ai-engine/app/core/config.py`、`ai-engine/app/core/auth.py`、`ai-engine/app/api/health.py`、`ai-engine/tests/test_health.py`。

**Interfaces:** `GET /internal/v1/health`；无供应商配置可启动；内部 Token 缺失配置时明确拒绝启动，不能隐式关闭认证。

- [x] Python 3.12 虚拟环境安装固定依赖。
- [x] 先写合法/缺失/错误 Token、无供应商配置启动的 Pytest；确认失败原因。
- [x] 使用 Pydantic Settings 独立管理配置，使用常量时间比较校验 Token。
- [x] 健康路由与鉴权分离，main.py 只装配应用；异常保持统一响应。
- [x] 执行 `python -m pytest`，包含契约校验；不引入数据库客户端和真实供应商调用。

## Task 5：React 工程空壳

**Files:** `frontend/package.json`、`frontend/package-lock.json`、`frontend/index.html`、`frontend/tsconfig.json`、`frontend/vite.config.ts`、`frontend/eslint.config.js`、`frontend/src/main.tsx`、`frontend/src/App.tsx`、`frontend/src/api/request.ts`、`frontend/src/api/health.ts`、`frontend/src/pages/dashboard/HealthPage.tsx`、`frontend/src/test/setup.ts`、`frontend/src/pages/dashboard/HealthPage.test.tsx`。

**Interfaces:** Axios 仅调用相对路径 `/api/v1/health`；Vite 将 `/api` 代理至 Java；浏览器不持有内部 Token。

- [x] 固定 React 19 和规定配套依赖、Vitest/Testing Library，生成 lockfile。
- [x] 先写页面加载、成功、失败状态测试，观察失败。
- [x] 创建 Router/QueryClient 装配与最小服务状态页面，不做项目管理界面。
- [x] 执行 `npm ci`、`npm run typecheck`、`npm run lint`、`npm run test -- --run`、`npm run build`。

## Task 6：启动脚本与 M0 验收证据

**Files:** `scripts/start-dev.ps1`、`scripts/start-dev.sh`、`scripts/stop-dev.ps1`、`scripts/stop-dev.sh`、`scripts/verify-p0.ps1`、`scripts/verify-p0.sh`、`docs/acceptance-p0.md`、`README.md`。

**Interfaces:** 从项目根执行；日志/PID 放忽略的运行目录；只终止本次脚本拥有的进程；不删除数据库卷。Windows 所有后台 Start-Process 使用 `-WindowStyle Hidden`。

- [x] 启动先检查版本和端口，读取本地环境；数据库 ready 后再启动 Java，并等待 HTTP ready，而不是固定 sleep。
- [x] 启动 Python/前端，分别等待健康或页面响应；失败显示脱敏日志并清理本次进程。
- [x] 验证 Java 公共健康、Java/Python 内部正确 Token、缺失及错误 Token；通过 Vite 代理访问 Java。
- [x] 重启 Java 验证 Flyway 不重复执行、JPA validate 成功、数据库记录保留。
- [x] 汇总所有命令、测试数量、HTTP 状态、实际版本与产物路径；未执行的 Linux 验证明确标注未验证。
- [x] 自审契约、配置和密钥忽略规则，更新项目计划中 P0 真实完成的勾选项。
- [ ] 提交：Git 身份已由用户提供并配置，已获提交和推送授权；提交成功后以 Git 历史确认。P1～P8 仍未开始。

## 当前状态

用户已确认边界；Task 1～6 的工程交付与 Windows 启动验证已完成。Java 6、前端 3、Python 19 项测试通过，9 项 HTTP 检查通过，应用重启持久化检查通过。验收见 docs/acceptance-p0.md。Git 提交身份已配置，用户已授权保存并推送 P0 基线；Linux 仅做脚本语法检查，未做实机运行。
