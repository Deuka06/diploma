from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps_auth import get_current_user
from app.models.appointment import Appointment
from app.models.user import User
from app.schemas.appointment import AppointmentIn, AppointmentOut

router = APIRouter(prefix="/appointments", tags=["appointments"])


@router.get("", response_model=list[AppointmentOut])
def list_appointments(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[AppointmentOut]:
    rows = (
        db.query(Appointment)
        .filter(Appointment.user_id == user.id)
        .order_by(Appointment.appointment_date.desc(), Appointment.appointment_time.desc())
        .all()
    )
    return [AppointmentOut.model_validate(r) for r in rows]


@router.post("", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
def create_appointment(
    body: AppointmentIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> AppointmentOut:
    appt = Appointment(
        user_id=user.id,
        doctor_name=body.doctor_name,
        specialty=body.specialty,
        clinic_name=body.clinic_name,
        clinic_address=body.clinic_address,
        appointment_date=body.appointment_date,
        appointment_time=body.appointment_time,
        duration_minutes=body.duration_minutes,
        notes=body.notes,
        status=body.status,
    )
    db.add(appt)
    db.commit()
    db.refresh(appt)
    return AppointmentOut.model_validate(appt)


@router.patch("/{appointment_id}", response_model=AppointmentOut)
def update_appointment(
    appointment_id: int,
    body: AppointmentIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> AppointmentOut:
    appt = db.get(Appointment, appointment_id)
    if appt is None or appt.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Запись не найдена")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(appt, k, v)
    db.commit()
    db.refresh(appt)
    return AppointmentOut.model_validate(appt)


@router.delete("/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> None:
    appt = db.get(Appointment, appointment_id)
    if appt is None or appt.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Запись не найдена")
    db.delete(appt)
    db.commit()
