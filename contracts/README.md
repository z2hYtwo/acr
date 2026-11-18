# P0 contract baseline

Only the health paths in OpenAPI `paths` are implemented. Task and execution schemas are reserved for P1/P2. No scheduler, model invocation or callback receiver exists yet.

- Public prefix: `/api/v1`; internal prefix: `/internal/v1`.
- Response: `{code,message,data}`; `OK` on success. Errors use matching HTTP status: 401 UNAUTHORIZED, 403 FORBIDDEN (reserved), 404 NOT_FOUND, 422 VALIDATION_ERROR (AI validation), 500 INTERNAL_ERROR, 503 SERVICE_UNAVAILABLE.
- Internal authentication: `Authorization: Bearer <AI_ENGINE_TOKEN>`. Missing and wrong tokens both return 401. No browser token.
- IDs: UUID strings; timestamps: ISO 8601 UTC. Pagination: page starts at 0, size 1–100.
- P2 planned public calls: POST /api/v1/tasks (202); GET /api/v1/tasks/{taskId}; GET .../logs; POST .../retry and .../cancel.
- P2 planned internal calls: POST /internal/v1/executions (202); GET .../{executionId}; POST .../cancel; Java callback POST /internal/v1/task-events.
- Model configs persist secretRef, not secrets. Runtime model objects are protected transport only and must not be logged.
- Python events are not authoritative: Java must validate executionToken, sequence and eventId in P2.
- Entity baseline: Project, Episode, StoryDocument, StoryAnalysisVersion, ScriptVersion, StoryboardVersion, Shot, Character, Scene, AssetVersion, MediaFile, ModelProvider, ModelConfig, GenerationTask, TaskAttempt, TaskLog, GenerationResult. Their business fields and tables are deliberately deferred to the owning phase, rather than pretending P0 is a business implementation.
