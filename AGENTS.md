# AI Comic Studio — 全局 Agent 开发规范

> 本文件是 AI Comic Studio 项目的最高级别开发规范。
>
> 所有参与本项目开发的 AI 编程 Agent 必须优先阅读并遵守本文件。
>
> 项目名称：AI Comic Studio
> 项目版本：V1.0
> 项目类型：AI 漫剧自动化生产平台
> 架构模式：Monorepo + 模块化后端 + 独立 AI 引擎
> 部署模式：本地部署 + 云端 AI 模型调用

---

# 1. 项目目标

AI Comic Studio 是一个基于大语言模型和多模态 AI 技术的个人漫剧自动化生产平台。

系统目标是将用户的故事创意转换为完整的漫剧视频，实现从内容创作到最终成片导出的自动化生产流程。

核心业务流程：

1. 故事输入与分析。
2. 剧本生成。
3. 角色与场景提取。
4. 角色和场景资产管理。
5. 分镜生成。
6. 图像生成。
7. 视频生成。
8. 语音合成。
9. 音效和背景音乐处理。
10. 视频剪辑与合成。
11. 成片质量检查与导出。

系统应支持各生产阶段独立执行、结果审核、内容修改和重新生成。

# 2. 全局技术栈

未经用户明确批准，不得擅自替换核心技术。

| 层级 | 技术 |
|---|---|
| 前端 | React 19、TypeScript、Vite |
| UI | Ant Design、Lucide React |
| 状态管理 | Zustand、TanStack Query |
| 后端 | JDK 17、Spring Boot 3.5.x |
| 构建 | Maven |
| 持久化 | Spring Data JPA |
| 数据库 | PostgreSQL 17 |
| 数据库迁移 | Flyway |
| AI 引擎 | Python 3.12、FastAPI |
| 数据校验 | Pydantic |
| HTTP 通信 | Axios、HTTPX、Spring RestClient |
| 媒体处理 | FFmpeg |
| 容器管理 | Docker Compose V2 |

具体依赖版本应以仓库现有配置为准，不得在未检查的情况下随意升级。

# 3. 全局架构

系统采用前后端分离、Java 业务管理与 Python AI 执行分离的架构。

```text
React Frontend
      |
      v
Java Spring Boot
      |
      +-----------> PostgreSQL
      |
      v
Python FastAPI
      |
      +-----------> LLM API
      |
      +-----------> Image API
      |
      +-----------> Video API
      |
      +-----------> Audio API
      |
      v
Generation Results
      |
      v
Java Persistence
```

## 3.1 Java 后端职责

Java 是系统业务数据的唯一权威管理方，负责：

- 项目和剧集管理。
- 故事、剧本和分镜管理。
- 角色与场景资产管理。
- 模型配置管理。
- AI 生成任务管理。
- 任务状态和执行日志管理。
- 业务数据持久化。
- AI Engine 通信。
- 生成结果登记和管理。

## 3.2 Python AI 引擎职责

Python 负责：

- LLM 调用。
- Prompt 管理。
- AI 工作流编排。
- 故事分析。
- 剧本生成。
- 分镜生成。
- 图像、视频、音频生成适配。
- AI 输出解析和校验。
- AI 执行日志。

Python 不得绕过 Java 修改业务数据库。

## 3.3 React 前端职责

React 负责：

- 页面展示。
- 用户交互。
- 项目和剧集管理界面。
- 故事、剧本和分镜编辑。
- 角色与场景资产展示。
- 生成任务管理界面。
- 生成结果预览。
- 人工审核和修改。

前端不得直接调用需要保密的模型供应商 API。

# 4. 项目目录约束

```text
ai-comic-studio/
├── frontend/
├── backend/
├── ai-engine/
├── contracts/
├── database/
├── storage/
├── scripts/
├── docs/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── AGENTS.md
└── README.md
```

目录职责：

- frontend：前端工程。
- backend：Java 业务后端。
- ai-engine：Python AI 引擎。
- contracts：跨服务接口契约。
- database：数据库初始化及设计参考。
- storage：媒体文件存储。
- scripts：开发和启动脚本。
- docs：项目技术文档。

不得随意改变顶层目录结构。

新增顶层模块必须说明必要性和影响范围。

# 5. 跨模块开发约束

所有跨模块通信必须通过明确的接口和数据契约完成。

禁止：

- 前端直接访问数据库。
- Python 直接操作 Java 业务表。
- Java 在内部直接耦合某个模型供应商的实现。
- 将所有 AI 工作流放进一个巨型 Service。
- 在多个模块中重复实现同一业务逻辑。
- 未经评估修改已有接口的数据结构。

跨模块接口发生变化时，必须同步检查调用方和相关契约。

# 6. 任务管理约束

所有 AI 生成任务必须具备：

- 唯一任务编号。
- 任务类型。
- 任务状态。
- 输入参数。
- 输出结果。
- 创建时间。
- 开始时间。
- 结束时间。
- 错误信息。
- 执行日志。
- 重试记录。

任务状态：

PENDING、QUEUED、RUNNING、WAITING、RETRYING、REVIEWING、SUCCEEDED、FAILED、CANCELLED。

任务执行必须考虑：

- 幂等性。
- 重复执行控制。
- 超时处理。
- 失败重试。
- 任务取消。
- 执行心跳。
- 任务中断恢复。

长时间运行的图像和视频生成不得使用阻塞式 HTTP 请求等待结果。

Java 负责任务状态持久化，Python 负责 AI 执行。

# 7. AI 工作流约束

漫剧生产流程必须拆分为独立工作流。

```text
故事分析
   |
   v
剧本生成
   |
   v
角色与场景提取
   |
   v
资产生成
   |
   v
分镜生成
   |
   v
图像生成
   |
   v
视频生成
   |
   v
音频生成
   |
   v
视频合成
   |
   v
成片导出
```

每个工作流必须具备：

- 明确输入。
- 明确输出。
- 结构化数据。
- Prompt 版本。
- 模型配置。
- 执行日志。
- 异常处理。
- 输出校验。
- 必要的重试机制。

不得将整个生产流程简化成单个 Prompt。

# 8. 数据库规范

PostgreSQL 是核心业务数据库。

- Java 负责业务数据持久化。
- Flyway 负责数据库版本迁移。
- 禁止使用 Hibernate 自动更新数据库结构。
- 禁止修改已经执行过的迁移文件。
- 数据库变更必须创建新的 Flyway Migration。
- 大型图片、视频和音频不得直接存储在数据库中。
- 业务表必须考虑主键、外键、索引和数据完整性。

Flyway 迁移文件统一存放于：

backend/comic-boot/src/main/resources/db/migration/

# 9. 安全规范

- 禁止将真实 `.env` 提交到 Git。
- 禁止硬编码 API Key。
- 禁止将模型密钥暴露给前端。
- 内部服务通信必须认证。
- 文件上传必须校验类型和大小。
- 文件操作必须防止路径穿越。
- 日志不得泄露密钥。
- AI 输出必须经过验证，不得直接作为可信业务指令执行。

# 10. Agent 开发工作流程

每次执行开发任务，必须遵循以下流程。

## 第一步：理解

- 阅读根目录 AGENTS.md。
- 阅读目标模块 AGENTS.md。
- 检查当前