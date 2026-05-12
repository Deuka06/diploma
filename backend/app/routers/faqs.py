from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.faq import Faq
from app.schemas.faq import FaqOut

router = APIRouter(prefix="/faqs", tags=["faqs"])


@router.get("", response_model=list[FaqOut])
def list_faqs(db: Session = Depends(get_db)) -> list[Faq]:
    return (
        db.query(Faq)
        .filter(Faq.is_active.is_(True))
        .order_by(Faq.sort_order, Faq.id)
        .all()
    )
