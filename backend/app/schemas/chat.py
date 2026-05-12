from typing import Literal

from pydantic import BaseModel, Field


class ChatHistoryItem(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(..., min_length=1, max_length=4000)


class ChatMessageIn(BaseModel):
    """Текущее сообщение пользователя + предыдущие реплики (без дубля текущего)."""

    message: str = Field(..., min_length=1, max_length=4000)
    history: list[ChatHistoryItem] = Field(default_factory=list, max_length=32)


class ChatMessageOut(BaseModel):
    reply: str
