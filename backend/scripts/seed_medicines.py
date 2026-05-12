#!/usr/bin/env python3
"""
Загрузка демо-лекарств (и опционально тестового пользователя) в PostgreSQL.

Запуск из папки backend (с активированным venv):

    cd backend
    source .venv/bin/activate
    PYTHONPATH=. python scripts/seed_medicines.py

Перед этим: docker compose up -d && один раз запустите API (создаст таблицы)
или скрипт сам вызовет create_all.
"""

from __future__ import annotations

import sys
from pathlib import Path

# корень backend на PYTHONPATH
_backend_root = Path(__file__).resolve().parent.parent
if str(_backend_root) not in sys.path:
    sys.path.insert(0, str(_backend_root))

import bcrypt
from sqlalchemy.orm import Session

from app.database import Base, SessionLocal, engine
from app.models.faq import Faq
from app.models.medicine import Medicine
from app.models.seller import Seller
from app.models.seller_offer import SellerOffer
from app.models.user import User


def _hash_demo_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


INDICATION_LABELS: dict[str, str] = {
    "paracetamol": "Для головной боли",
    "analgin": "Для зубной боли",
    "nurofen": "Для головной боли",
    "ibuprofen": "Для головной боли",
    "aspirin": "Для головной боли",
    "naiz": "Для зубной боли",
    "mildronate": "Для сердечной боли",
    "concor": "Для сердечной боли",
}

# Категории: head | heart | teeth (как в ТЗ)
MEDICINES: list[dict] = [
    {
        "id": "paracetamol",
        "name": "Парацетамол",
        "category": "head",
        "subcategory": "painkiller",
        "active_ingredients": ["парацетамол"],
        "allergen_tags": ["analgesic"],
        "analog_ids": ["analgin", "naiz"],
        "description": "Жаропонижающее и обезболивающее средство.",
        "dosage": "500–1000 мг",
        "instructions": "Принимать по показаниям, не превышать суточную дозу.",
        "restrictions": "С осторожностью при заболеваниях печени.",
        "image_url": None,
        "price": 350.0,
    },
    {
        "id": "analgin",
        "name": "Анальгин",
        "category": "teeth",
        "subcategory": "painkiller",
        "active_ingredients": ["метамизол натрия"],
        "allergen_tags": ["pyrazolone", "метамизол"],
        "analog_ids": ["paracetamol", "naiz"],
        "description": "Обезболивающее средство группы пиразолонов.",
        "dosage": "по инструкции",
        "instructions": "После еды, курс по назначению врача.",
        "restrictions": "Не сочетать с алкоголем без консультации врача.",
        "image_url": None,
        "price": 430.0,
    },
    {
        "id": "nurofen",
        "name": "Нурофен",
        "category": "head",
        "subcategory": "painkiller",
        "active_ingredients": ["ибупрофен"],
        "allergen_tags": ["nsaid", "ibuprofen"],
        "analog_ids": ["paracetamol", "analgin", "naiz"],
        "description": "НПВП с обезболивающим и противовоспалительным действием.",
        "dosage": "200–400 мг",
        "instructions": "После еды.",
        "restrictions": "Противопоказания по ЖКТ; не смешивать с алкоголем.",
        "image_url": None,
        "price": 650.0,
    },
    {
        "id": "ibuprofen",
        "name": "Ибупрофен",
        "category": "head",
        "subcategory": "painkiller",
        "active_ingredients": ["ибупрофен"],
        "allergen_tags": ["nsaid"],
        "analog_ids": ["paracetamol", "analgin"],
        "description": "Генерик ибупрофена.",
        "dosage": "200 мг",
        "instructions": "После еды, интервал между приёмами не менее 4–6 ч.",
        "restrictions": "См. инструкцию; осторожно при язве ЖКТ.",
        "image_url": None,
        "price": 420.0,
    },
    {
        "id": "aspirin",
        "name": "Аспирин",
        "category": "head",
        "subcategory": "painkiller",
        "active_ingredients": ["ацетилсалициловая кислота"],
        "allergen_tags": ["nsaid", "salicylate"],
        "analog_ids": ["paracetamol", "ibuprofen"],
        "description": "НПВП; также антиагрегант в низких дозах.",
        "dosage": "по инструкции",
        "instructions": "После еды.",
        "restrictions": "Детям не назначать без врача; осторожность при астме.",
        "image_url": None,
        "price": 280.0,
    },
    {
        "id": "naiz",
        "name": "Найз",
        "category": "teeth",
        "subcategory": "painkiller",
        "active_ingredients": ["нимесулид"],
        "allergen_tags": ["nsaid"],
        "analog_ids": ["paracetamol", "analgin"],
        "description": "НПВП из группы сульфонанилидов.",
        "dosage": "100 мг",
        "instructions": "После еды, краткий курс.",
        "restrictions": "Противопоказания по печени; не с алкоголем.",
        "image_url": None,
        "price": 890.0,
    },
    {
        "id": "mildronate",
        "name": "Милдронат",
        "category": "heart",
        "subcategory": "cardio_metabolic",
        "active_ingredients": ["мельдоний"],
        "allergen_tags": [],
        "analog_ids": ["concor"],
        "description": "Препарат для улучшения толерантности к нагрузке (по назначению врача).",
        "dosage": "по схеме врача",
        "instructions": "Утром или в первой половине дня.",
        "restrictions": "Только по назначению специалиста.",
        "image_url": None,
        "price": 1200.0,
    },
    {
        "id": "concor",
        "name": "Конкор",
        "category": "heart",
        "subcategory": "beta_blocker",
        "active_ingredients": ["бисопролол"],
        "allergen_tags": ["beta_blocker"],
        "analog_ids": ["mildronate"],
        "description": "Селективный бета-адреноблокатор.",
        "dosage": "2.5–10 мг",
        "instructions": "Строго по назначению кардиолога.",
        "restrictions": "Не отменять резко; контроль ЧСС и АД.",
        "image_url": None,
        "price": 2100.0,
    },
]


