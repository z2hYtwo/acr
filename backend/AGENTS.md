# Backend — Java 后端 Agent 开发规范

> 本文件约束 AI Comic Studio/backend 目录下的所有 Java 开发活动。
>
> 开发前必须同时阅读项目根目录 AGENTS.md。

---

# 1. 模块定位

Java Backend 是 AI Comic Studio 的核心业务管理层。

主要职责：

- 业务接口管理。
- 项目与剧集管理。
- 故事、剧本和分镜管理。
- 角色和场景资产管理。
- AI 生成任务管理。
- 模型供应商配置管理。
- 数据持久化。
- AI Engine 内部通信。
- 生成结果管理。

Java 不负责具体的 LLM Prompt 执行和图像、视频模型推理。

# 2. 技术栈

| 技术 | 版本或用途 |
|---|---|
| JDK | 17 |
| Spring Boot | 3.5.x |
| Maven | 3.8.8+ |
| Spring Web | REST API |
| Spring Data JPA | ORM |
| PostgreSQL | 数据库 |
| Flyway | 数据库迁移 |
| Spring Validation | 参数校验 |
| Spring Actuator | 健康检查 |

实际版本以现有 pom.xml 为准。

未经批准不得更换核心技术。

# 3. 模块结构

```text
backend/
├── comic-boot/
│   └── 应用启动与配置
│
├── comic-common/
│   └── 公共组件
│
├── comic-project/
│   └── 项目管理
│
├── comic-story/
│   └── 故事管理
│
├── comic-script/
│   └── 剧本管理
│
├── comic-storyboard/
│   └── 分镜管理
│
├── comic-asset/
│   └── 角色与场景资产
│
├── comic-generation/
│   └── 生成业务管理
│
├── comic-task/
│   └── 任务管理
│
├── comic-model/
│   └── 模型配置管理
│
└── pom.xml
```

模块职责：

- comic-boot：启动入口、应用配置和模块装配。
- comic-common：统一响应、异常、公共枚举、基础工具。
- comic-project：项目业务。
- comic-story：故事业务。
- comic-script：剧本业务。
- comic-storyboard：分镜业务。
- comic-asset：角色、场景和道具资产。
- comic-generation：AI 生成业务。
- comic-task：任务状态和执行记录。
- comic-model：模型供应商配置。

不得将所有业务代码堆积到 comic-boot。

# 4. 模块内部代码结构

业务模块优先使用统一的分层结构。

```text
comic-project/
└── src/main/java/com/comicstudio/project/
    ├── controller/
    ├── service/
    │   └── impl/
    ├── repository/
    ├── entity/
    ├── dto/
    │   ├── request/
    │   └── response/
    ├── mapper/
    ├── enums/
    └── exception/
```

职责：

| 层级 | 职责 |
|---|---|
| Controller | 接收请求、参数校验、返回响应 |
| Service | 核心业务逻辑 |
| Repository | 数据访问 |
| Entity | 数据库实体映射 |
| DTO | 请求和响应数据结构 |
| Mapper | DTO 与 Entity 转换 |
| Enum | 业务枚举 |
| Exception | 业务异常定义 |

不得跨层直接调用不属于当前职责的组件。

# 5. 分层开发规则

## 5.1 Controller

Controller 只负责：

- 接收 HTTP 请求。
- 参数绑定。
- 参数校验。
- 调用 Service。
- 返回统一响应。

禁止：

- 编写复杂业务逻辑。
- 直接操作 Repository。
- 直接编写 SQL。
- 直接调用模型供应商 API。
- 直接返回 JPA Entity。

## 5.2 Service

Service 负责：

- 业务规则。
- 业务数据处理。
- 事务控制。
- 模块之间的业务协调。
- 任务创建与状态变更。
- AI Engine 调用协调。

复杂业务应拆分为职责清晰的 Service。

## 5.3 Repository

Repository 负责：

- 数据查询。
- 数据保存。
- 数据删除。
- 数据访问方法定义。

优先使用 Spring Data JPA。

复杂查询可以使用 JPQL 或经过评估的原生 SQL。

## 5.4 Entity

Entity 只负责数据库映射。

禁止将 Entity 直接作为 API 返回对象。

禁止在 Entity 中编写大量业务流程。

## 5.5 DTO

请求和响应必须使用明确的 DTO。

命名建议：

- CreateProjectRequest
- UpdateProjectRequest
- ProjectResponse
- CreateGenerationTaskRequest
- GenerationTaskResponse

禁止使用 Map 代替所有业务 DTO。

# 6. API 设计规范

统一采用：

/api/v1/{resources}

示例：

```text
GET    /api/v1/projects
POST   /api/v1/projects
GET    /api/v1/projects/{id}
PUT    /api/v1/projects/{id}
DELETE /api/v1/projects/{id}

GET    /api/v1/projects/{id}/episodes
POST   /api/v1/projects/{id}/episodes

POST   /api/v1/generation/tasks
GET    /api/v1/generation/tasks/{taskId}
POST   /api/v1/generation/tasks/{taskId}/retry
POST   /api/v1/generation/tasks/{taskId}/cancel
```

