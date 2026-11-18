# AI Engine — Python AI 引擎 Agent 开发规范

> 本文件约束 AI Comic Studio/ai-engine 目录下的所有 Python 开发活动。
>
> 开发前必须同时阅读项目根目录 AGENTS.md。

---

# 1. 模块定位

AI Engine 是 AI Comic Studio 的智能执行层。

主要职责：

- 大语言模型调用。
- Prompt 模板管理。
- 故事分析。
- 剧本生成。
- 角色和场景信息提取。
- 分镜生成。
- 图像生成。
- 视频生成。
- 语音合成。
- 音频处理。
- AI 工作流编排。
- AI 输出结构化处理。
- 模型供应商适配。

AI Engine 不负责管理项目的核心业务数据。

Java Backend 是项目业务数据和任务状态的唯一权威管理方。

# 2. 技术栈

| 技术 | 主要用途 |
|---|---|
| Python 3.12.x | 运行环境 |
| FastAPI | 服务接口 |
| Pydantic | 数据校验 |
| HTTPX | HTTP 请求 |
| OpenAI 兼容 SDK | LLM 调用 |
| Pytest | 自动化测试 |
| Tenacity | 受控重试 |

实际依赖以 requirements.txt 为准。

不得未经批准随意引入大型 AI 框架。

# 3. 项目目录结构

```text
ai-engine/
├── app/
│   ├── api/
│   │   └── 内部服务接口
│   │
│   ├── core/
│   │   └── 配置、日志、异常
│   │
│   ├── schemas/
│   │   └── 输入输出数据结构
│   │
│   ├── services/
│   │   └── AI 服务
│   │
│   ├── adapters/
│   │   ├── llm/
│   │   ├── image/
│   │   ├── video/
│   │   └── audio/
│   │
│   ├── workflows/
│   │   ├── story/
│   │   ├── script/
│   │   ├── storyboard/
│   │   ├── asset/
│   │   └── generation/
│   │
│   ├── workers/
│   │   └── 后台执行组件
│   │
│   └── utils/
│
├── prompts/
│   ├── story/
│   ├── script/
│   ├── storyboard/
│   ├── image/
│   ├── video/
│   └── audio/
│
├── tests/
├── requirements.txt
└── main.py
```

不得将所有 AI 逻辑放入 main.py。

# 4. 架构分层

## 4.1 API 层

负责：

- 接收 Java 后端请求。
- 校验请求参数。
- 调用对应的 Workflow 或 Service。
- 返回标准化响应。
- 处理内部接口认证。

API 层不负责复杂 AI 业务逻辑。

## 4.2 Schema 层

负责定义：

- 请求模型。
- 响应模型。
- Workflow 输入输出模型。
- 模型调用参数。
- AI 结果数据结构。

所有重要 AI 输出必须有对应的 Pydantic 模型。

## 4.3 Service 层

负责：

- 具体 AI 能力封装。
- 模型调用协调。
- Prompt 调用。
- 数据转换。
- 结果处理。

Service 不应承担多个无关 Workflow 的全部逻辑。

## 4.4 Adapter 层

负责封装不同模型供应商的调用差异。

例如：

- 请求格式。
- 鉴权方式。
- 模型名称。
- 参数转换。
- 响应解析。
- 错误映射。

业务 Workflow 不应直接依赖具体供应商 SDK 的特殊实现。

## 4.5 Workflow 层

负责将多个 AI 能力组织成完整业务流程。

每个 Workflow 必须独立定义输入、输出和执行步骤。

## 4.6 Worker 层

负责后续的后台任务执行能力。

必须遵守 Java 对任务状态的权威管理原则。

Python Worker 不得独立维护一套与 Java 冲突的业务任务状态。

# 5. 模型适配器规范

不同模型能力应使用独立 Adapter。

```text
adapters/
├── llm/
│   ├── base.py
│   ├── openai_compatible.py
│   └── providers/
│
├── image/
│   ├── base.py
│   └── providers/
│
├── video/
│   ├── base.py
│   └── providers/
│
└── audio/
    ├── base.py
    └── providers/
```

