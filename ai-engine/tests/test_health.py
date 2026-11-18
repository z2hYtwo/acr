import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("AI_ENGINE_TOKEN", "test-internal-token-not-real")
    from main import create_app
    return TestClient(create_app())

def test_valid_token_and_no_provider_config(client):
    response = client.get("/internal/v1/health", headers={"Authorization": "Bearer test-internal-token-not-real"})
    assert response.status_code == 200
    assert response.json() == {"code": "OK", "message": "ok", "data": {"service": "ai-engine", "status": "UP"}}
    assert response.headers["X-Request-ID"]

@pytest.mark.parametrize("header", [None, "Bearer wrong", "Basic abc", "Bearer "])
def test_unauthorized(client, header):
    response = client.get("/internal/v1/health", headers={"Authorization": header} if header else {})
    assert response.status_code == 401
    assert response.json() == {"code": "UNAUTHORIZED", "message": "Internal authentication required", "data": None}
    assert "test-internal-token" not in response.text

def test_missing_token_configuration(monkeypatch):
    monkeypatch.delenv("AI_ENGINE_TOKEN", raising=False)
    from app.core.config import Settings
    with pytest.raises(ValidationError):
        Settings(_env_file=None)

def test_blank_token_configuration():
    from app.core.config import Settings
    with pytest.raises(ValidationError):
        Settings(ai_engine_token="   ", _env_file=None)

def test_internal_unknown_route_is_also_protected(client):
    assert client.get("/internal/v1/executions").status_code == 401

def test_docs_disabled(client):
    assert client.get("/docs").status_code == 404

def test_not_found_envelope(client):
    response = client.get("/missing")
    assert response.status_code == 404
    assert response.json()["code"] == "NOT_FOUND"
