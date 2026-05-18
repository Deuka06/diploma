from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import get_settings


class Base(DeclarativeBase):
    pass


def _normalize_url(url: str) -> str:
    if url.startswith("postgres://"):
        url = "postgresql+psycopg://" + url[len("postgres://"):]
    elif url.startswith("postgresql://") and not url.startswith("postgresql+"):
        url = "postgresql+psycopg://" + url[len("postgresql://"):]
    if url.startswith("postgresql+psycopg://"):
        host = url.split("@")[-1].split("/")[0].split(":")[0]
        if host not in ("localhost", "127.0.0.1", "::1") and "sslmode" not in url:
            sep = "&" if "?" in url else "?"
            url = url + sep + "sslmode=require"
    return url


settings = get_settings()
_db_url = _normalize_url(settings.database_url)

_is_pooler = ":6543/" in _db_url
engine = create_engine(
    _db_url,
    pool_pre_ping=True,
    pool_size=3,
    max_overflow=5,
    connect_args={"prepare_threshold": 0} if _is_pooler else {},
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
