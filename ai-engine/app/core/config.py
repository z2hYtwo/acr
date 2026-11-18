from pathlib import Path
from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=Path(__file__).resolve().parents[3] / ".env", extra="ignore", populate_by_name=True)
    ai_engine_token: SecretStr
    storage_root: str = "../storage"

    @field_validator("ai_engine_token")
    @classmethod
    def token_not_blank(cls, value: SecretStr) -> SecretStr:
        if not value.get_secret_value().strip():
            raise ValueError("Internal token must not be blank")
        return value
