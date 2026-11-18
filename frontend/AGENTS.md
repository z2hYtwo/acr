# Frontend — React 前端 Agent 开发规范

> 本文件约束 AI Comic Studio/frontend 目录下的所有前端开发活动。
>
> 开发前必须同时阅读项目根目录 AGENTS.md。

---

# 1. 模块定位

Frontend 是 AI Comic Studio 的用户交互和内容展示层。

主要职责：

- 项目管理。
- 剧集管理。
- 故事输入与分析结果展示。
- 剧本查看和编辑。
- 分镜展示和编辑。
- 角色与场景资产管理。
- 图像和视频预览。
- AI 生成任务管理。
- 模型配置管理。
- 最终视频预览和导出。

前端不负责实际模型推理和核心 AI 工作流执行。

# 2. 技术栈

| 技术 | 主要用途 |
|---|---|
| React 19 | UI 框架 |
| TypeScript | 类型系统 |
| Vite | 构建工具 |
| React Router | 页面路由 |
| Axios | HTTP 请求 |
| Zustand | 全局状态管理 |
| TanStack Query | 服务端状态管理 |
| Ant Design | UI 组件库 |
| Lucide React | 图标 |

未经批准不得更换核心技术。

# 3. 项目目录结构

```text
frontend/
├── public/
│
├── src/
│   ├── api/
│   │   ├── request.ts
│   │   ├── project.ts
│   │   ├── story.ts
│   │   ├── script.ts
│   │   ├── storyboard.ts
│   │   ├── asset.ts
│   │   └── task.ts
│   │
│   ├── assets/
│   │
│   ├── components/
│   │   ├── common/
│   │   ├── project/
│   │   ├── story/
│   │   ├── storyboard/
│   │   ├── asset/
│   │   └── generation/
│   │
│   ├── layouts/
│   │
│   ├── pages/
│   │   ├── dashboard/
│   │   ├── project/
│   │   ├── story/
│   │   ├── script/
│   │   ├── storyboard/
│   │   ├── asset/
│   │   ├── generation/
│   │   └── settings/
│   │
│   ├── hooks/
│   │
│   ├── router/
│   │
│   ├── stores/
│   │
│   ├── types/
│   │
│   ├── utils/
│   │
│   ├── App.tsx
│   └── main.tsx
│
├── package.json
├── tsconfig.json
└── vite.config.ts
```

不得将所有业务代码放在 App.tsx 中。

新增目录必须符合现有结构和业务职责。

# 4. 页面架构规范

页面建议划分为以下模块。

## 4.1 Dashboard

展示：

- 项目总数。
- 剧集总数。
- 生成任务数量。
- 成功任务数量。
- 失败任务数量。
- 最近生成记录。
- 最近项目。

Dashboard 只负责数据展示和快捷入口。

## 4.2 项目管理页面

负责：

- 项目列表。
- 项目创建。
- 项目编辑。
- 项目详情。
- 项目删除。
- 项目状态展示。

## 4.3 故事管理页面

负责：

- 故事输入。
- 故事内容编辑。
- 故事分析任务创建。
- 分析进度展示。
- 故事分析结果展示。
- 角色和场景提取结果展示。
- 分析结果人工修订。

## 4.4 剧本管理页面

负责：

- 剧集列表。
- 剧本查看。
- 剧本编辑。
- 剧本生成。
- 剧本版本管理。
- 剧本审核。

## 4.5 分镜管理页面

负责：

- 分镜列表。
- 分镜详情。
- 镜头顺序调整。
- 镜头描述编辑。
- 镜头时长调整。
- 分镜图预览。
- 分镜重新生成。

## 4.6 资产管理页面

负责：

- 角色资产。
- 场景资产。
- 道具资产。
- 参考图展示。
- 资产版本管理。
- 资产关联关系。

## 4.7 生成任务页面

负责：

- 任务列表。
- 任务状态。
- 任务进度。
- 任务详情。
- 执行日志。
- 失败原因。
- 任务重试。
- 任务取消。

## 4.8 设置页面

负责：

- 模型供应商配置展示。
- 模型选择。
- 本地存储配置展示。
- 系统基础配置。

不得在浏览器中直接保存私有模型密钥。

# 5. 组件设计规范

组件必须保持单一职责。

建议划分：

```text
components/
├── common/
│   ├── PageHeader/
│   ├── EmptyState/
│   ├── LoadingState/
│   ├── ErrorState/
│   └── ConfirmDialog/
│
├── project/
│   ├── ProjectCard/
│   ├── ProjectForm/
│   └── ProjectList/
│
├── story/
│   ├── StoryEditor/
│   └── StoryAnalysisPanel/
│
├── storyboard/
│   ├── StoryboardCard/
│   ├── StoryboardEditor/
│   └── ShotTimeline/
│
├── asset/
│   ├── CharacterCard/
│   └── SceneCard/
│
└── generation/
    ├── TaskCard/
    ├── TaskProgress/
    └── GenerationPreview/
```

要求：

- 组件职责清晰。
- 公共组件可复用。
- 避免重复实现相同 UI。
- 避免超大组件。
- 复杂组件应拆分子组件。
- 组件内部不要重复定义 API 请求逻辑。

# 6. API 请求规范

所有业务 API 统一放在 src/api。

推荐：

```text
api/
├── request.ts
├── project.ts
├── story.ts
├── script.ts
├── storyboard.ts
├── asset.ts
└── task.ts
```

统一使用 Axios 实例。

要求：

- 统一配置 baseURL。
- 统一设置超时时间。
- 统一处理响应结构。
- 统一处理错误信息。
- 统一处理请求取消。
- 不在组件中重复创建 Axios 实例。

前端业务 API 默认调用 Java 后端。

