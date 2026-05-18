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

### Запуск Flutter Web на Vercel

Для веб-версии приложение должно обращаться к работающему backend.

- Backend должен быть доступен по публичному URL.
- При сборке укажите `API_BASE` на адрес backend, например:
  `flutter build web --dart-define=API_BASE=https://your-backend.example.com`
- После этого можно развернуть папку `build/web` через Vercel.

Если вы хотите использовать Supabase, то backend всё равно остаётся FastAPI и работает с вашей PostgreSQL базой напрямую по `DATABASE_URL`.

### Хостинг backend на Render

Чтобы развернуть backend на Render, создайте Web Service с настройками:

- Root: `backend`
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Environment Variables:
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `JWT_ALGORITHM=HS256`
  - `ACCESS_TOKEN_EXPIRE_MINUTES=10080`
  - `CORS_ORIGINS=*`
  - `OPENAI_API_BASE=https://api.openai.com/v1`
  - `OPENAI_API_KEY` (опционально)
  - `OPENAI_MODEL=gpt-4o-mini`

### Запуск Flutter Web на Vercel

Для веб-версии приложение должно обращаться к работающему backend.

- Backend должен быть доступен по публичному URL.
- При сборке укажите `API_BASE` на адрес backend, например:
  `flutter build web --dart-define=API_BASE=https://your-backend.example.com`
- После этого можно развернуть папку `build/web` через Vercel.

Если вы хотите использовать Supabase, то backend всё равно остаётся FastAPI и работает с вашей PostgreSQL базой напрямую по `DATABASE_URL`.

## Структура

- `backend/` — REST API, логика аллергий, сиды лекарств и продавцов.
- `diploma_project/lib/` — UI по макетам: splash, welcome, вход/регистрация, 5 вкладок, каталог, карточка препарата, продавцы, помощь (FAQ).
