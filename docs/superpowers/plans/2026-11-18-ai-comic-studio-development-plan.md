# AI Comic Studio V1.0 开发安排 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. 本文是项目级开发安排；每个阶段执行前，应拆出对应子系统的文件级实施计划，经确认后再编码。选择并行 Agent 执行须由用户明确授权。

**Goal:** 从现有需求与规范目录建设本地漫剧生产平台，以一篇短篇故事完成一集 30～60 秒动态漫，支持阶段审核、单镜头重试和重启恢复。

**Architecture:** React 只调用 Java 业务接口；Java 是业务数据、任务状态与生成结果的唯一权威管理方；Python 通过独立 Workflow 和供应商 Adapter 执行 AI 与媒体处理。PostgreSQL 存业务和任务信息，本地 storage 存媒体文件，使用持久化任务、租约和幂等控制保证恢复能力。

**Tech Stack:** React 19 / TypeScript / Vite / Ant Design / Lucide React / React Router / Zustand / TanStack Query / Axios；JDK 17 / Spring Boot 3.5.x / Maven 3.8.8+ / Spring Data JPA / Flyway / Spring RestClient；PostgreSQL 17；Python 3.12 / FastAPI / Pydantic / HTTPX / Pytest / Tenacity；FFmpeg；Docker Compose V2。

**Spec:** `SRS-V1.0.MD`、`AGENTS.md`、`frontend/AGENTS.md`、`backend/AGENTS.md`、`ai-engine/AGENTS.md`。

## Global Constraints

- 产品形态：本地部署、个人使用、浏览器访问。
- 操作系统：Windows 11优先，兼容Linux。
- 不实现注册、组织、角色权限和多人协作。
- 未经用户明确批准，不得擅自替换核心技术。
- Python 不得绕过 Java 修改业务数据库。
- 前端不得直接调用需要保密的模型供应商 API。
- 状态枚举固定：PENDING、QUEUED、RUNNING、WAITING、RETRYING、REVIEWING、SUCCEEDED、FAILED、CANCELLED。
- 长时间运行的图像和视频生成不得使用阻塞式 HTTP 请求等待结果。
- Flyway 迁移目录：backend/comic-boot/src/main/resources/db/migration/。
- JPA 使用 ddl-auto=validate；禁止修改已执行的迁移文件。
- API密钥不得明文存储在业务数据库或日志中。
- 内部服务通信必须认证；文件上传必须校验类型和大小；文件操作必须防止路径穿越。
- 普通业务接口在本地环境下以P95响应时间不超过1秒为初步目标，不包含AI模型推理和文件上传下载时间。
- 外部模型 API 使用 Mock，不应在普通自动化测试中产生真实付费调用。
- 不擅自引入消息队列、分布式架构或大型 AI 框架；不建设专业级非线性编辑器。

## 1. 当前目录与启动条件

2026-11-18 检查结果：实际只有根目录的 `AGENTS.md`、`SRS-V1.0.MD` 和 frontend、backend、ai-engine 下各一份 `AGENTS.md`。没有源码、pom.xml、package.json、requirements.txt、数据库迁移或启动脚本；当前目录不是 Git 仓库。

根目录 `AGENTS.md` 在第 10 节“检查当前”处截断。启动前由项目所有者确认其是否为完整规范，不在本次安排中擅自修改。IDE 中显示的另一份根级 SRS 不在本次磁盘检查结果中；本计划以 `ai-comic-studio/SRS-V1.0.MD` 为基线。

因此阶段状态均为“未开始”，不能把规范中推荐的目录当成已完成的工程。确切依赖补丁版本在初始化阶段固定并记录锁文件；供应商能力、额度、价格和付费联调条件在接入前确认。

## 2. 排期假设与里程碑

以下按 1 名全栈开发者、每周 5 个有效开发日估算，前后端和 AI 工作量串行计算；不是承诺完成日期。人日包含编码、测试和基础联调，不包含外部供应商审批或长时间限流等待。另保留 5～10 人日风险缓冲。

