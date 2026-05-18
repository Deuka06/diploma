from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.schemas.common import ORMModel


class UserOut(ORMModel):
    id: int
    email: EmailStr
    full_name: str | None
    first_name: str | None
    last_name: str | None
    phone: str | None
    avatar_url: str | None
    gender: str | None
    age: int | None
    weight_kg: float | None
    height_cm: float | None
    blood_type: str | None
    birth_date: datetime | None
    onboarding_completed: bool
    allergy_types: list[str] | None
    allergen_substances: list[str] | None
    chronic_conditions: list[str] | None
    extra_profile: dict | None


class UserUpdateIn(BaseModel):
    full_name: str | None = Field(default=None, max_length=255)
    first_name: str | None = Field(default=None, max_length=120)
    last_name: str | None = Field(default=None, max_length=120)
    phone: str | None = Field(default=None, max_length=32)
    avatar_url: str | None = Field(default=None, max_length=512)
    gender: str | None = Field(default=None, max_length=32)
    age: int | None = None
    weight_kg: float | None = None
    height_cm: float | None = None
    blood_type: str | None = Field(default=None, max_length=8)
    birth_date: datetime | None = None
    onboarding_completed: bool | None = None
    allergy_types: list[str] | None = None
    allergen_substances: list[str] | None = None
    chronic_conditions: list[str] | None = None
    extra_profile: dict | None = None
