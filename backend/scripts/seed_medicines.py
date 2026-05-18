#!/usr/bin/env python3
"""
Загрузка демо-лекарств в Supabase PostgreSQL.

Запуск из папки backend (с активированным venv):
    cd backend
    source .venv/bin/activate
    PYTHONPATH=. python scripts/seed_medicines.py
"""

from __future__ import annotations

import sys
from datetime import date
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
from app.models.treatment import Treatment
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

# Категории: head | heart | teeth | painkillers | vitamins | antibiotics
MEDICINES: list[dict] = [
    # Головная боль (head)
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
        "image_url": "assets/med1.png",
        "price": 350.0,
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
        "image_url": "assets/med3.png",
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
        "image_url": "assets/med4.png",
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
        "image_url": "assets/med5.png",
        "price": 280.0,
    },
    # Зубная боль (teeth)
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
        "image_url": "assets/med2.png",
        "price": 430.0,
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
        "image_url": "assets/med6.png",
        "price": 890.0,
    },
    {
        "id": "ketanov",
        "name": "Кетанов",
        "category": "teeth",
        "subcategory": "painkiller",
        "active_ingredients": ["кеторолак"],
        "allergen_tags": ["nsaid", "keterolac"],
        "analog_ids": ["analgin", "naiz"],
        "description": "Сильное НПВП обезболивающее, применяется при зубной боли.",
        "dosage": "10 мг",
        "instructions": "После еды, краткосрочный курс, не более 5 дней.",
        "restrictions": "Противопоказан при кровотечениях, язве желудка.",
        "image_url": "assets/med9.png",
        "price": 520.0,
    },
    # Сердце (heart)
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
        "image_url": "assets/med7.png",
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
        "image_url": "assets/med8.png",
        "price": 2100.0,
    },
    {
        "id": "ronocit",
        "name": "Роноцит",
        "category": "heart",
        "subcategory": "cardio_metabolic",
        "active_ingredients": ["цитиколин"],
        "allergen_tags": [],
        "analog_ids": ["mildronate"],
        "description": "Ноотропный препарат для улучшения кровообращения мозга.",
        "dosage": "500–2000 мг/сут",
        "instructions": "Утром, по назначению врача.",
        "restrictions": "Только по назначению.",
        "image_url": "assets/med10.png",
        "price": 1850.0,
    },
    # Обезболивающие (painkillers)
    {
        "id": "pentalgin",
        "name": "Пенталгин",
        "category": "painkillers",
        "subcategory": "painkiller",
        "active_ingredients": ["парацетамол", "напроксен", "кофеин", "дротаверин"],
        "allergen_tags": ["nsaid", "analgesic"],
        "analog_ids": ["paracetamol", "ibuprofen"],
        "description": "Комбинированный анальгетик для снятия боли разного характера.",
        "dosage": "1 таблетка",
        "instructions": "После еды, не более 3 таблеток в сутки.",
        "restrictions": "Не применять при ЖКТ-проблемах.",
        "image_url": "assets/med1.png",
        "price": 480.0,
    },
    {
        "id": "no-shpa",
        "name": "Но-шпа",
        "category": "painkillers",
        "subcategory": "antispasmodic",
        "active_ingredients": ["дротаверин"],
        "allergen_tags": [],
        "analog_ids": ["pentalgin"],
        "description": "Спазмолитик для снятия спазмов гладкой мускулатуры.",
        "dosage": "40–80 мг",
        "instructions": "При болях, не более 240 мг/сут.",
        "restrictions": "С осторожностью при гипотонии.",
        "image_url": "assets/med2.png",
        "price": 320.0,
    },
    {
        "id": "nimesil",
        "name": "Нимесил",
        "category": "painkillers",
        "subcategory": "painkiller",
        "active_ingredients": ["нимесулид"],
        "allergen_tags": ["nsaid"],
        "analog_ids": ["naiz", "ketanov"],
        "description": "Противовоспалительное и обезболивающее средство.",
        "dosage": "100 мг (1 пакетик)",
        "instructions": "Растворить в воде, после еды.",
        "restrictions": "Не более 2 пакетиков в сутки, не для длительного применения.",
        "image_url": "assets/med3.png",
        "price": 720.0,
    },
    # Витамины (vitamins)
    {
        "id": "vitamin-c",
        "name": "Витамин C",
        "category": "vitamins",
        "subcategory": "vitamin",
        "active_ingredients": ["аскорбиновая кислота"],
        "allergen_tags": [],
        "analog_ids": ["vitamin-d3", "multivitamin"],
        "description": "Укрепляет иммунитет и антиоксидантную защиту организма.",
        "dosage": "500–1000 мг",
        "instructions": "После еды.",
        "restrictions": "С осторожностью при гастрите.",
        "image_url": "assets/med4.png",
        "price": 250.0,
    },
    {
        "id": "vitamin-d3",
        "name": "Витамин D3",
        "category": "vitamins",
        "subcategory": "vitamin",
        "active_ingredients": ["холекальциферол"],
        "allergen_tags": [],
        "analog_ids": ["vitamin-c", "multivitamin"],
        "description": "Поддерживает здоровье костей и иммунной системы.",
        "dosage": "1000–2000 МЕ",
        "instructions": "Во время еды с жирной пищей.",
        "restrictions": "Не превышать дозу без контроля анализов.",
        "image_url": "assets/med5.png",
        "price": 450.0,
    },
    {
        "id": "multivitamin",
        "name": "Мультивитамины",
        "category": "vitamins",
        "subcategory": "vitamin",
        "active_ingredients": ["комплекс витаминов"],
        "allergen_tags": [],
        "analog_ids": ["vitamin-c", "vitamin-d3"],
        "description": "Комплекс витаминов и минералов для поддержания здоровья.",
        "dosage": "1 таблетка",
        "instructions": "После еды, ежедневно.",
        "restrictions": "Не сочетать с другими витаминными комплексами.",
        "image_url": "assets/med6.png",
        "price": 680.0,
    },
    {
        "id": "omega-3",
        "name": "Омега-3",
        "category": "vitamins",
        "subcategory": "supplement",
        "active_ingredients": ["рыбий жир", "ЭПК", "ДГК"],
        "allergen_tags": ["fish"],
        "analog_ids": ["multivitamin"],
        "description": "Полезные жирные кислоты для сердца и мозга.",
        "dosage": "1–2 капсулы",
        "instructions": "После еды.",
        "restrictions": "С осторожностью при аллергии на рыбу.",
        "image_url": "assets/med7.png",
        "price": 890.0,
    },
    # Антибиотики (antibiotics)
    {
        "id": "amoxicillin",
        "name": "Амоксициллин",
        "category": "antibiotics",
        "subcategory": "penicillin",
        "active_ingredients": ["амоксициллин"],
        "allergen_tags": ["penicillin", "antibiotic"],
        "analog_ids": ["azithromycin", "ciprofloxacin"],
        "description": "Антибиотик пенициллинового ряда широкого спектра.",
        "dosage": "500 мг",
        "instructions": "3 раза в день, независимо от еды, курс 5–7 дней.",
        "restrictions": "Противопоказан при аллергии на пенициллин.",
        "image_url": "assets/med8.png",
        "price": 280.0,
    },
    {
        "id": "azithromycin",
        "name": "Азитромицин",
        "category": "antibiotics",
        "subcategory": "macrolide",
        "active_ingredients": ["азитромицин"],
        "allergen_tags": ["macrolide", "antibiotic"],
        "analog_ids": ["amoxicillin", "ciprofloxacin"],
        "description": "Макролидный антибиотик с длительным действием.",
        "dosage": "500 мг",
        "instructions": "1 раз в день, 3 дня.",
        "restrictions": "С осторожностью при заболеваниях печени.",
        "image_url": "assets/med9.png",
        "price": 420.0,
    },
    {
        "id": "ciprofloxacin",
        "name": "Ципрофлоксацин",
        "category": "antibiotics",
        "subcategory": "fluoroquinolone",
        "active_ingredients": ["ципрофлоксацин"],
        "allergen_tags": ["fluoroquinolone", "antibiotic"],
        "analog_ids": ["amoxicillin", "azithromycin"],
        "description": "Фторхинолоновый антибиотик для лечения инфекций.",
        "dosage": "500 мг",
        "instructions": "2 раза в день, запивая большим количеством воды.",
        "restrictions": "Противопоказан детям и беременным.",
        "image_url": "assets/med10.png",
        "price": 350.0,
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
        u.full_name = "Медет Махамбетхан"
        u.first_name = "Медет"
        u.last_name = "Махамбетхан"
        u.gender = "male"
        u.age = 21
        u.weight_kg = 72.0
        u.height_cm = 178.0
        u.onboarding_completed = True
        u.allergy_types = ["food", "drug"]
        u.allergen_substances = ["ибупрофен", "аспирин", "пенициллин"]

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
            full_name="Медет Махамбетхан",
            first_name="Медет",
            last_name="Махамбетхан",
            gender="male",
            age=21,
            weight_kg=72.0,
            height_cm=178.0,
            onboarding_completed=True,
            allergy_types=["food", "drug"],
            allergen_substances=["ибупрофен", "аспирин", "пенициллин"],
        )
    )
    print(f"Создан пользователь: {email} / пароль: demo123 (только для локального MVP)")