| 阶段 | 工作内容 | 预计人日 | 完成门槛 |
|---|---|---:|---|
| P0 | 工程、契约、安全配置与健康检查 | 3～4 | 三服务可启动，数据库迁移和内部鉴权通过 |
| P1 | 项目/剧集/存储/模型配置 | 4～5 | 浏览器创建项目并安全管理配置与文件 |
| P2 | 持久化任务执行骨架 | 5～7 | Mock 任务异步运行，重复提交、重试、取消、重启可验证 |
| P3 | 故事解析和分析 | 4～5 | TXT/DOCX/PDF/文本导入，结构化结果可修订 |
| P4 | 大纲、分集、剧本和版本 | 4～5 | 单集剧本可生成、编辑、审核和重新生成 |
| P5 | 角色/场景资产与分镜 | 5～6 | 参考资产复用，镜头编辑、排序和版本可用 |
| P6 | 图像与视频生成 | 6～8 | 候选图审核，异步视频任务，单镜头独立重试 |
| P7 | 配音、音效、音乐和合成 | 5～7 | 字幕、音画时长、混音与 MP4 导出通过 |
| P8 | 恢复演练、安全、性能和最终验收 | 4～5 | 真实供应商 30～60 秒成片及全部验收项通过 |
| 合计 | 不含风险缓冲 | 40～52 | 约 8～10.5 个工作周 |

若有前端、后端、AI 三名开发者，可在每阶段契约确认后分别开发；不能直接将总工期除以三。P2、供应商适配及最终联调仍在关键路径。

**里程碑：** M0=P0 工程可运行；M1=P4 文本创作闭环；M2=P6 视觉生产闭环；M3=P7 Mock 成片闭环；M4=P8 真实成片与恢复验收。

## 3. 目录落位与职责分工

以下均为计划新增路径；保留现有顶层布局，不移动需求或规范。

| 目录/文件 | 负责人角色 | 职责 |
|---|---|---|
| `contracts/public-api.yaml` | 后端牵头，前端评审 | 前端→Java 的 OpenAPI、分页、错误码与 DTO |
| `contracts/ai-engine-api.yaml` | 后端/AI 共同确认 | Java→Python 提交/查询/取消任务，Python→Java 事件 |
| `contracts/schemas/` | 后端/AI | 工作流输入输出、状态与生成结果 JSON Schema |
| `backend/pom.xml`、`backend/comic-boot/` | 后端 | Maven 聚合、服务启动、配置与 Flyway |
| `backend/comic-common/` | 后端 | ApiResponse、异常、公共类型 |
| `backend/comic-project/`、`comic-story/`、`comic-script/` | 后端 | 项目剧集、故事及剧本版本 |
| `backend/comic-storyboard/`、`comic-asset/` | 后端 | 镜头、角色场景、文件元数据和版本 |
| `backend/comic-task/`、`comic-generation/`、`comic-model/` | 后端 | 持久化调度、生成协调、模型能力与密钥引用 |
| `frontend/src/api/`、`types/` | 前端 | Axios 和跨层 DTO；服务端数据交给 TanStack Query |
| `frontend/src/pages/`、`components/`、`router/`、`stores/` | 前端 | 页面、媒体预览、路由与客户端 UI 状态 |
| `ai-engine/app/api/`、`schemas/`、`core/` | AI | 内部接口、校验、认证和日志 |
| `ai-engine/app/adapters/` | AI | llm/image/video/audio 供应商能力封装 |
| `ai-engine/app/workflows/`、`workers/` | AI | 独立工作流和执行，不直连业务数据库 |
| `ai-engine/prompts/`、`tests/` | AI | Prompt 版本、单元与接口测试 |
| `database/schema.md` | 后端 | ER 设计参考；实际变更只使用 Flyway |
| `storage/` | 后端/AI | 媒体、临时文件和产物，真实文件不入 Git |
| `scripts/`、`docker-compose.yml`、`.env.example` | 集成负责人 | Windows/Linux 启动、健康检查与安全配置示例 |
| `docs/`、`README.md` | 各模块负责人 | 决策、接口、运行、备份、验收资料 |

