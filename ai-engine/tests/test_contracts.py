from pathlib import Path
import re
import yaml
import pytest
from openapi_spec_validator import validate

ROOT = Path(__file__).resolve().parents[2]
STATES = ["PENDING", "QUEUED", "RUNNING", "WAITING", "RETRYING", "REVIEWING", "SUCCEEDED", "FAILED", "CANCELLED"]

@pytest.mark.parametrize("name", ["public-api", "ai-engine-api"])
def test_contract_valid(name):
    spec = yaml.safe_load((ROOT / "contracts" / f"{name}.yaml").read_text(encoding="utf-8"))
    validate(spec)
    assert spec["components"]["schemas"]["TaskStatus"]["enum"] == STATES

def test_task_status_identical_across_languages():
    from app.schemas.task import TaskStatus
    assert [s.value for s in TaskStatus] == STATES
    java = (ROOT / "backend/comic-common/src/main/java/com/comicstudio/common/TaskStatus.java").read_text()
    ts = (ROOT / "frontend/src/types/task.ts").read_text()
    for state in STATES:
        assert re.search(r"\b" + state + r"\b", java)
        assert f"'{state}'" in ts

def test_health_runtime_matches_contract(monkeypatch):
    monkeypatch.setenv("AI_ENGINE_TOKEN", "contract-test-token")
    from main import create_app
    spec = yaml.safe_load((ROOT / "contracts/ai-engine-api.yaml").read_text())
    runtime = create_app().openapi()
    path = "/internal/v1/health"
    assert set(spec["paths"]) == {path}
    assert runtime["paths"][path]["get"]["security"] == [{"InternalBearer": []}]
    assert spec["paths"][path]["get"]["security"] == [{"InternalBearer": []}]
