import random
import string
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import get_settings
from app.database import get_db
from app.models.password_reset import PasswordResetOtp
from app.models.user import User
from app.schemas.auth import (
    ForgotPasswordIn,
    ForgotPasswordOut,
    LoginIn,
    RegisterIn,
    ResetPasswordIn,
    TokenOut,
    VerifyOtpIn,
    VerifyOtpOut,
)
from app.security import (
    create_access_token,
    create_password_reset_token,
    decode_token,
    hash_password,
    verify_password,
    verify_token_type,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenOut)
def register(body: RegisterIn, db: Session = Depends(get_db)) -> TokenOut:
    exists = db.query(User).filter(User.email == body.email.lower()).first()
    if exists:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Email уже зарегистрирован")
    user = User(
        email=body.email.lower(),
        hashed_password=hash_password(body.password),
        full_name=body.full_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return TokenOut(access_token=create_access_token(user.id))


@router.post("/login", response_model=TokenOut)
def login(body: LoginIn, db: Session = Depends(get_db)) -> TokenOut:
    user = db.query(User).filter(User.email == body.email.lower()).first()
    if user is None or not verify_password(body.password, user.hashed_password):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Неверная почта или пароль")
    return TokenOut(access_token=create_access_token(user.id))


@router.post("/forgot-password", response_model=ForgotPasswordOut)
def forgot_password(body: ForgotPasswordIn, db: Session = Depends(get_db)) -> ForgotPasswordOut:
    user = db.query(User).filter(User.email == body.email.lower()).first()
    settings = get_settings()
    code = "".join(random.choices(string.digits, k=4))
    expires = datetime.now(timezone.utc) + timedelta(minutes=10)

    if user:
        for old in db.query(PasswordResetOtp).filter(PasswordResetOtp.email == user.email).all():
            old.used = True
        db.add(PasswordResetOtp(email=user.email, code=code, expires_at=expires, used=False))
        db.commit()

    demo = code if settings.debug_demo_otp and user else None
    msg = "Если аккаунт существует, код отправлен (в MVP см. demo_code в ответе)."
    return ForgotPasswordOut(message=msg, demo_code=demo)


@router.post("/verify-otp", response_model=VerifyOtpOut)
def verify_otp(body: VerifyOtpIn, db: Session = Depends(get_db)) -> VerifyOtpOut:
    email = body.email.lower()
    row = (
        db.query(PasswordResetOtp)
        .filter(
            PasswordResetOtp.email == email,
            PasswordResetOtp.used.is_(False),
            PasswordResetOtp.code == body.code.strip(),
        )
        .order_by(PasswordResetOtp.id.desc())
        .first()
    )
    if row is None or row.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Неверный или просроченный код")
    row.used = True
    db.commit()
    return VerifyOtpOut(reset_token=create_password_reset_token(email))


@router.post("/reset-password")
def reset_password(body: ResetPasswordIn, db: Session = Depends(get_db)) -> dict[str, str]:
    try:
        payload = decode_token(body.reset_token)
        verify_token_type(payload, "pwdreset")
        email = str(payload["sub"]).lower()
    except Exception:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Недействительный токен сброса")
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Пользователь не найден")
    user.hashed_password = hash_password(body.new_password)
    db.commit()
    return {"message": "Пароль обновлён"}