def upsert_medicines(db: Session) -> int:
    n = 0
    for raw in MEDICINES:
        row = {
            **raw,
            "indication_label": raw.get("indication_label") or INDICATION_LABELS.get(raw["id"]),
        }
        m = db.get(Medicine, row["id"])
        if m is None:
            db.add(Medicine(**row))
            n += 1
        else:
            for key, val in row.items():
                setattr(m, key, val)
            n += 1
    return n


SELLERS: list[dict] = [
    {"id": "amir", "name": "Амир и Д", "rating": 5.0, "review_count": 444},
    {"id": "sadykhan", "name": "Садыхан", "rating": 4.0, "review_count": 120},
    {"id": "zhasulan", "name": "Жасұлан", "rating": 4.5, "review_count": 89},
    {"id": "europharma", "name": "Europharma", "rating": 4.8, "review_count": 512},
]


def upsert_sellers_and_offers(db: Session) -> None:
    for s in SELLERS:
        ex = db.get(Seller, s["id"])
        if ex is None:
            db.add(Seller(**s))
        else:
            for k, v in s.items():
                setattr(ex, k, v)

    # Предложения: для Анальгина — полный макет «Продавцы»; для остальных — 2 продавца (чтобы список не был пустым).
    analgin_offers = [
        ("amir", 430.0, "Доставка, 19 апреля, бесплатно", ["delivery", "express", "today"]),
        ("sadykhan", 410.0, "Доставка, 20 апреля, бесплатно", ["delivery", "today"]),
        ("zhasulan", 450.0, "Доставка, Express за 3 часа", ["express", "today"]),
        ("europharma", 399.0, "Самовывоз сегодня", ["today"]),
    ]
    def upsert_offer(mid: str, seller_id: str, price: float, delivery: str, tags: list[str]) -> None:
        exists = (
            db.query(SellerOffer)
            .filter(SellerOffer.medicine_id == mid, SellerOffer.seller_id == seller_id)
            .first()
        )
        if exists:
            exists.price = price
            exists.delivery_text = delivery
            exists.tags = tags
        else:
            db.add(
                SellerOffer(
                    medicine_id=mid,
                    seller_id=seller_id,
                    price=price,
                    currency="KZT",
                    delivery_text=delivery,
                    tags=tags,
                )
            )

    for seller_id, price, delivery, tags in analgin_offers:
        upsert_offer("analgin", seller_id, price, delivery, tags)

    for m in MEDICINES:
        mid = m["id"]
        if mid == "analgin":
            continue
        base = float(m.get("price") or 400)
        upsert_offer(mid, "amir", round(base, 2), "Доставка, завтра, бесплатно", ["delivery", "today"])
        upsert_offer(
            mid,
            "europharma",
            round(max(base * 0.92, 50), 2),
            "Самовывоз, сегодня",
            ["today"],
        )


