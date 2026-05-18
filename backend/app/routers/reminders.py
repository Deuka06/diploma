from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps_auth import get_current_user
from app.models.reminder import Reminder
from app.models.user import User
from app.schemas.reminder import ReminderIn, ReminderOut

router = APIRouter(prefix="/reminders", tags=["reminders"])


@router.get("", response_model=list[ReminderOut])
def list_reminders(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[ReminderOut]:
    rows = (
        db.query(Reminder)
        .filter(Reminder.user_id == user.id)
        .order_by(Reminder.reminder_time)
        .all()
    )
    return [ReminderOut.model_validate(r) for r in rows]


@router.post("", response_model=ReminderOut, status_code=status.HTTP_201_CREATED)
def create_reminder(
    body: ReminderIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> ReminderOut:
    rem = Reminder(
        user_id=user.id,
        medicine_name=body.medicine_name,
        dosage=body.dosage,
        reminder_time=body.reminder_time,
        days_of_week=body.days_of_week,
        treatment_id=body.treatment_id,
        is_active=body.is_active,
    )
    db.add(rem)
    db.commit()
    db.refresh(rem)
    return ReminderOut.model_validate(rem)


@router.patch("/{reminder_id}", response_model=ReminderOut)
def update_reminder(
    reminder_id: int,
    body: ReminderIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> ReminderOut:
    rem = db.get(Reminder, reminder_id)
    if rem is None or rem.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Напоминание не найдено")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(rem, k, v)
    db.commit()
    db.refresh(rem)
    return ReminderOut.model_validate(rem)


@router.delete("/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_reminder(
    reminder_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> None:
    rem = db.get(Reminder, reminder_id)
    if rem is None or rem.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Напоминание не найдено")
    db.delete(rem)
    db.commit()
