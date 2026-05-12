from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps_auth import get_current_user, get_current_user_optional
from app.models.medicine import Medicine
from app.models.user import User
from app.schemas.medicine import CategoryOut, MedicineBrief, MedicineDetail, MedicineSafetyOut
from app.services.allergy import build_safety_payload

router = APIRouter(prefix="/medicines", tags=["medicines"])

CATEGORIES: list[CategoryOut] = [
    CategoryOut(id="heart", label="Сердце"),
    CategoryOut(id="teeth", label="Зубы"),
    CategoryOut(id="head", label="Голова"),
]


@router.get("/categories", response_model=list[CategoryOut])
def list_categories() -> list[CategoryOut]:
    return CATEGORIES


@router.get("", response_model=list[MedicineBrief])
def list_medicines(
    category: str | None = Query(default=None),
    q: str | None = Query(default=None, description="Поиск по названию"),
    db: Session = Depends(get_db),
) -> list[Medicine]:
    query = db.query(Medicine)
    if category:
        query = query.filter(Medicine.category == category)
    items = query.order_by(Medicine.name).all()
    if q:
        qq = q.strip().lower()
        items = [m for m in items if qq in m.name.lower()]
    return items


@router.get("/{medicine_id}", response_model=MedicineDetail)
def get_medicine(medicine_id: str, db: Session = Depends(get_db)) -> Medicine:
    m = db.get(Medicine, medicine_id)
    if m is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Препарат не найден")
    return m


@router.get("/{medicine_id}/safety", response_model=MedicineSafetyOut)
def medicine_safety(
    medicine_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> MedicineSafetyOut:
    m = db.get(Medicine, medicine_id)
    if m is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Препарат не найден")
    payload = build_safety_payload(db, m, user)
    alts = [MedicineBrief.model_validate(x) for x in payload["alternatives"]]
    return MedicineSafetyOut(
        is_recommended=payload["is_recommended"],
        conflict_allergen=payload["conflict_allergen"],
        warning_message=payload["warning_message"],
        alternatives=alts,
    )


@router.get("/{medicine_id}/safety/public", response_model=MedicineSafetyOut)
def medicine_safety_public(
    medicine_id: str,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_current_user_optional),
) -> MedicineSafetyOut:
    """Без обязательного токена: если не авторизован — считаем без аллергий."""
    m = db.get(Medicine, medicine_id)
    if m is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Препарат не найден")
    payload = build_safety_payload(db, m, user)
    alts = [MedicineBrief.model_validate(x) for x in payload["alternatives"]]
    return MedicineSafetyOut(
        is_recommended=payload["is_recommended"],
        conflict_allergen=payload["conflict_allergen"],
        warning_message=payload["warning_message"],
        alternatives=alts,
    )
