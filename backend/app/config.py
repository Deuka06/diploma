from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

_BASE_DIR = Path(__file__).resolve().parents[1]


class Settings(BaseSettings):
    # Always read backend/.env regardless of where uvicorn is started from.
    model_config = SettingsConfigDict(
        env_file=str(_BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # По умолчанию — SQLite (файл в backend/data/), без Docker и без установки PostgreSQL.
    # Для PostgreSQL задайте в .env: postgresql+psycopg://user:pass@localhost:5432/medi
    database_url: str = "sqlite:///./data/medi.db"
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
