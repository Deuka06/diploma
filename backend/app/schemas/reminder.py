from datetime import datetime, time

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class ReminderIn(BaseModel):
    medicine_name: str = Field(max_length=255)
    dosage: str | None = Field(default=None, max_length=128)
    reminder_time: time
    days_of_week: str = Field(default="1,2,3,4,5,6,7", max_length=32)
    treatment_id: int | None = None
    is_active: bool = True


class ReminderOut(ORMModel):
    id: int
    medicine_name: str
    dosage: str | None
    reminder_time: time
    days_of_week: str
    treatment_id: int | None
    is_active: bool
    notification_sent: bool
    created_at: datetime
