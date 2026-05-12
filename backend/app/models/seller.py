from sqlalchemy import Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Seller(Base):
    __tablename__ = "sellers"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    rating: Mapped[float] = mapped_column(Float, nullable=False, default=5.0)
    review_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