后端依赖方向：业务模块依赖 comic-common；comic-generation 协调业务、task 和 model；comic-task 不反向依赖 generation；comic-boot 装配各模块。调度通过 task 层接口注册执行器，避免循环 Maven 依赖。

## 4. 开发前必须冻结的接口与数据规则

以下为实施建议，尚不是已实现接口。P0 确认后形成正式契约。

- 业务 API 前缀 `/api/v1`，响应 `{code,message,data}`；HTTP 状态与错误语义一致。分页参数 `page`（从 0 开始）、`size`（1～100），响应含 `items,total,page,size`。
- Java 中主键用 UUID，跨服务统一字符串；时间用 ISO 8601 UTC，前端按本地时区显示。
- 基础对象：Project、Episode、StoryDocument/StoryAnalysisVersion、ScriptVersion、StoryboardVersion/Shot、Character/Scene/AssetVersion、MediaFile、ModelProvider/ModelConfig、GenerationTask、TaskAttempt、TaskLog、GenerationResult。
- 已审核内容及已选媒体不可被重新生成静默覆盖；结果用不可变版本保存，当前选定版本单独引用。删除项目需确认并清理关联记录与未共享文件，失败清理可重试。
- 任务创建 `POST /api/v1/tasks`，输入 `projectId,episodeId?,taskType,targetId,inputData,modelConfigId,idempotencyKey`；返回任务 UUID，长任务只返回接受状态，不等待供应商生成。
- 查询 `GET /api/v1/tasks/{taskId}`；日志 `GET /api/v1/tasks/{taskId}/logs`；重试与取消分别 `POST .../retry`、`POST .../cancel`。
- Java 调 Python：`POST /internal/v1/executions`，请求含 `taskId,attemptId,executionToken,taskType,input,model,traceId`；返回 `executionId,accepted`。查询和取消为 `GET /internal/v1/executions/{executionId}`、`POST .../cancel`。
- Python 回报 Java：`POST /internal/v1/task-events`，含 `eventId,taskId,attemptId,executionToken,sequence,status,progress,output,error,usage`。Java 去重、拒绝过期执行令牌和乱序事件；所有内部请求使用 Token 认证。
- 模型配置保存 `secretRef` 而非密钥明文；本地密钥由环境变量注入。设置页配置地址、能力、模型和引用，读取接口不返回真实密钥。运行时 Java 使用受保护内部请求传递密钥且禁止日志记录正文中的敏感字段。
- `usage` 保存模型/Prompt 版本、参数、输入资产版本、供应商任务 ID、token/时长/计费单位；成本按配置费率计算并标记估算与币种，缺失报价显示未知而不是零成本。
- 媒体响应提供受控 URL，不暴露任意本机路径。下载支持视频 Range；输出登记包含相对路径、校验和、类型、时长及分辨率。

## 5. 分阶段任务与验收

### Task P0：工程初始化和契约基线

**Files:** 新增 `README.md`、`.gitignore`、`.env.example`、`docker-compose.yml`、`scripts/start-dev.ps1`、`scripts/start-dev.sh`、`contracts/public-api.yaml`、`contracts/ai-engine-api.yaml`、`database/schema.md`；新增 `backend/pom.xml` 及上述 Maven 模块、`frontend/package.json`/`src/main.tsx`/`src/App.tsx`、`ai-engine/requirements.txt`/`main.py`/`app/core/config.py`。

**Produces:** 可启动三服务、健康检查、固定依赖和正式契约；为 P1/P2 提供配置及测试框架。