要求：

- 使用 HTTP 方法表达操作语义。
- 路径使用名词。
- 接口版本统一。
- 请求参数必须校验。
- 错误响应必须统一。
- 分页接口统一分页参数。
- 不得随意改变已有接口字段。

# 7. 统一响应结构

业务接口统一返回：

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

在 comic-common 中统一维护响应类。

建议：

```text
comic-common/
└── response/
    └── ApiResponse.java
```

统一异常处理建议：

```text
comic-common/
└── exception/
    ├── BusinessException.java
    └── GlobalExceptionHandler.java
```

不要在每个 Controller 中重复编写响应封装和异常处理。

# 8. AI Engine 通信规范

Java 是 AI Engine 的业务调用入口。

通信方式：

Java Spring Boot
    |
    v
HTTP Client
    |
    v
Python FastAPI

要求：

- 使用统一的 AI Engine Client。
- 使用配置文件管理 Python 服务地址。
- 使用内部 Token 认证。
- 配置连接超时和读取超时。
- 统一处理网络异常。
- 统一记录请求编号。
- 避免业务 Service 直接拼接 HTTP 请求。

推荐结构：

```text
comic-generation/
└── client/
    ├── AiEngineClient.java
    └── AiEngineProperties.java
```

具体实现可放在公共集成模块中，但必须避免形成循环依赖。

Java 负责提交和管理任务，Python 负责执行 AI 工作流。

# 9. 任务管理规范

任务是系统核心业务对象。

每个任务必须具有：

- taskId。
- taskNo。
- projectId。
- episodeId。
- taskType。
- status。
- progress。
- inputData。
- outputData。
- errorCode。
- errorMessage。
- retryCount。
- maxRetries。
- createdAt。
- startedAt。
- finishedAt。

状态：

PENDING、QUEUED、RUNNING、WAITING、RETRYING、REVIEWING、SUCCEEDED、FAILED、CANCELLED。

要求：

- 任务状态必须持久化。
- 状态变更必须经过业务校验。
- 任务执行必须支持幂等控制。
- 重试次数必须受到限制。
- 必须保留执行日志。
- 长时间任务不能阻塞用户请求。
- 任务取消必须检查当前状态和供应商能力。

后续实现任务恢复时，应考虑数据库原子领取、租约、心跳和超时回收。

# 10. 数据库开发规范

数据库使用 PostgreSQL。

Flyway 迁移目录：

```text
comic-boot/src/main/resources/db/migration/
```

要求：

- 所有结构变更通过 Flyway。
- 已执行迁移不可修改。
- 新结构使用新版本迁移。
- JPA 使用 ddl-auto=validate。
- 不使用 ddl-auto=update。
- 高频查询字段合理建立索引。
- 合理使用 JSONB。
- 大型媒体文件不存入数据库。

Entity 与数据库表必须保持一致。

# 11. 事务规范

- 在 Service 层控制事务。
- 多表写操作需要考虑事务一致性。
- 不要在事务中执行长时间模型生成。
- 外部 HTTP 调用与数据库事务应合理分离。
- 不要使用长事务等待视频生成。
- 任务创建和状态更新应保证一致性。

# 12. 配置规范

配置统一放在：

```text
comic-boot/src/main/resources/
├── application.yml
└── application-local.yml
```

敏感信息通过环境变量注入。

禁止：

- 硬编码数据库密码。
- 硬编码模型 API Key。
- 硬编码内部通信 Token。
- 将真实密钥提交到 Git。

# 13. 测试规范

必须根据实际改动编写测试。

重点测试：

- Service 业务逻辑。
- Controller 接口。
- Repository 数据访问。
- 参数校验。
- 全局异常处理。
- 任务状态流转。
- Flyway 迁移。
- AI Engine Client。

外部模型 API 使用 Mock，不应在普通自动化测试中产生真实付费调用。

# 14. 开发执行要求

每次任务按照以下步骤执行：

1. 阅读根目录 AGENTS.md。
2. 检查当前 Java 模块结构。
3. 理解现有实现。
4. 明确修改范围。
5. 输出实施计划。
6. 实现代码。
7. 执行编译与测试。
8. 汇报修改文件和验证结果。

如果需求涉及多个模块，必须说明模块之间的依赖关系。

# 15. 禁止事项

1. 不得在 Controller 中编写复杂业务逻辑。
2. 不得直接返回 Entity。
3. 不得绕过 Service 直接操作 Repository。
4. 不得在业务模块直接硬编码模型 API。
5. 不得让 Java 等待视频生成完成后才返回。
6. 不得修改已经执行的 Flyway 迁移。
7. 不得随意改变任务状态枚举。
8. 不得为小功能创建过多模块。
9. 不得擅自引入消息队列和分布式架构。
10. 不得修改与当前任务无关的代码。

# 16. 最终原则

Java 后端应始终保持：

- 分层清晰。
- 模块独立。
- 业务数据可靠。
- 任务状态可追踪。
- API 结构统一。
- 数据库结构可维护。
- AI Engine 通信可控。

**Java 后端负责管理业务，不负责亲自执行 AI 模型推理。**