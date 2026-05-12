from collections.abc import Generator
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import get_settings

_BACKEND_ROOT = Path(__file__).resolve().parent.parent


class Base(DeclarativeBase):
    pass


def _resolve_database_url(url: str) -> tuple[str, dict]:
    """
    SQLite: относительный путь считается от папки backend/, создаём каталоги.
    Возвращает (url, connect_args).
    """
    if not url.startswith("sqlite"):
        return url, {}

    rest = url.removeprefix("sqlite:///")
    if rest.startswith("/") or (len(rest) > 1 and rest[1] == ":"):
        path = Path(rest)
    else:
        path = (_BACKEND_ROOT / rest).resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    resolved = path.resolve().as_posix()
    return f"sqlite:///{resolved}", {"check_same_thread": False}


settings = get_settings()
_db_url, _sqlite_connect = _resolve_database_url(settings.database_url)
_engine_kwargs: dict = {"pool_pre_ping": not settings.database_url.startswith("sqlite")}
if _sqlite_connect:
    _engine_kwargs["connect_args"] = _sqlite_connect

engine = create_engine(_db_url, **_engine_kwargs)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