DEMO_TREATMENTS: list[dict] = [
    # Активные (показываются на главной)
    {
        "disease_name": "Грипп",
        "medicine_name": "Парацетамол",
        "start_date": date(2026, 5, 4),
        "end_date": date(2026, 5, 24),
        "intake_time": "19:00 – 20:00",
        "color_index": 0,
    },
    {
        "disease_name": "Витаминный курс",
        "medicine_name": "Витамин С",
        "start_date": date(2026, 5, 10),
        "end_date": date(2026, 6, 1),
        "intake_time": "19:00 – 20:00",
        "color_index": 1,
    },
    {
        "disease_name": "Профилактика",
        "medicine_name": "Аспирин",
        "start_date": date(2026, 5, 14),
        "end_date": date(2026, 5, 28),
        "intake_time": "08:00 – 08:30",
        "color_index": 2,
    },
    # Завершённые (показываются в обзоре)
    {
        "disease_name": "Насморк",
        "medicine_name": "Нурофен",
        "start_date": date(2026, 4, 11),
        "end_date": date(2026, 4, 18),
        "intake_time": "08:00 – 09:00",
        "color_index": 1,
    },
    {
        "disease_name": "Головная боль",
        "medicine_name": "Аспирин",
        "start_date": date(2026, 3, 15),
        "end_date": date(2026, 3, 23),
        "intake_time": "12:00 – 13:00",
        "color_index": 2,
    },
]


def seed_treatments(db: Session) -> None:
    user = db.query(User).filter(User.email == "demo@example.com").one_or_none()
    if user is None:
        return
    if db.query(Treatment).filter(Treatment.user_id == user.id).count() > 0:
        return
    for t in DEMO_TREATMENTS:
        db.add(Treatment(user_id=user.id, **t))
    print(f"Создано {len(DEMO_TREATMENTS)} демо-лечений для {user.email}")


def main() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        upsert_medicines(db)
        upsert_sellers_and_offers(db)
        seed_faqs(db)
        ensure_demo_user(db)
        db.commit()
        seed_treatments(db)
        db.commit()
        print(f"Готово: лекарства {len(MEDICINES)} шт., продавцы, офферы, FAQ, демо-пользователь, лечения.")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
