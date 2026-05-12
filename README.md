# MEDI — дипломный проект

Монорепозиторий: **backend** (FastAPI + SQLite/PostgreSQL) и **diploma_project** (Flutter).

## Запуск backend

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
PYTHONPATH=. python scripts/seed_medicines.py
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Документация API: http://127.0.0.1:8000/docs  

Демо-логин: `demo@example.com` / `demo123` (домен `.local` не принимается валидатором email в API)

## Запуск Flutter

```bash
cd diploma_project
flutter pub get
flutter run --dart-define=API_BASE=http://127.0.0.1:8000
```

На **Android-эмуляторе** укажите `http://10.0.2.2:8000` вместо `127.0.0.1`.

## Структура

- `backend/` — REST API, логика аллергий, сиды лекарств и продавцов.
- `diploma_project/lib/` — UI по макетам: splash, welcome, вход/регистрация, 5 вкладок, каталог, карточка препарата, продавцы, помощь (FAQ).