- [x] 确认截断规范、运行时工具、Git 初始化方案和供应商能力清单；将默认端口及配置说明写入 README。
- [x] 定义数据对象、响应、错误码、任务状态和内部认证契约；前端与 AI 共同核对字段。
- [x] 先写健康检查与无 Token 拒绝访问的失败测试，再建立最小三服务、PostgreSQL Compose 与测试工具。
- [x] 建立首个 Flyway 迁移和 `ddl-auto=validate`；Compose 服务配置健康检查，不将服务启动顺序视为服务就绪。
- [x] 验证 `docker compose config`、`mvn -f backend/pom.xml verify`、前端 `npm run build`、AI `python -m pytest`；契约可被 OpenAPI 校验器解析。
- [x] 验收：无真实密钥可启动开发环境，健康检查正常，错误 Token 返回 401/403；实际结果已记录于 `docs/acceptance-p0.md`；Git 身份已配置，用户已授权提交并推送 P0 基线；以 Git 历史确认结果。

### Task P1：基础业务、存储和模型管理

**Files:** 新增 `backend/comic-project/` 项目/剧集 Controller、Service、Repository、DTO；`comic-asset/` MediaFile 与文件访问服务；`comic-model/` 模型配置与连接测试；对应 Flyway 新迁移；`frontend/src/pages/project/`、`settings/`、`src/api/project.ts`、`model.ts`；AI 模型连接测试接口与 `adapters/llm/base.py`。

**Consumes:** P0 契约与配置。**Produces:** projectId/episodeId、受控 mediaId、可用 modelConfigId。

- [ ] 先测试项目 CRUD、比例/分辨率非法值、剧集关联、删除确认和分页边界。
- [ ] 建表并实现项目/剧集页面、生产进度的后端统计、Dashboard 基础查询。
- [ ] 实现密钥引用与模型能力/默认参数配置、连接测试、敏感字段脱敏；地址限制和超时控制防止任意内网探测。
- [ ] 建立文件类型与大小白名单、相对路径归一化、目录边界检查及预览/下载服务。
- [ ] 验证路径穿越、伪造扩展名、超限上传、删除关联和错误配置测试；普通 CI 只调用 Mock 模型。
- [ ] 验收：浏览器完成项目与剧集 CRUD；配置读取、日志、数据库都没有明文 API Key；项目重启后存在。

### Task P2：任务调度、状态机和早期恢复

**Files:** 新增 `comic-task/` 的 Task/Attempt/Log 实体、状态服务、领取/租约/恢复组件；`comic-generation/client/AiEngineClient.java`；AI `app/api/executions.py`、`workers/`、`schemas/execution.py`；前端 `api/task.ts`、`types/task.ts`、`pages/generation/`；任务表 Flyway 迁移。

**Consumes:** P1 项目/模型/存储与 P0 内部契约。**Produces:** 后续所有 AI 工作流复用的异步执行通道。

- [ ] 先写状态流转、重复提交、过期事件拒绝、受限重试和重启恢复失败测试。
- [ ] 建立 task、attempt、log 和结果登记；数据库原子领取及租约/心跳；外部调用在事务外进行。
- [ ] 用无付费 Mock 工作流跑通提交、等待、回报、审核、成功/失败；前端展示真实状态和日志，离页停止轮询。
- [ ] 明确状态：PENDING→QUEUED→RUNNING；供应商等待用 WAITING；需人工确认的产物进入 REVIEWING；有效审核后 SUCCEEDED；可重试失败创建新 attempt，经 RETRYING→QUEUED。终态禁止被旧回报覆盖。
- [ ] 超时和 429 可指数退避，验证/鉴权错误不可自动重试；Java 控制任务级次数，Python 仅做受限传输重试，避免重试相乘。
- [ ] 持久化供应商任务 ID、executionId 和输入快照；重启先查询远端已有任务再决定续跑。供应商不支持幂等且提交结果不明时进入人工核对，不盲目二次付费提交。
- [ ] 取消区分本地取消与供应商停止能力；取消后晚到结果不恢复成功状态。Python 队列不是唯一持久化来源。
- [ ] 验收：同幂等键不重复生成；杀停 Java/Python 后恢复；旧 attempt 回调无效；单任务失败不影响其他任务。

