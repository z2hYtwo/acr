export const TASK_STATUSES = ['PENDING', 'QUEUED', 'RUNNING', 'WAITING', 'RETRYING', 'REVIEWING', 'SUCCEEDED', 'FAILED', 'CANCELLED'] as const
export type TaskStatus = typeof TASK_STATUSES[number]
export interface CreateTaskRequest { projectId: string; episodeId?: string | null; taskType: string; targetId: string; inputData: Record<string, unknown>; modelConfigId: string; idempotencyKey: string }
