from typing import TYPE_CHECKING

from sqlalchemy import JSON, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.medicine import Medicine
    from app.models.seller import Seller


class SellerOffer(Base):
    """Предложение продавца на конкретный препарат (цена, доставка)."""

    __tablename__ = "seller_offers"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    medicine_id: Mapped[str] = mapped_column(String(64), ForeignKey("medicines.id"), index=True)
    seller_id: Mapped[str] = mapped_column(String(64), ForeignKey("sellers.id"), index=True)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    currency: Mapped[str] = mapped_column(String(8), nullable=False, default="KZT")
    delivery_text: Mapped[str] = mapped_column(Text, nullable=False, default="")
    tags: Mapped[list | None] = mapped_column(JSON, nullable=True)

    medicine: Mapped["Medicine"] = relationship("Medicine", back_populates="seller_offers")
    seller: Mapped["Seller"] = relationship("Seller", lazy="joined")
