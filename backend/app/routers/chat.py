from fastapi import APIRouter, Depends

from app.deps_auth import get_current_user
from app.models.user import User
from app.schemas.chat import ChatMessageIn, ChatMessageOut
from app.config import get_settings
from app.services.chat_ai import generate_reply

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/message", response_model=ChatMessageOut)
def post_chat_message(
    body: ChatMessageIn,
    _user: User = Depends(get_current_user),
) -> ChatMessageOut:
    settings = get_settings()
    hist = [{"role": h.role, "content": h.content} for h in body.history]
    reply = generate_reply(settings, body.message.strip(), hist)
    return ChatMessageOut(reply=reply)