### Task P3：故事导入和结构化分析

**Files:** 新增 `comic-story/` 故事正文/分析版本实现；前端 `pages/story/`、`components/story/`、`api/story.ts`；AI `schemas/story.py`、`workflows/story/analysis.py`、`services/document_parser.py`、`prompts/story/analysis/v1.md`；对应迁移与测试文件。

**Consumes:** P2 任务、P1 项目/文件/模型。**Produces:** 正文和经审核的结构化故事档案。

- [ ] 先制作 TXT（UTF-8/常见中文编码）、DOCX、可提取文本 PDF、空文件、损坏文件及非法 AI JSON 测试样本。
- [ ] 实现正文提取和直接文本输入；扫描 PDF 明确提示无可提取文本，OCR 不作为默认隐含能力。
- [ ] 分别解析背景、人物关系、剧情节点、时间线和地点；输出用 Pydantic 验证，长文按模型上下文限制分段并保留来源定位。
- [ ] 通过 P2 创建分析任务，前端支持修改与审核，保存输入与 Prompt 版本。
- [ ] 验收：四类输入均可处理；无效文件不会生成业务成功结果；已有分析不会被重新生成覆盖。

### Task P4：大纲、分集与剧本版本

**Files:** 新增 `comic-script/` 剧本版本、审核和当前版本引用；前端 `pages/script/`、`api/script.ts`；AI `schemas/script.py`、`workflows/script/outline.py`、`generation.py`、`prompts/script/generation/v1.md`；对应迁移与测试。

**Consumes:** 已审核故事版本。**Produces:** 剧集划分、含对白/旁白的剧本版本。

- [ ] 先测试大纲/分集结构、单集重生成隔离、版本冲突和人工修改保存。
- [ ] 将大纲、分集、单集剧本作为独立步骤，不能以一个 Prompt 代替全部流程。
- [ ] 保存版本、父版本和审核状态；前端提供版本查看、编辑和选择当前版本。
- [ ] 验收：可独立重生成一集且其他剧集不变；当前已审核剧本引用明确，修改后下游标记为需要检查。

### Task P5：角色/场景资产与结构化分镜

**Files:** 扩展 `comic-asset/` Character/Scene/AssetVersion；新增 `comic-storyboard/` Shot/StoryboardVersion；前端 `pages/asset/`、`pages/storyboard/`、`components/storyboard/ShotTimeline/`；AI `schemas/asset.py`、`storyboard.py`、`workflows/asset/extraction.py`、`workflows/storyboard/generation.py` 及 Prompt。

**Consumes:** 当前已审核剧本版本。**Produces:** 角色/场景档案、参考媒体引用和有序镜头版本。

- [ ] 先测试角色场景复用、引用完整性、镜头排序唯一性、非正时长拒绝、版本隔离。
- [ ] 提取角色外貌/服装/表情/声音配置和场景光照/环境；资产版本可人工编辑。
- [ ] 分镜输出编号、景别、角度、运镜、动作、表情、时长、图像/视频提示词及资产引用。
- [ ] 实现镜头编辑、删除、排序、单镜头重新生成与分镜版本；参考图实际生成复用 P6 图像通道，不另造任务系统。
- [ ] 验收：资产可跨镜头复用；镜头顺序与持久化一致；重新生成保留旧分镜；目标总时长可检查。

### Task P6：关键帧和异步镜头视频

**Files:** 扩展 `comic-generation/` 图像/视频结果协调；AI `adapters/image/base.py`、`adapters/video/base.py`、各能力 `providers/`、`workflows/generation/image.py`/`video.py`；前端 `components/generation/GenerationPreview/` 和镜头生成操作；生成结果/供应商引用迁移。

