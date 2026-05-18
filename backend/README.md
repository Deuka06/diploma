# MEDI — backend (FastAPI + SQLite или PostgreSQL)

Собственный REST API для приложения MEDI. **По умолчанию база — SQLite в файле** (`backend/data/medi.db`): не нужны Docker и отдельный сервер БД. При необходимости можно переключиться на PostgreSQL через `.env`.

## Стек

- **Python 3.11+**
- **FastAPI** — `/docs` (OpenAPI)
- **SQLAlchemy 2**
- **SQLite** (MVP без Docker) **или** **PostgreSQL** (опционально)

## Быстрый старт без Docker

1. Виртуальное окружение и зависимости:

   ```bash
   cd backend
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. Переменные окружения (по умолчанию уже SQLite):

   ```bash
   cp .env.example .env
   ```

3. Запуск API (из папки `backend`):

   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

   Файл БД появится в **`data/medi.db`** после первого старта.

4. Демо-данные (лекарства + пользователь `demo@example.com` / `demo123`):

   ```bash
   PYTHONPATH=. python scripts/seed_medicines.py
   ```

5. Документация API: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

Проверка: `GET http://127.0.0.1:8000/health`

## Как смотреть базу без Docker

### SQLite — файл `backend/data/medi.db`

- **[DB Browser for SQLite](https://sqlitebrowser.org/)** (бесплатно) — открыть файл, смотреть таблицы `users`, `medicines`.
- Расширение **SQLite** в VS Code / Cursor — открыть `data/medi.db`.
- **TablePlus**, **DBeaver** — тип подключения SQLite, путь к файлу.

### Консоль (если установлен `sqlite3`)

```bash
sqlite3 data/medi.db
.tables
SELECT id, email FROM users;
SELECT id, name, category FROM medicines;
```

## Как добавлять товары

1. Скрипт **`scripts/seed_medicines.py`** — см. выше.
2. Вручную в DB Browser / DBeaver: таблица `medicines`, поле **`active_ingredients`** — JSON-массив, например `["ибупрофен"]`.
3. Позже — через API (`POST /medicines`), когда добавите маршрут.

## Опционально: PostgreSQL / Supabase PostgreSQL

Если понадобится PostgreSQL (как на проде):

```bash
docker compose up -d
```

В `.env` укажите:

```env
DATABASE_URL=postgresql+psycopg://medi:medi@localhost:5432/medi
```

### Supabase

Для Supabase используйте строку подключения из Project Settings → Database → Connection String.

Пример:

```env
DATABASE_URL=postgresql+psycopg://postgres:password@db.etfthwudtdgzipabccxk.supabase.co:5432/postgres?sslmode=require
```

> Важно: URL `https://etfthwudtdgzipabccxk.supabase.co/rest/v1/` — это Supabase REST endpoint. Он не заменяет `DATABASE_URL` для FastAPI backend. Ваш backend подключается напрямую к базе через PostgreSQL connection string.

Без Docker PostgreSQL можно поставить через [Postgres.app](https://postgresapp.com/) (macOS) или пакетный менеджер и создать БД `medi` вручную.

**Adminer** в браузере: [http://127.0.0.1:8081](http://127.0.0.1:8080) — сервер `db`, пользователь `medi`, пароль `medi`, БД `medi` (только при запущенном `docker compose`).

### Render

Для хостинга backend на Render используйте этот сервис как Python Web Service.

- Build Command: `pip install -r backend/requirements.txt`
- Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Root directory: `backend`
- Environment: Python

Задайте в Render Environment Variables:

- `DATABASE_URL` — строка из Supabase
- `JWT_SECRET` — ваш секрет для подписи токенов
- `JWT_ALGORITHM=HS256`
- `ACCESS_TOKEN_EXPIRE_MINUTES=10080`
- `CORS_ORIGINS=*`
- `OPENAI_API_BASE=https://api.openai.com/v1`
- `OPENAI_API_KEY` — опционально
- `OPENAI_MODEL=gpt-4o-mini`

## Структура

```
backend/
  data/              # medi.db (SQLite), в .gitignore
  app/
  scripts/
  docker-compose.yml # опционально
  requirements.txt
```

## API (MVP)

| Метод | Путь | Описание |
|--------|------|-----------|
| POST | `/auth/register` | Регистрация, JSON: `email`, `password`, `full_name?` |
| POST | `/auth/login` | Вход → `access_token` |
| POST | `/auth/forgot-password` | OTP (в MVP `demo_code` в ответе) |
| POST | `/auth/verify-otp` | `{ email, code }` → `reset_token` |
| POST | `/auth/reset-password` | `{ reset_token, new_password }` |
| GET | `/users/me` | Профиль (Bearer) |
| PATCH | `/users/me` | Обновление профиля |
| GET | `/medicines/categories` | Категории |
| GET | `/medicines` | Список, `?category=&q=` |
| GET | `/medicines/{id}` | Карточка |
| GET | `/medicines/{id}/safety` | Аллергии + аналоги (Bearer) |
| GET | `/medicines/{id}/safety/public` | Без токена / гостевой просмотр |
| GET | `/medicines/{id}/offers` | Продавцы и цены |
| GET | `/faqs` | Помощь |
| POST | `/chat/message` | Чат с ИИ (Bearer): тело `message`, опционально `history` — см. ниже |

### Чат с реальным ИИ

Эндпоинт `POST /chat/message` ходит в OpenAI-совместимый `…/v1/chat/completions`. В **`backend/.env`** задайте один из вариантов (примеры в `.env.example`):

- **OpenAI:** `OPENAI_API_KEY`, при необходимости `OPENAI_API_BASE=https://api.openai.com/v1`, `OPENAI_MODEL=gpt-4o-mini`
- **Groq:** `OPENAI_API_BASE=https://api.groq.com/openai/v1`, свой ключ и модель с их консоли
- **Ollama** на этом же компьютере: `OPENAI_API_BASE=http://127.0.0.1:11434/v1`, `OPENAI_MODEL=llama3.2` (ключ можно не указывать)

Без ключа и без `localhost` в base сервер отвечает краткими заглушками. После правок `.env` перезапустите `uvicorn`.

## Дальше по плану

- Онбординг в API, заказы и оплата
- Профиль и аллергии
- Каталог и проверка препарата + аналоги
- Alembic при росте схемы

Таблицы создаются при старте (`create_all`). Если менялись типы колонок, удалите `data/medi.db` и перезапустите API (для MVP).
