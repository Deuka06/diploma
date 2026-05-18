from datetime import date, datetime, time

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class AppointmentIn(BaseModel):
    doctor_name: str = Field(max_length=255)
    specialty: str = Field(max_length=128)
    clinic_name: str | None = Field(default=None, max_length=255)
    clinic_address: str | None = Field(default=None, max_length=500)
    appointment_date: date
    appointment_time: time
    duration_minutes: int = Field(default=30, ge=5, le=480)
    notes: str | None = None
    status: str = Field(default="scheduled", max_length=32)


class AppointmentOut(ORMModel):
    id: int
    doctor_name: str
    specialty: str
    clinic_name: str | None
    clinic_address: str | None
    appointment_date: date
    appointment_time: time
    duration_minutes: int
    notes: str | None
    status: str
    reminder_sent: bool
    created_at: datetime