**Consumes:** 已审核镜头/资产版本与模型能力。**Produces:** 多候选参考图、选定关键帧和镜头视频。

- [ ] 先测试供应商请求映射、能力不支持、429/超时、远端任务查询、取消与迟到响应。
- [ ] 先完成各能力的 Mock Adapter，再接一个实际可用图像供应商和一个视频供应商；LLM 兼容协议不推定为其他媒体能力通用协议。
- [ ] 支持模型参数、提示词修改、角色/场景参考图、多候选选择；视频输入绑定选定关键帧版本。
- [ ] 实现远端异步提交/轮询、结果下载校验及历史查看；视频时长/分辨率按供应商真实能力验证。
- [ ] 若修改关键帧或镜头提示词，旧视频保留但标记不匹配当前输入，不能直接冒充最新结果。
- [ ] 验收：一个镜头失败可以单独重试；其他已完成镜头可复用；图像/视频真实调用经人工授权限定次数和预算。

### Task P7：音频、字幕、合成与导出

**Files:** AI `adapters/audio/base.py`、`providers/`、`workflows/generation/audio.py`、`compose.py`、`services/ffmpeg_service.py`；后端合成输入清单及结果登记；前端音频配置、生成预览与导出；`scripts/check-media.ps1`、`check-media.sh`。

**Consumes:** 已选镜头视频、对白/旁白、角色声音和音频素材。**Produces:** 合成任务、字幕文件和最终 MP4。

- [ ] 先测试角色声音绑定、缺失音轨、对白超长、损坏视频、非零 FFmpeg 退出码和不合法输出路径。
- [ ] 生成对白、旁白、环境音和背景音乐；缺少真实音乐/音效供应商时完成 Mock 和素材导入，但明确真实生成功能尚未验收。
- [ ] 建立合成清单，按分镜排序统一分辨率/帧率/音频采样率；对白超长需用户调整或明确时长策略，不静默裁掉台词。
- [ ] 添加字幕、配音、音效和背景音乐，控制音量与混音；调用 FFmpeg 使用参数数组，不拼接用户输入为 shell 命令。
- [ ] 用 ffprobe 检查时长、分辨率、编码和音轨，用前端验证 Range 播放及下载；预览失败不登记成功。
- [ ] 验收：生成 30～60 秒、可播放/下载 MP4；镜头顺序正确，字幕/对白基本同步，无明显黑帧、静音异常或截断。

### Task P8：可靠性、安全与最终验收

**Files:** 新增 `docs/acceptance-v1.md`、`docs/recovery.md`、`docs/model-providers.md`、各模块集成/端到端测试及 `scripts/smoke-test.ps1`/`.sh`；补充 README 运行、备份与恢复说明。

**Consumes:** P0～P7 所有闭环。**Produces:** 可复现验收记录和已知限制清单。

- [ ] 先自动化重启、重复提交、无效回报、文件越界及密钥泄露回归用例，再修复测试发现的问题。
- [ ] 演练 Java 重启、Python 重启、供应商超时/限流、文件下载失败、FFmpeg 中断和重复回报；记录已完成结果复用情况。
- [ ] 检查生成追溯字段与模型消耗/成本；备份数据库和 storage，恢复后媒体引用可用。
- [ ] 用说明了机器配置、数据量、并发数的本地负载测量普通业务接口 P95；AI 推理和上传下载单独统计。
- [ ] 在 Windows 11 完成完整真实故事验收；Linux 至少验证启动、迁移、测试和媒体合成链路。
- [ ] 全部 SRS 验收项逐项记录输入、结果、日志/截图、产物路径；失败项不标记完成。

## 6. 测试与提交工作纪律

