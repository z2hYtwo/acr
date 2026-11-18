from enum import StrEnum
from uuid import UUID
from typing import Any
from pydantic import BaseModel, Field, SecretStr

class TaskStatus(StrEnum):
    PENDING = "PENDING"
    QUEUED = "QUEUED"
    RUNNING = "RUNNING"
    WAITING = "WAITING"
    RETRYING = "RETRYING"
    REVIEWING = "REVIEWING"
    SUCCEEDED = "SUCCEEDED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"

class ExecutionRequest(BaseModel):
    taskId: UUID
    attemptId: UUID
    executionToken: SecretStr
    taskType: str
    input: dict[str, Any]
    model: dict[str, Any]
    traceId: UUID

class TaskEvent(BaseModel):
    eventId: UUID
    taskId: UUID
    attemptId: UUID
    executionToken: SecretStr
    sequence: int = Field(ge=0)
    status: TaskStatus
    progress: float = Field(ge=0, le=100)
    output: dict[str, Any] | None = None
    error: dict[str, Any] | None = None
    usage: dict[str, Any] | None = None