要求：

- 统一接口。
- 统一错误处理。
- 统一日志记录。
- 统一参数校验。
- 供应商实现与业务流程分离。
- 模型参数必须可配置。
- API Key 必须通过安全配置获取。

不得在 Workflow 中硬编码供应商地址和密钥。

不得假设所有供应商的图像、视频和音频 API 都使用相同的请求格式。

# 6. Prompt 工程规范

Prompt 必须与 Python 业务代码分离。

推荐目录：

```text
prompts/
├── story/
│   ├── analysis/
│   └── extraction/
│
├── script/
│   ├── generation/
│   └── revision/
│
├── storyboard/
│   ├── generation/
│   └── refinement/
│
├── image/
├── video/
└── audio/
```

要求：

- Prompt 模板独立保存。
- 使用明确的变量占位符。
- 区分 System Prompt 和 User Prompt。
- 不在 Service 中硬编码大段 Prompt。
- 对关键 Prompt 进行版本管理。
- 记录生成任务使用的 Prompt 版本。
- Prompt 变更后必须验证输出结果。
- 避免向模型提供无关上下文。

Prompt 应围绕当前 Workflow 的任务目标进行设计。

# 7. AI Workflow 开发规范

## 7.1 Workflow 独立性

每个 Workflow 必须：

- 具备独立输入。
- 具备独立输出。
- 具备独立执行入口。
- 具备数据校验。
- 具备异常处理。
- 具备执行日志。
- 可以独立测试。
- 可以被其他 Workflow 复用。

不得将所有流程写入一个超大型 Workflow。

## 7.2 故事分析 Workflow

负责：

- 故事摘要。
- 故事类型识别。
- 情节结构分析。
- 角色提取。
- 场景提取。
- 冲突分析。
- 剧集数量建议。

输出必须结构化。

## 7.3 剧本生成 Workflow

负责：

- 故事转剧本。
- 剧集拆分。
- 场景描述。
- 角色对白。
- 旁白。
- 情绪和动作描述。

剧本必须具有明确的结构，不能只返回一段自然语言。

## 7.4 分镜生成 Workflow

负责：

- 镜头拆分。
- 镜头景别。
- 摄像机运动。
- 镜头时长。
- 画面描述。
- 角色位置。
- 场景引用。
- 镜头之间的连续性。

分镜结果必须能够被后续图像和视频生成模块使用。

## 7.5 资产生成 Workflow

负责：

- 角色视觉描述。
- 角色参考图生成请求。
- 场景视觉描述。
- 场景参考图生成请求。
- 道具描述。
- 资产版本和引用关系。

必须关注角色和场景的视觉一致性。

## 7.6 图像与视频生成 Workflow

负责：

- 根据分镜构建生成参数。
- 选择模型供应商。
- 调用对应 Adapter。
- 处理异步生成结果。
- 记录生成文件位置。
- 返回标准化结果。

不得假设外部模型调用一定能够同步返回最终文件。

# 8. 结构化输出规范

禁止将未经校验的模型原始文本直接作为可信业务数据。

使用 Pydantic 进行输出验证。

示例：

```python
from pydantic import BaseModel, Field


class CharacterInfo(BaseModel):
    name: str
    appearance: str
    personality: str = ""
    role: str = ""


class StoryAnalysis(BaseModel):
    title: str
    genre: str
    summary: str
    characters: list[CharacterInfo] = Field(default_factory=list)
    scenes: list[str] = Field(default_factory=list)
    episode_count: int = Field(ge=1)
```

输出处理流程：

1. 接收模型原始响应。
2. 提取结构化内容。
3. 执行 JSON 解析。
4. 使用 Pydantic 校验。
5. 处理缺失字段和非法数据。
6. 返回标准化结果。
7. 记录必要的执行信息。

当解析失败时，不得静默返回成功。

# 9. 异步任务与异常处理

图像和视频生成通常具有较长执行时间。

必须考虑：

