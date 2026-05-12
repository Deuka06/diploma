from pydantic import BaseModel, EmailStr, Field

from app.schemas.common import ORMModel


class UserOut(ORMModel):
    id: int
    email: EmailStr
    full_name: str | None
    first_name: str | None
    last_name: str | None
    gender: str | None
    age: int | None
    weight_kg: float | None
    height_cm: float | None
    onboarding_completed: bool
    allergy_types: list[str] | None
    allergen_substances: list[str] | None


class UserUpdateIn(BaseModel):
    full_name: str | None = Field(default=None, max_length=255)
    first_name: str | None = Field(default=None, max_length=120)
    last_name: str | None = Field(default=None, max_length=120)
    gender: str | None = Field(default=None, max_length=32)
    age: int | None = None
    weight_kg: float | None = None
    height_cm: float | None = None
    onboarding_completed: bool | None = None
    allergy_types: list[str] | None = None
    allergen_substances: list[str] | None = None
