from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.medicine import Medicine
from app.models.seller_offer import SellerOffer
from app.schemas.checkout import SellerOfferOut

router = APIRouter(tags=["checkout"])


@router.get("/medicines/{medicine_id}/offers", response_model=list[SellerOfferOut])
def list_offers_for_medicine(
    medicine_id: str,
    tag: str | None = Query(default=None, description="delivery | express | today"),
    db: Session = Depends(get_db),
) -> list[SellerOffer]:
    if db.get(Medicine, medicine_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Препарат не найден")
    q = db.query(SellerOffer).filter(SellerOffer.medicine_id == medicine_id)
    rows = q.all()
    if tag:
        filtered: list[SellerOffer] = []
        for o in rows:
            t = o.tags or []
            if tag in t:
                filtered.append(o)
        rows = filtered
    return rows