- 外部任务编号。
- 生成状态。
- 请求超时。
- 任务查询。
- 结果回调或轮询。
- 失败重试。
- 取消请求。
- 结果下载。
- 临时文件清理。

Python 负责执行过程，Java 负责业务任务状态。

不得在 Python 中创建另一套与 Java 不一致的任务状态体系。

重试必须考虑：

- 错误类型。
- 最大重试次数。
- 重试间隔。
- 是否存在重复计费风险。
- 是否支持供应商幂等请求。

# 10. Java 通信规范

AI Engine 仅向 Java 提供内部服务接口。

接口统一使用：

/internal/v1/

示例：

```text
GET  /internal/v1/health

POST /internal/v1/workflows/story-analysis

POST /internal/v1/workflows/script-generation

POST /internal/v1/workflows/storyboard-generation

POST /internal/v1/generation/image

POST /internal/v1/generation/video
```

要求：

- 使用 Pydantic 校验请求。
- 使用统一响应结构。
- 内部接口必须认证。
- 记录请求编号。
- 返回清晰的错误码。
- 不向外泄露敏感配置。
- 保持与 contracts 中的接口定义一致。

# 11. 配置管理

使用 Pydantic Settings 管理配置。

配置项示例：

```text
AI_ENGINE_TOKEN
LLM_PROVIDER
LLM_BASE_URL
LLM_API_KEY
LLM_MODEL
STORAGE_ROOT
```

要求：

- 配置与业务代码分离。
- API Key 不得写入代码。
- 开发环境和生产环境配置分离。
- 缺少非必需模型配置时，健康检查仍应能够启动。
- 真正调用模型前才验证对应供应商配置。
- 不得将真实密钥写入日志。

# 12. 文件与媒体管理

Python 生成的文件应写入配置的 STORAGE_ROOT。

要求：

- 文件名唯一。
- 临时文件和正式文件分离。
- 生成结果可追溯。
- 记录文件类型和路径。
- 不随意覆盖已有结果。
- 清理临时文件时不得误删正式资产。
- 文件路径必须防止路径穿越。

Python 通过接口将生成结果元数据交给 Java 管理。

# 13. 日志规范

日志应包含：

- request_id。
- workflow_name。
- task_id。
- provider。
- model_name。
- execution_time。
- status。
- error_type。

禁止记录：

- API Key。
- 内部 Token。
- 完整敏感配置。
- 不必要的用户隐私信息。

关键工作流必须能够根据 task_id 追踪执行过程。

# 14. 测试规范

必须使用 Pytest。

重点测试：

- Pydantic Schema。
- Prompt 模板。
- Adapter。
- Workflow。
- 模型响应解析。
- 异常处理。
- 超时处理。
- 重试机制。
- 文件处理。

外部模型 API 使用 Mock。

普通测试不得产生真实付费调用。

# 15. 开发执行流程

1. 阅读根目录 AGENTS.md。
2. 检查现有 Python 目录结构。
3. 理解已有 Schema、Service 和 Adapter。
4. 明确当前 Workflow 的输入输出。
5. 输出实施计划。
6. 编写代码。
7. 编写测试。
8. 执行 Pytest。
9. 检查与 Java 的接口兼容性。
10. 汇报修改内容和测试结果。

# 16. 禁止事项

1. 不得将所有逻辑写入 main.py。
2. 不得将所有模型调用写入一个 Service。
3. 不得在 Workflow 中硬编码 API Key。
4. 不得让 Workflow 直接依赖具体供应商实现。
5. 不得绕过 Java 修改业务数据。
6. 不得将未验证的模型输出作为正式业务结果。
7. 不得无限重试。
8. 不得假设外部生成接口都是同步的。
9. 不得随意引入复杂 Agent 框架。
10. 不得为了简单任务引入不必要的多 Agent 架构。

# 17. 最终原则

AI Engine 必须保持：

- 模型供应商可替换。
- Workflow 可复用。
- Prompt 可维护。
- 输出可验证。
- 任务可追踪。
- 异常可处理。
- 代码可测试。

**Python 负责让 AI 完成任务，Java 负责让整个业务系统可靠地管理任务。**