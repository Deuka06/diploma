from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps_auth import get_current_user
from app.models.treatment import Treatment
from app.models.user import User
from app.schemas.treatment import TreatmentIn, TreatmentOut, TreatmentProgressPatch

router = APIRouter(prefix="/treatments", tags=["treatments"])


def _to_out(t: Treatment) -> TreatmentOut:
    today = date.today()
    if t.end_date:
        duration_days = (t.end_date - t.start_date).days
    else:
        duration_days = 0

    if t.manual_progress is not None:
        progress = round(min(max(t.manual_progress, 0.0), 1.0), 2)
        is_completed = progress >= 1.0
    elif t.end_date:
        total = max(duration_days, 1)
        elapsed = max((today - t.start_date).days, 0)
        progress = round(min(elapsed / total, 1.0), 2)
        is_completed = progress >= 1.0
    else:
        progress = 0.0
        is_completed = False
    return TreatmentOut(
        id=t.id,
        disease_name=t.disease_name,
        medicine_name=t.medicine_name,
        medicine_id=t.medicine_id,
        dosage=t.dosage,
        frequency=t.frequency,
        start_date=t.start_date,
        end_date=t.end_date,
        intake_time=t.intake_time,
        color_index=t.color_index,
        notes=t.notes,
        is_active=t.is_active,
        progress=progress,
        duration_days=duration_days,
        is_completed=is_completed,
    )


@router.get("", response_model=list[TreatmentOut])
def list_treatments(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[TreatmentOut]:
    rows = (
        db.query(Treatment)
        .filter(Treatment.user_id == user.id)
        .order_by(Treatment.start_date.desc())
        .all()
    )
    return [_to_out(r) for r in rows]


@router.post("", response_model=TreatmentOut, status_code=status.HTTP_201_CREATED)
def create_treatment(
    body: TreatmentIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> TreatmentOut:
    t = Treatment(
        user_id=user.id,
        disease_name=body.disease_name,
        medicine_name=body.medicine_name,
        medicine_id=body.medicine_id,
        dosage=body.dosage,
        frequency=body.frequency,
        start_date=body.start_date,
        end_date=body.end_date,
        intake_time=body.intake_time,
        color_index=body.color_index,
        notes=body.notes,
        is_active=body.is_active,
    )
    db.add(t)
    db.commit()
    db.refresh(t)
    return _to_out(t)


@router.patch("/{treatment_id}/progress", response_model=TreatmentOut)
def update_treatment_progress(
    treatment_id: int,
    body: TreatmentProgressPatch,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> TreatmentOut:
    t = db.get(Treatment, treatment_id)
    if t is None or t.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Лечение не найдено")
    t.manual_progress = round(min(max(body.progress, 0.0), 1.0), 4)
    db.commit()
    db.refresh(t)
    return _to_out(t)


@router.delete("/{treatment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_treatment(
    treatment_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> None:
    t = db.get(Treatment, treatment_id)
    if t is None or t.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Лечение не найдено")
    db.delete(t)
    db.commit()