每个阶段拆成可独立验收的小任务，每个小任务执行：读取规范→锁定文件/契约→写失败测试→确认失败原因→最小实现→运行测试→检查调用方与契约→提交。编码细节和实际测试代码写入对应子系统实施计划，不能仅凭本文大阶段直接批量生成整个项目。

建议在 P0 设置以下脚本，后续阶段复用（当前尚不存在）：

```powershell
mvn -f backend/pom.xml verify
# 在 frontend 目录
npm ci
npm run typecheck
npm run lint
npm run test -- --run
npm run build
# 在 ai-engine 的 Python 3.12 虚拟环境内
python -m pytest
# 在项目根目录
docker compose config
```

后端数据库集成测试使用 PostgreSQL 验证 Flyway/JSONB/原子领取，不用 H2 替代后宣称数据库验证通过。前端建议 Vitest、React Testing Library 与 Playwright；初始化时作为测试依赖确认并固定版本。所有供应商测试默认 Mock，真实付费测试与普通 CI 隔离。

每次汇报包含：修改文件、已执行命令、实际结果、剩余问题和下一项任务。当前没有 Git，先确认初始化后再执行小步提交；本次只新增计划文档，未执行任何业务构建或测试。

## 7. SRS 覆盖与验收映射

| SRS | 实施阶段 | 验收证据 |
|---|---|---|
| 2.1 项目 | P1 | 创建/编辑/删除、剧集和进度测试 |
| 2.2 故事 | P3 | 四种输入、结构化档案与人工修订 |
| 2.3 剧本 | P4 | 大纲、分集、对白/旁白和版本测试 |
| 2.4 分镜 | P5 | 全字段、排序、编辑和独立重生成 |
| 2.5/2.6 资产 | P5/P6 | 角色/场景版本、参考图生成与复用 |
| 2.7 图片 | P6 | 参数/参考图/候选图与选定结果 |
| 2.8 视频 | P6 | 异步、查询、取消、历史及单镜头重试 |
| 2.9 音频 | P7 | 配音/旁白/环境音/音乐及重新生成 |
| 2.10 合成 | P7 | 字幕、音轨、时长、预览和 MP4 |
| 2.11 任务 | P2/P8 | 状态、日志、进度、恢复、消耗和成本 |
| 2.12 模型 | P1/P6/P7 | 供应商/密钥引用/参数/能力与连接测试 |
| 3.1/3.2 维护扩展 | P0/各阶段 | 模块边界及 Adapter/契约测试 |
| 3.3/3.4 稳定恢复 | P2/P8 | 杀停和重启演练 |
| 3.5 安全 | P0/P1/P8 | 鉴权、密钥脱敏和文件安全测试 |
| 3.6 性能 | P8 | 排除推理/传输后的 P95 测量 |
| 3.7 追溯 | P2/各工作流/P8 | 输入/模型/Prompt/参数/结果完整记录 |
| 第 5 节验收 1～12 | P8 汇总 | 真实短篇故事 30～60 秒成片和恢复证据 |

质量检测在 P7/P8 实施为文件可读性、时长、分辨率、音轨、缺失镜头与基本播放检查，不承诺专业级自动审片。无真实供应商调用证据时只能报告 Mock 闭环，不报告完整 V1.0 验收成功。

## 8. 下一步的具体执行范围

优先只开展 P0，建议首个执行批次：

1. 确认规范截断问题与工程初始化范围，检查 JDK/Maven/Node/Python/Docker/FFmpeg 的版本。
2. 编写 `contracts/public-api.yaml` 和 `contracts/ai-engine-api.yaml` 的健康检查、基础响应及任务骨架契约。
3. 建立 Maven 多模块、React 空壳和 FastAPI 健康检查；建立 `.env.example`、PostgreSQL Compose 和安全忽略规则。
4. 建立测试与启动脚本，实际运行三服务和鉴权测试，交付 M0。

P0 通过后才进入 P1/P2；不以堆页面或接入昂贵视频模型代替基础设施验收。
