from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

_BASE_DIR = Path(__file__).resolve().parents[1]
_ENV_FILE = _BASE_DIR / ".env"


class Settings(BaseSettings):
    # Read from backend/.env when it exists, otherwise use environment variables.
    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE) if _ENV_FILE.exists() else None,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # PostgreSQL (Supabase). Задайте в backend/.env: DATABASE_URL=postgresql+psycopg://...
    database_url: str = ""
    jwt_secret: str = "change-me-in-development-only"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7

    # Для локальной разработки можно указать * (все источники, без credentials-cookie).
    cors_origins: str = "*"
    debug_demo_otp: bool = True  # в ответе forgot-password отдавать код (без SMTP)

    # Чат: совместимый с OpenAI API (OpenAI, Groq, локальный Ollama: http://127.0.0.1:11434/v1).
    openai_api_base: str = "https://api.openai.com/v1"
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"

    @property
    def cors_origin_list(self) -> list[str]:
        raw = self.cors_origins.strip()
        if raw == "*":
            return ["*"]
        return [o.strip() for o in raw.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