FAQ_SEED: list[tuple[str, str, int]] = [
    (
        "Как оказать первую помощь?",
        "Вызовите 112/103, обеспечьте безопасность места, проверьте дыхание и пульс, при необходимости начните СЛР по алгоритму.",
        1,
    ),
    (
        "Что такое коронавирус?",
        "Инфекционное заболевание, вызываемое вирусом SARS-CoV-2. У большинства людей — лёгкие симптомы дыхательных путей.",
        2,
    ),
    (
        "Как перевязать руку?",
        "Используйте стерильный бинт, накладывайте повязку без пережатия конечности; при сильном кровотечении — жгут со временем.",
        3,
    ),
    (
        "Что такое чума?",
        "Острое инфекционное заболевание, исторически вызываемое бактерией Yersinia pestis; вакцинация и санитария снижают риск.",
        4,
    ),
]


def seed_faqs(db: Session) -> None:
    if db.query(Faq).count() > 0:
        return
    for q, a, order in FAQ_SEED:
        db.add(Faq(question=q, answer=a, sort_order=order, is_active=True))


def ensure_demo_user(db: Session) -> None:
    # .local в домене не проходит Pydantic EmailStr / email-validator
    email = "demo@example.com"
    legacy = "demo@medi.local"
    pw = _hash_demo_password("demo123")

    def _apply_demo_fields(u: User) -> None:
        u.hashed_password = pw
        u.full_name = "Демо Пользователь"
        u.first_name = "Демо"
        u.last_name = "Пользователь"
        u.onboarding_completed = True
        u.allergy_types = ["medicinal"]
        u.allergen_substances = ["ибупрофен", "аспирин", "диклофенак", "метамизол"]

    # Важно: сначала ищем целевой email в БД. Нельзя сначала переименовывать legacy без flush —
    # иначе повторный SELECT не увидит строку и попытка INSERT даст UNIQUE.
    u = db.query(User).filter(User.email == email).one_or_none()
    if u is not None:
        _apply_demo_fields(u)
        legacy_u = db.query(User).filter(User.email == legacy).one_or_none()
        if legacy_u is not None and legacy_u.id != u.id:
            db.delete(legacy_u)
        print(f"Демо-пользователь обновлён: {email} / пароль: demo123")
        return

    old = db.query(User).filter(User.email == legacy).one_or_none()
    if old is not None:
        old.email = email
        _apply_demo_fields(old)
        print(f"Почта обновлена {legacy} → {email}, пароль: demo123")
        return

    db.add(
        User(
            email=email,
            hashed_password=pw,
            full_name="Демо Пользователь",
            first_name="Демо",
            last_name="Пользователь",
            onboarding_completed=True,
            allergy_types=["medicinal"],
            allergen_substances=["ибупрофен", "аспирин", "диклофенак", "метамизол"],
        )
    )
    print(f"Создан пользователь: {email} / пароль: demo123 (только для локального MVP)")


def main() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        upsert_medicines(db)
        upsert_sellers_and_offers(db)
        seed_faqs(db)
        ensure_demo_user(db)
        db.commit()
        print(f"Готово: лекарства {len(MEDICINES)} шт., продавцы, офферы, FAQ, демо-пользователь.")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
