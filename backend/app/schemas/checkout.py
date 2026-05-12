from pydantic import BaseModel

from app.schemas.common import ORMModel


class SellerBrief(ORMModel):
    id: str
    name: str
    rating: float
    review_count: int


class SellerOfferOut(BaseModel):
    id: int
    price: float
    currency: str
    delivery_text: str
    tags: list[str] | None
    seller: SellerBrief
