from datetime import date

from pydantic import BaseModel, Field


class TreatmentIn(BaseModel):
    disease_name: str = Field(max_length=255)
    medicine_name: str | None = Field(default=None, max_length=255)
    medicine_id: str | None = Field(default=None, max_length=64)
    dosage: str | None = Field(default=None, max_length=128)
    frequency: str | None = Field(default=None, max_length=64)
    start_date: date
    end_date: date | None = None
    intake_time: str | None = Field(default=None, max_length=64)
    color_index: int = Field(default=0, ge=0, le=9)
    notes: str | None = None
    is_active: bool = True


class TreatmentOut(BaseModel):
    id: int
    disease_name: str
    medicine_name: str | None
    medicine_id: str | None
    dosage: str | None
    frequency: str | None
    start_date: date
    end_date: date | None
    intake_time: str | None
    color_index: int
    notes: str | None
    is_active: bool
    progress: float
    duration_days: int
    is_completed: bool
