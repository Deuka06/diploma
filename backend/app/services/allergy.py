from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy.orm import Session

from app.models.medicine import Medicine

if TYPE_CHECKING:
    from app.models.user import User


def _norm(s: str) -> str:
    return s.strip().lower()


def find_conflicting_substance(
    active_ingredients: list[str],
    user_substances: list[str] | None,
) -> str | None:
    if not user_substances:
        return None
    allergens = [_norm(a) for a in user_substances if a]
    for ing in active_ingredients:
        ni = _norm(ing)
        for al in allergens:
            if al in ni or ni in al:
                return al
    return None


def medicine_is_safe_for_user(medicine: Medicine, user_substances: list[str] | None) -> bool:
    return find_conflicting_substance(list(medicine.active_ingredients or []), user_substances) is None


def find_safe_alternatives(
    db: Session,
    *,
    category: str,
    user_substances: list[str] | None,
    exclude_medicine_id: str | None = None,
    limit: int = 5,
) -> list[Medicine]:
    q = db.query(Medicine).filter(Medicine.category == category)
    if exclude_medicine_id:
        q = q.filter(Medicine.id != exclude_medicine_id)
    candidates: list[Medicine] = q.all()
    safe: list[Medicine] = []
    for m in candidates:
        if medicine_is_safe_for_user(m, user_substances):
            safe.append(m)
        if len(safe) >= limit:
            break
    return safe


def build_safety_payload(db: Session, medicine: Medicine, user: User | None) -> dict:
    substances = user.allergen_substances if user and user.allergen_substances else None
    conflict = find_conflicting_substance(list(medicine.active_ingredients or []), substances)
    is_recommended = conflict is None
    alternatives: list[Medicine] = []
    if not is_recommended:
        alternatives = find_safe_alternatives(
            db,
            category=medicine.category,
            user_substances=substances,
            exclude_medicine_id=medicine.id,
            limit=5,
        )
    warning = None
    if conflict:
        warning = f"Сізде аллергия бар {conflict} құрамында бар"
    return {
        "is_recommended": is_recommended,
        "conflict_allergen": conflict,
        "warning_message": warning,
        "alternatives": alternatives,
    }