禁止直接调用需要保密的 LLM、图像、视频和音频模型 API。

# 7. 类型规范

所有核心业务数据必须定义 TypeScript 类型。

建议：

```text
types/
├── common.ts
├── project.ts
├── story.ts
├── script.ts
├── storyboard.ts
├── asset.ts
├── task.ts
└── model.ts
```

示例：

```typescript
export type TaskStatus =
  | "PENDING"
  | "QUEUED"
  | "RUNNING"
  | "WAITING"
  | "RETRYING"
  | "REVIEWING"
  | "SUCCEEDED"
  | "FAILED"
  | "CANCELLED";

export interface GenerationTask {
  id: string;
  taskNo: string;
  taskType: string;
  status: TaskStatus;
  progress: number;
  errorMessage?: string;
}
```

要求：

- 不随意使用 any。
- 不重复定义相同业务类型。
- API 类型与后端契约保持一致。
- 枚举值与后端保持一致。
- 接口变化时同步修改对应类型。

# 8. 状态管理规范

根据数据性质选择状态管理方式。

## 8.1 Zustand

用于客户端全局状态，例如：

- 当前项目。
- 当前剧集。
- 页面级共享 UI 状态。
- 用户界面偏好。

## 8.2 TanStack Query

用于服务端数据：

- 项目列表。
- 项目详情。
- 剧集信息。
- 故事内容。
- 分镜数据。
- 生成任务。
- 模型配置。

不得将所有服务端数据都复制到 Zustand。

## 8.3 局部状态

组件内部临时状态使用 React useState 或 useReducer。

避免不必要的全局状态。

# 9. 页面交互规范

所有异步操作必须提供明确的交互反馈。

包括：

- Loading。
- Success。
- Error。
- Empty。
- Disabled。

AI 生成任务必须区分：

- 等待提交。
- 排队中。
- 执行中。
- 等待外部服务。
- 重试中。
- 等待审核。
- 执行成功。
- 执行失败。
- 已取消。

任务进度必须来自后端数据，不得在前端虚构生成进度。

对于长时间运行的任务，使用合理的轮询或后续支持的实时通信机制获取状态。

页面离开时应合理处理轮询清理，避免重复请求。

# 10. UI 设计规范

整体视觉方向：

- 现代化桌面工具平台。
- 清晰的内容层级。
- 简洁专业。
- 重点突出媒体内容。
- 统一间距和布局。
- 统一按钮和表单样式。

设计要求：

- 优先保证操作清晰。
- 统一页面 Header。
- 统一卡片样式。
- 统一状态标签。
- 统一表格和分页。
- 统一弹窗交互。
- 合理使用空状态和错误状态。
- 避免过度装饰。
- 避免无意义的复杂动画。

对于漫剧创作场景，图像、分镜和视频预览应拥有足够的展示空间。

# 11. 文件与媒体展示

媒体展示组件应考虑：

- 图片加载状态。
- 图片加载失败。
- 视频播放控制。
- 音频播放控制。
- 媒体尺寸适配。
- 文件下载。
- 生成结果预览。

不得将大型媒体文件通过不合理的方式反复加载到页面中。

优先使用后端提供的文件访问接口或受控的本地资源访问方式。

# 12. 路由规范

统一在 router 目录管理路由。

建议：

```text
/dashboard

/projects
/projects/:projectId

/projects/:projectId/stories

/projects/:projectId/episodes

/projects/:projectId/scripts

/projects/:projectId/storyboards

/projects/:projectId/assets

/generation/tasks

/settings
```

要求：

- 路由命名清晰。
- 避免页面路径重复。
- 合理使用嵌套路由。
- 需要共享布局的页面使用 Layout。
- 页面参数必须进行有效性处理。

# 13. 环境变量规范

使用 Vite 环境变量。

例如：

```text
VITE_API_BASE_URL=/api
```

要求：

- 不将私有密钥放入 VITE_ 环境变量。
- 不将模型供应商 API Key 放入前端环境文件。
- 不在组件中硬编码后端地址。
- 不同环境使用独立配置。

# 14. 测试与构建规范

重点验证：

- 页面渲染。
- 组件交互。
- API 请求。
- 表单校验。
- 状态更新。
- 任务状态展示。
- 错误处理。
- 页面路由。

提交前根据项目现有脚本执行：

```powershell
npm run build
```

如果项目配置了类型检查和测试脚本，也必须执行相关命令。

不得声称未执行的构建或测试已经通过。

# 15. 开发执行流程

每次任务必须：

1. 阅读根目录 AGENTS.md。
2. 阅读本文件。
3. 检查现有页面和组件。
4. 确认现有 API 和类型定义。
5. 分析影响范围。
6. 输出实施计划。
7. 编写代码。
8. 执行构建和测试。
9. 检查页面交互。
10. 汇报修改内容和测试结果。

# 16. 禁止事项

1. 不得把所有页面写入 App.tsx。
2. 不得把所有业务状态放进一个 Zustand Store。
3. 不得在页面组件中重复编写 API 请求。
4. 不得随意使用 any。
5. 不得直接调用私有模型 API。
6. 不得将真实密钥放进前端环境变量。
7. 不得虚构任务进度。
8. 不得随意更改后端接口字段。
9. 不得为简单页面引入复杂状态管理。
10. 不得为了视觉效果牺牲页面可用性。
11. 不得修改与当前需求无关的页面。
12. 不得随意删除已有组件。

# 17. 最终原则

前端开发必须始终保持：

- 组件职责清晰。
- 页面结构统一。
- 类型定义明确。
- API 请求统一。
- 状态管理合理。
- 交互反馈完整。
- 媒体展示稳定。
- 用户操作直观。

**前端负责让用户高效完成漫剧创作和管理，不负责执行底层 AI 生成任务。**