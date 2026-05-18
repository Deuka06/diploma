from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.appointment import Appointment
    from app.models.chat_message import ChatMessage
    from app.models.order import Order
    from app.models.reminder import Reminder
    from app.models.review import Review
    from app.models.treatment import Treatment


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    first_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    gender: Mapped[str | None] = mapped_column(String(32), nullable=True)
    age: Mapped[int | None] = mapped_column(nullable=True)
    weight_kg: Mapped[float | None] = mapped_column(nullable=True)
    height_cm: Mapped[float | None] = mapped_column(nullable=True)
    blood_type: Mapped[str | None] = mapped_column(String(8), nullable=True)
    birth_date: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    onboarding_completed: Mapped[bool] = mapped_column(default=False)

    allergy_types: Mapped[list | None] = mapped_column(JSON, nullable=True)
    allergen_substances: Mapped[list | None] = mapped_column(JSON, nullable=True)
    chronic_conditions: Mapped[list | None] = mapped_column(JSON, nullable=True)

    extra_profile: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    treatments: Mapped[list["Treatment"]] = relationship("Treatment", back_populates="user")
    orders: Mapped[list["Order"]] = relationship("Order", back_populates="user")
    reminders: Mapped[list["Reminder"]] = relationship("Reminder", back_populates="user")
    appointments: Mapped[list["Appointment"]] = relationship("Appointment", back_populates="user")
    reviews: Mapped[list["Review"]] = relationship("Review", back_populates="user")
    chat_messages: Mapped[list["ChatMessage"]] = relationship("ChatMessage", back_populates="user")
