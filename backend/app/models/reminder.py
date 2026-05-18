from datetime import datetime, time
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Time, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.treatment import Treatment
    from app.models.user import User


class Reminder(Base):
    """Напоминание о приёме лекарства."""

    __tablename__ = "reminders"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True, nullable=False)
    treatment_id: Mapped[int | None] = mapped_column(ForeignKey("treatments.id"), nullable=True)
    medicine_name: Mapped[str] = mapped_column(String(255), nullable=False)
    dosage: Mapped[str | None] = mapped_column(String(128), nullable=True)
    reminder_time: Mapped[time] = mapped_column(Time, nullable=False)
    days_of_week: Mapped[str] = mapped_column(String(32), nullable=False, default="1,2,3,4,5,6,7")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    notification_sent: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship("User", back_populates="reminders")
    treatment: Mapped["Treatment | None"] = relationship("Treatment", back_populates="reminders")
