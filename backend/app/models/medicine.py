from typing import TYPE_CHECKING

from sqlalchemy import Boolean, ForeignKey, Integer, JSON, Float, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.category import Category
    from app.models.review import Review
    from app.models.seller_offer import SellerOffer


class Medicine(Base):
    __tablename__ = "medicines"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    name_kz: Mapped[str | None] = mapped_column(String(255), nullable=True)
    indication_label: Mapped[str | None] = mapped_column(String(255), nullable=True)
    category: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"), nullable=True)
    subcategory: Mapped[str | None] = mapped_column(String(64), nullable=True)
    manufacturer: Mapped[str | None] = mapped_column(String(255), nullable=True)
    country: Mapped[str | None] = mapped_column(String(64), nullable=True)
    form: Mapped[str | None] = mapped_column(String(64), nullable=True)
    prescription_required: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    active_ingredients: Mapped[list] = mapped_column(JSON, nullable=False)
    allergen_tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    analog_ids: Mapped[list | None] = mapped_column(JSON, nullable=True)

    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    dosage: Mapped[str | None] = mapped_column(Text, nullable=True)
    instructions: Mapped[str | None] = mapped_column(Text, nullable=True)
    restrictions: Mapped[str | None] = mapped_column(Text, nullable=True)
    side_effects: Mapped[str | None] = mapped_column(Text, nullable=True)
    contraindications: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    price: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    stock_quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    rating: Mapped[float] = mapped_column(Float, nullable=False, default=4.5)
    review_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    extra: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    category_ref: Mapped["Category | None"] = relationship("Category")
    reviews: Mapped[list["Review"]] = relationship("Review", back_populates="medicine")
    seller_offers: Mapped[list["SellerOffer"]] = relationship("SellerOffer", back_populates="medicine")
