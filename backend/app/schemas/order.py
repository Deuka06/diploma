from datetime import datetime

from pydantic import BaseModel

from app.schemas.common import ORMModel


class OrderItemIn(BaseModel):
    medicine_id: str
    quantity: int = 1
    unit_price: float


class OrderCreate(BaseModel):
    items: list[OrderItemIn]
    delivery_text: str | None = None
    seller_name: str | None = None


class OrderItemOut(ORMModel):
    id: int
    medicine_id: str
    medicine_name: str
    medicine_image_url: str | None = None
    quantity: int
    unit_price: float
    total_price: float


class OrderOut(ORMModel):
    id: int
    status: str
    total_amount: float
    currency: str
    delivery_type: str
    notes: str | None
    created_at: datetime
    items: list[OrderItemOut]
