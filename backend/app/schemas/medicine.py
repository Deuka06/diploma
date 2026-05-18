from pydantic import BaseModel

from app.schemas.common import ORMModel


class SellerOut(ORMModel):
    id: str
    name: str
    rating: float
    review_count: int


class SellerOfferOut(ORMModel):
    id: int
    medicine_id: str
    seller_id: str
    price: float
    currency: str
    delivery_text: str
    tags: list[str] | None
    seller: SellerOut


class MedicineBrief(ORMModel):
    id: str
    name: str
    indication_label: str | None
    category: str
    image_url: str | None
    price: float


class MedicineDetail(MedicineBrief):
    subcategory: str | None
    active_ingredients: list[str]
    allergen_tags: list[str] | None
    analog_ids: list[str] | None
    description: str | None
    dosage: str | None
    instructions: str | None
    restrictions: str | None


class MedicineSafetyOut(BaseModel):
    is_recommended: bool
    conflict_allergen: str | None
    warning_message: str | None
    alternatives: list[MedicineBrief]


class CategoryOut(BaseModel):
    id: str
    label: str
