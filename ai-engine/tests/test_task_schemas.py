from uuid import uuid4
import pytest
from pydantic import ValidationError
from app.schemas.task import ExecutionRequest, TaskEvent


def test_execution_requires_uuid_and_masks_token():
    request = ExecutionRequest(taskId=uuid4(), attemptId=uuid4(), executionToken="private-test-token", taskType="STORY_ANALYSIS", input={}, model={}, traceId=uuid4())
    assert "private-test-token" not in repr(request)
    with pytest.raises(ValidationError):
        ExecutionRequest(taskId="invalid", attemptId=uuid4(), executionToken="x", taskType="TEST", input={}, model={}, traceId=uuid4())


@pytest.mark.parametrize("progress,sequence", [(-1,0),(101,0),(50,-1)])
def test_event_rejects_invalid_progress_and_sequence(progress, sequence):
    with pytest.raises(ValidationError):
        TaskEvent(eventId=uuid4(), taskId=uuid4(), attemptId=uuid4(), executionToken="x", sequence=sequence, status="RUNNING", progress=progress)
