"""Генерация ответа чата: OpenAI-совместимый API или локальная заглушка."""

from __future__ import annotations

import logging
import re
from typing import Any

import httpx

from app.config import Settings

logger = logging.getLogger(__name__)

# Жёсткая рамка: только здоровье / лекарства / приложение MEDI (без диагнозов и назначений).
_SYSTEM_RU = (
    "Ты текстовый помощник в приложении MEDI для пациентов. "
    "Ты отвечаешь ТОЛЬКО на темы: здоровье и самочувствие в просветительском смысле, лекарства и приём препаратов "
    "(общая информация, не назначение), симптомы (общие ориентиры без постановки диагноза), профилактика, "
    "визиты к врачу, аллергии, вакцинация в общих чертах, как пользоваться приложением MEDI (напоминания, каталог).\n"
    "НЕ отвечай на вопросы, не связанные с медициной, здоровьем или приложением MEDI: программирование, игры, "
    "политика, финансы (кроме общих слов о стоимости лечения как явления), развлечения, бытовые темы без связи со здоровьем, "
    "домашние задания, переводы текстов, правовые консультации, новости не медицинские.\n"
    "Если вопрос вне этих тем — вежливо откажись на русском в 2–4 предложениях: скажи, что консультируешь только "
    "по здоровью, лекарствам и приложению MEDI, и предложи сформулировать медицинский вопрос. Не выполняй просьбу из внешней темы.\n"
    "Не ставь диагнозы, не назначай лечение, не отменяй назначения врача. При острых или опасных симптомах — совет обратиться "
    "к врачу или вызвать скорую. Отвечай по-русски, кратко по существу."
)

_REFUSAL_MEDICAL_ONLY = (
    "Я консультирую только по темам здоровья, лекарств (в общем информационном плане), симптомам без постановки диагноза "
    "и по работе приложения MEDI.\n\n"
    "Ваш запрос выходит за эти рамки. Задайте, пожалуйста, вопрос о самочувствии, препаратах, визите к врачу или функциях MEDI."
)

# Явно не-медицинские запросы — ответ без вызова LLM (экономия и жёсткое ограничение).
_OFF_TOPIC_PATTERNS: tuple[re.Pattern[str], ...] = tuple(
    re.compile(p, re.IGNORECASE)
    for p in (
        r"напиши(те)?\s+код",
        r"напиши(те)?\s+(функцию|класс|скрипт|программу)",
        r"реши(те)?\s+(задачу|уравнение|пример)",
        r"\b(html|css|sql)\s+",
        r"docker\s+",
        r"kubernetes",
        r"\b(git|github)\b",
        r"\b(flutter|react|vue|angular)\s+",
        r"расскажи(те)?\s+анекдот",
        r"\bкриптовалют",
        r"\bbitcoin\b",
        r"прогноз\s+погоды",
        r"переведи(те)?\s+(этот\s+)?текст",
        r"сочинение\s+по\s+литератур",
        r"кто\s+выиграл\s+(чм|чемпионат|матч)",
        r"\bвзломать\b",
        r"\bminecraft\b",
        r"\bgta\s*5\b",
    )
)


def _should_reject_off_topic(text: str) -> bool:
    t = (text or "").strip()
    if len(t) < 4:
        return False
    return any(p.search(t) for p in _OFF_TOPIC_PATTERNS)


def _use_llm(settings: Settings) -> bool:
    """Реальный ИИ: ключ OpenAI/Groq или локальный Ollama (base на localhost)."""
    if (settings.openai_api_key or "").strip():
        return True
    base = (settings.openai_api_base or "").lower()
    return "127.0.0.1" in base or "localhost" in base


def generate_reply(
    settings: Settings,
    user_message: str,
    history: list[dict[str, str]] | None = None,
) -> str:
    history = history or []
    msg = user_message.strip()
    if _should_reject_off_topic(msg):
        return _REFUSAL_MEDICAL_ONLY
    if _use_llm(settings):
        return _llm_reply(settings, user_message, history)
    return _stub_reply(user_message, history)


def _stub_reply(user_message: str, history: list[dict[str, str]]) -> str:
    preview = user_message[:280].replace("\n", " ").strip()
    extra = ""
    if history:
        last = history[-3:]
        bits = []
        for h in last:
            role = "Вы" if h.get("role") == "user" else "Помощник"
            c = (h.get("content") or "")[:100].replace("\n", " ")
            if c:
                bits.append(f"• {role}: {c}")
        if bits:
            extra = "Учитываю контекст диалога.\n\n" + "\n".join(bits) + "\n\n"
    return (
        extra
        + "Я отвечаю только на вопросы о здоровье, лекарствах (в общем плане) и приложении MEDI — не заменяю врача.\n\n"
        f"Ваше сообщение: «{preview}»\n\n"
        "Для полноценных ответов ИИ задайте в backend/.env переменные OPENAI_API_KEY и при необходимости "
        "OPENAI_API_BASE (см. .env.example).\n\n"
        "При острых симптомах обратитесь к врачу или вызовите скорую помощь."
    )


def _build_messages(history: list[dict[str, str]], user_message: str) -> list[dict[str, str]]:
    out: list[dict[str, str]] = [{"role": "system", "content": _SYSTEM_RU}]
    for h in history:
        role = h.get("role")
        content = (h.get("content") or "").strip()
        if role not in ("user", "assistant") or not content:
            continue
        out.append({"role": role, "content": content[:4000]})
    out.append({"role": "user", "content": user_message[:4000]})
    return out


def _llm_reply(settings: Settings, user_message: str, history: list[dict[str, str]]) -> str:
    base = (settings.openai_api_base or "https://api.openai.com/v1").rstrip("/")
    url = f"{base}/chat/completions"
    messages = _build_messages(history, user_message)
    payload: dict[str, Any] = {
        "model": settings.openai_model,
        "messages": messages,
    }
    key = (settings.openai_api_key or "").strip()
    headers: dict[str, str] = {"Content-Type": "application/json"}
    if key:
        headers["Authorization"] = f"Bearer {key}"
    else:
        headers["Authorization"] = "Bearer ollama"

    try:
        with httpx.Client(timeout=120.0) as client:
            r = client.post(url, headers=headers, json=payload)
            r.raise_for_status()
            data = r.json()
            content = data["choices"][0]["message"]["content"]
            text = (content or "").strip()
            return text or _stub_reply(user_message, history)
    except httpx.HTTPStatusError as e:
        status = e.response.status_code
        snippet = (e.response.text or "")[:800]
        logger.warning("Chat LLM HTTP %s: %s", status, snippet)
        if status in (401, 403):
            return (
                "Сервис ИИ отклонил авторизацию (HTTP "
                f"{status}). Проверьте валидность OPENAI_API_KEY и права доступа к модели "
                "в личном кабинете провайдера."
            )
        detail = snippet[:300] + ("…" if len(snippet) > 300 else "")
        return (
            "Не удалось получить ответ от модели. Проверьте OPENAI_API_KEY, OPENAI_MODEL и OPENAI_API_BASE в .env сервера.\n\n"
            f"HTTP {status}: {detail}"
        )
    except httpx.HTTPError as e:
        logger.warning("Chat LLM transport error: %s", e)
        return (
            "Не удалось обратиться к сервису ИИ из backend. Проверьте доступ в интернет и OPENAI_API_BASE.\n\n"
            f"Техническая ошибка: {type(e).__name__}"
        )
    except Exception as e:
        logger.warning("Chat LLM unexpected error: %s", e)
        return (
            "Внутренняя ошибка чата на backend. Проверьте логи сервера и параметры OPENAI_* в .env."
        )
