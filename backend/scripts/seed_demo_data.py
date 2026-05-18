#!/usr/bin/env python3
"""Заполнение базы данных демо-данными для презентации дипломного проекта."""

import sys
from datetime import date, datetime, time, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.database import Base, SessionLocal, engine
from app.models import (
    Appointment,
    Category,
    ChatMessage,
    Faq,
    Medicine,
    Order,
    OrderItem,
    Pharmacy,
    Reminder,
    Review,
    Seller,
    SellerOffer,
    Treatment,
    User,
)
from app.security import hash_password


def create_tables():
    """Создать все таблицы."""
    Base.metadata.create_all(bind=engine)
    print("Таблицы созданы успешно!")


def seed_categories(db):
    """Заполнить категории лекарств."""
    categories = [
        Category(id=1, name="Обезболивающие", name_kz="Ауырсынуға қарсы", slug="painkillers", icon="pill", sort_order=1),
        Category(id=2, name="Антибиотики", name_kz="Антибиотиктер", slug="antibiotics", icon="capsule", sort_order=2),
        Category(id=3, name="Витамины", name_kz="Витаминдер", slug="vitamins", icon="vitamin", sort_order=3),
        Category(id=4, name="Сердечно-сосудистые", name_kz="Жүрек-қан тамырлары", slug="cardiovascular", icon="heart", sort_order=4),
        Category(id=5, name="Противовирусные", name_kz="Вирусқа қарсы", slug="antiviral", icon="shield", sort_order=5),
        Category(id=6, name="ЖКТ", name_kz="АЖЖ", slug="gastrointestinal", icon="stomach", sort_order=6),
        Category(id=7, name="Детские", name_kz="Балаларға арналған", slug="pediatric", icon="baby", parent_id=1, sort_order=7),
        Category(id=8, name="Для взрослых", name_kz="Ересектерге арналған", slug="adult", icon="person", parent_id=1, sort_order=8),
    ]
    for cat in categories:
        existing = db.query(Category).filter(Category.id == cat.id).first()
        if not existing:
            db.add(cat)
    db.commit()
    print(f"Добавлено {len(categories)} категорий")


def seed_demo_user(db):
    """Создать демо-пользователя с полным профилем."""
    email = "demo@medi.kz"
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        print(f"Демо-пользователь уже существует: {email}")
        return existing

    user = User(
        email=email,
        hashed_password=hash_password("Demo123!"),
        full_name="Алексей Демонов",
        first_name="Алексей",
        last_name="Демонов",
        phone="+7 (777) 123-45-67",
        gender="male",
        age=32,
        weight_kg=78.5,
        height_cm=178.0,
        blood_type="A+",
        birth_date=datetime(1994, 3, 15),
        onboarding_completed=True,
        allergy_types=["Пищевая", "Лекарственная"],
        allergen_substances=["Пенициллин", "Орехи", "Морепродукты"],
        chronic_conditions=["Гипертония", "Аллергия"],
        extra_profile={
            "emergency_contact": "+7 (777) 987-65-43",
            "insurance_number": "MED-2024-001234",
            "preferred_pharmacy": "Europharma",
        },
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    print(f"Создан демо-пользователь: {email} / Demo123!")
    return user


def seed_medicines(db):
    """Заполнить лекарства."""
    medicines = [
        Medicine(
            id="paracetamol-500",
            name="Парацетамол",
            name_kz="Парацетамол",
            indication_label="От боли и жара",
            category="painkillers",
            category_id=1,
            manufacturer="Фармстандарт",
            country="Россия",
            form="Таблетки",
            prescription_required=False,
            active_ingredients=["Парацетамол 500мг"],
            allergen_tags=["lactose"],
            description="Обезболивающее и жаропонижающее средство. Применяется при головной боли, зубной боли, болях в суставах, простудных заболеваниях.",
            dosage="Взрослым по 1-2 таблетки 3-4 раза в день. Максимальная суточная доза - 8 таблеток.",
            instructions="Принимать после еды, запивая водой.",
            restrictions="Не применять при заболеваниях печени и почек.",
            side_effects="Возможны аллергические реакции, тошнота.",
            contraindications="Повышенная чувствительность к парацетамолу.",
            image_url="https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400",
            price=450.0,
            stock_quantity=150,
            rating=4.7,
            review_count=128,
        ),
        Medicine(
            id="ibuprofen-400",
            name="Ибупрофен",
            name_kz="Ибупрофен",
            indication_label="Противовоспалительное",
            category="painkillers",
            category_id=1,
            manufacturer="Синтез",
            country="Россия",
            form="Таблетки",
            prescription_required=False,
            active_ingredients=["Ибупрофен 400мг"],
            allergen_tags=[],
            description="Нестероидное противовоспалительное средство. Обладает обезболивающим, противовоспалительным и жаропонижающим действием.",
            dosage="По 1 таблетке 3 раза в день после еды.",
            instructions="Принимать после еды для снижения раздражения ЖКТ.",
            restrictions="Не применять при язвенной болезни желудка.",
            side_effects="Диспепсия, головная боль.",
            contraindications="Язвенная болезнь, астма, беременность III триместр.",
            image_url="https://images.unsplash.com/photo-1550572017-4fcdbb59cc32?w=400",
            price=380.0,
            stock_quantity=200,
            rating=4.5,
            review_count=95,
        ),
        Medicine(
            id="amoxicillin-500",
            name="Амоксициллин",
            name_kz="Амоксициллин",
            indication_label="Антибиотик",
            category="antibiotics",
            category_id=2,
            manufacturer="КРКА",
            country="Словения",
            form="Капсулы",
            prescription_required=True,
            active_ingredients=["Амоксициллин 500мг"],
            allergen_tags=["penicillin"],
            description="Антибиотик широкого спектра действия из группы пенициллинов.",
            dosage="По 500мг 3 раза в день в течение 7-10 дней.",
            instructions="Принимать независимо от приёма пищи.",
            restrictions="Строго по назначению врача.",
            side_effects="Диарея, тошнота, аллергические реакции.",
            contraindications="Аллергия на пенициллины, инфекционный мононуклеоз.",
            image_url="https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400",
            price=1250.0,
            stock_quantity=80,
            rating=4.8,
            review_count=67,
        ),
        Medicine(
            id="vitamin-d3",
            name="Витамин D3",
            name_kz="D3 витамині",
            indication_label="Для костей и иммунитета",
            category="vitamins",
            category_id=3,
            manufacturer="Солгар",
            country="США",
            form="Капсулы",
            prescription_required=False,
            active_ingredients=["Холекальциферол 2000 МЕ"],
            allergen_tags=[],
            description="Витамин D3 для поддержания здоровья костей, зубов и иммунной системы.",
            dosage="По 1 капсуле в день во время еды.",
            instructions="Принимать с жирной пищей для лучшего усвоения.",
            restrictions="Не превышать рекомендованную дозу.",
            side_effects="При передозировке возможна гиперкальциемия.",
            contraindications="Гиперкальциемия, гипервитаминоз D.",
            image_url="https://images.unsplash.com/photo-1577401239170-897942555fb3?w=400",
            price=3200.0,
            stock_quantity=120,
            rating=4.9,
            review_count=234,
        ),
        Medicine(
            id="omeprazole-20",
            name="Омепразол",
            name_kz="Омепразол",
            indication_label="От изжоги",
            category="gastrointestinal",
            category_id=6,
            manufacturer="Тева",
            country="Израиль",
            form="Капсулы",
            prescription_required=False,
            active_ingredients=["Омепразол 20мг"],
            allergen_tags=[],
            description="Ингибитор протонной помпы. Снижает кислотность желудочного сока.",
            dosage="По 1 капсуле утром натощак.",
            instructions="Принимать за 30 минут до еды, не разжёвывая.",
            restrictions="Курс лечения не более 14 дней без консультации врача.",
            side_effects="Головная боль, диарея, запор.",
            contraindications="Беременность, лактация.",
            image_url="https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400",
            price=890.0,
            stock_quantity=90,
            rating=4.6,
            review_count=156,
        ),
        Medicine(
            id="loratadine-10",
            name="Лоратадин",
            name_kz="Лоратадин",
            indication_label="От аллергии",
            category="antiviral",
            category_id=5,
            manufacturer="Вертекс",
            country="Россия",
            form="Таблетки",
            prescription_required=False,
            active_ingredients=["Лоратадин 10мг"],
            allergen_tags=[],
            description="Антигистаминный препарат. Устраняет симптомы аллергии: зуд, насморк, слезотечение.",
            dosage="По 1 таблетке 1 раз в день.",
            instructions="Можно принимать независимо от приёма пищи.",
            restrictions="С осторожностью при заболеваниях печени.",
            side_effects="Сонливость, сухость во рту.",
            contraindications="Детский возраст до 2 лет, лактация.",
            image_url="https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=400",
            price=320.0,
            stock_quantity=180,
            rating=4.4,
            review_count=89,
        ),
    ]
    for med in medicines:
        existing = db.query(Medicine).filter(Medicine.id == med.id).first()
        if not existing:
            db.add(med)
    db.commit()
    print(f"Добавлено {len(medicines)} лекарств")


def seed_pharmacies(db):
    """Заполнить аптеки."""
    pharmacies = [
        Pharmacy(
            name="Europharma",
            address="ул. Абая 150, Алматы",
            city="Алматы",
            phone="+7 (727) 250-90-00",
            latitude=43.2380,
            longitude=76.9456,
            working_hours="08:00 - 22:00",
            is_24h=False,
            rating=4.8,
            review_count=342,
            description="Крупнейшая сеть аптек Казахстана",
        ),
        Pharmacy(
            name="Аптека Садыхан",
            address="пр. Достык 89, Алматы",
            city="Алматы",
            phone="+7 (727) 264-55-55",
            latitude=43.2351,
            longitude=76.9572,
            working_hours="Круглосуточно",
            is_24h=True,
            rating=4.6,
            review_count=218,
            description="Сеть аптек с доставкой",
        ),
        Pharmacy(
            name="PharmMir",
            address="ул. Толе би 59, Алматы",
            city="Алматы",
            phone="+7 (727) 233-44-55",
            latitude=43.2567,
            longitude=76.9234,
            working_hours="09:00 - 21:00",
            is_24h=False,
            rating=4.5,
            review_count=156,
            description="Аптека низких цен",
        ),
        Pharmacy(
            name="Биосфера",
            address="ул. Жандосова 98, Алматы",
            city="Алматы",
            phone="+7 (727) 302-10-10",
            latitude=43.2089,
            longitude=76.8934,
            working_hours="08:00 - 23:00",
            is_24h=False,
            rating=4.7,
            review_count=287,
            description="Премиальная аптека",
        ),
    ]
    for pharm in pharmacies:
        existing = db.query(Pharmacy).filter(Pharmacy.name == pharm.name).first()
        if not existing:
            db.add(pharm)
    db.commit()
    print(f"Добавлено {len(pharmacies)} аптек")


def seed_sellers(db):
    """Заполнить продавцов."""
    sellers = [
        Seller(id="europharma", name="Europharma", rating=4.8, review_count=342),
        Seller(id="sadykhan", name="Садыхан", rating=4.6, review_count=218),
        Seller(id="pharmmir", name="PharmMir", rating=4.5, review_count=156),
        Seller(id="biosfera", name="Биосфера", rating=4.7, review_count=287),
    ]
    for seller in sellers:
        existing = db.query(Seller).filter(Seller.id == seller.id).first()
        if not existing:
            db.add(seller)
    db.commit()
    print(f"Добавлено {len(sellers)} продавцов")


def seed_seller_offers(db):
    """Заполнить предложения продавцов."""
    offers = [
        SellerOffer(medicine_id="paracetamol-500", seller_id="europharma", price=450, delivery_text="Доставка 1-2 дня"),
        SellerOffer(medicine_id="paracetamol-500", seller_id="sadykhan", price=420, delivery_text="Самовывоз сегодня"),
        SellerOffer(medicine_id="ibuprofen-400", seller_id="europharma", price=380, delivery_text="Доставка 1-2 дня"),
        SellerOffer(medicine_id="ibuprofen-400", seller_id="pharmmir", price=350, delivery_text="Бесплатная доставка"),
        SellerOffer(medicine_id="amoxicillin-500", seller_id="biosfera", price=1250, delivery_text="По рецепту"),
        SellerOffer(medicine_id="vitamin-d3", seller_id="europharma", price=3200, delivery_text="В наличии"),
        SellerOffer(medicine_id="vitamin-d3", seller_id="biosfera", price=3100, delivery_text="Скидка 5%"),
        SellerOffer(medicine_id="omeprazole-20", seller_id="sadykhan", price=890, delivery_text="Доставка сегодня"),
        SellerOffer(medicine_id="loratadine-10", seller_id="pharmmir", price=320, delivery_text="Самовывоз"),
    ]
    for offer in offers:
        existing = db.query(SellerOffer).filter(
            SellerOffer.medicine_id == offer.medicine_id,
            SellerOffer.seller_id == offer.seller_id
        ).first()
        if not existing:
            db.add(offer)
    db.commit()
    print(f"Добавлено {len(offers)} предложений")


def seed_treatments(db, user_id: int):
    """Заполнить курсы лечения для демо-пользователя."""
    today = date.today()
    treatments = [
        Treatment(
            user_id=user_id,
            medicine_id="paracetamol-500",
            disease_name="Головная боль",
            medicine_name="Парацетамол",
            dosage="500мг",
            frequency="При необходимости",
            start_date=today - timedelta(days=5),
            end_date=today + timedelta(days=2),
            intake_time="08:00,14:00,20:00",
            color_index=0,
            is_active=True,
            notes="Не более 4г в сутки",
        ),
        Treatment(
            user_id=user_id,
            medicine_id="vitamin-d3",
            disease_name="Дефицит витамина D",
            medicine_name="Витамин D3",
            dosage="2000 МЕ",
            frequency="1 раз в день",
            start_date=today - timedelta(days=30),
            end_date=today + timedelta(days=60),
            intake_time="09:00",
            color_index=1,
            is_active=True,
            notes="Принимать с жирной пищей",
        ),
        Treatment(
            user_id=user_id,
            medicine_id="loratadine-10",
            disease_name="Сезонная аллергия",
            medicine_name="Лоратадин",
            dosage="10мг",
            frequency="1 раз в день",
            start_date=today - timedelta(days=10),
            end_date=today + timedelta(days=20),
            intake_time="10:00",
            color_index=2,
            is_active=True,
            notes="При появлении симптомов",
        ),
    ]
    for treat in treatments:
        db.add(treat)
    db.commit()
    print(f"Добавлено {len(treatments)} курсов лечения")


def seed_reminders(db, user_id: int):
    """Заполнить напоминания."""
    reminders = [
        Reminder(
            user_id=user_id,
            medicine_name="Витамин D3",
            dosage="1 капсула",
            reminder_time=time(9, 0),
            days_of_week="1,2,3,4,5,6,7",
            is_active=True,
        ),
        Reminder(
            user_id=user_id,
            medicine_name="Лоратадин",
            dosage="1 таблетка",
            reminder_time=time(10, 0),
            days_of_week="1,2,3,4,5,6,7",
            is_active=True,
        ),
        Reminder(
            user_id=user_id,
            medicine_name="Омепразол",
            dosage="1 капсула",
            reminder_time=time(7, 30),
            days_of_week="1,2,3,4,5",
            is_active=False,
        ),
    ]
    for rem in reminders:
        db.add(rem)
    db.commit()
    print(f"Добавлено {len(reminders)} напоминаний")


def seed_appointments(db, user_id: int):
    """Заполнить записи к врачам."""
    today = date.today()
    appointments = [
        Appointment(
            user_id=user_id,
            doctor_name="Иванов Пётр Сергеевич",
            specialty="Терапевт",
            clinic_name="Медицинский центр Авиценна",
            clinic_address="ул. Абая 52, каб. 305",
            appointment_date=today + timedelta(days=3),
            appointment_time=time(10, 30),
            duration_minutes=30,
            notes="Плановый осмотр",
            status="scheduled",
        ),
        Appointment(
            user_id=user_id,
            doctor_name="Смирнова Анна Владимировна",
            specialty="Аллерголог",
            clinic_name="Клиника АллергоМед",
            clinic_address="пр. Достык 45",
            appointment_date=today + timedelta(days=7),
            appointment_time=time(14, 0),
            duration_minutes=45,
            notes="Консультация по сезонной аллергии",
            status="scheduled",
        ),
        Appointment(
            user_id=user_id,
            doctor_name="Ким Виктор Александрович",
            specialty="Кардиолог",
            clinic_name="Кардиоцентр",
            clinic_address="ул. Жандосова 12",
            appointment_date=today - timedelta(days=14),
            appointment_time=time(11, 0),
            duration_minutes=60,
            notes="Контроль давления",
            status="completed",
        ),
    ]
    for appt in appointments:
        db.add(appt)
    db.commit()
    print(f"Добавлено {len(appointments)} записей к врачам")


def seed_orders(db, user_id: int):
    """Заполнить заказы."""
    today = date.today()

    order1 = Order(
        user_id=user_id,
        pharmacy_id=1,
        status="delivered",
        total_amount=4470.0,
        delivery_address="ул. Назарбаева 25, кв. 15",
        delivery_type="delivery",
        notes="Позвонить перед доставкой",
    )
    db.add(order1)
    db.flush()

    order1_items = [
        OrderItem(order_id=order1.id, medicine_id="paracetamol-500", quantity=2, unit_price=450, total_price=900),
        OrderItem(order_id=order1.id, medicine_id="vitamin-d3", quantity=1, unit_price=3200, total_price=3200),
        OrderItem(order_id=order1.id, medicine_id="loratadine-10", quantity=1, unit_price=320, total_price=320),
    ]
    for item in order1_items:
        db.add(item)

    order2 = Order(
        user_id=user_id,
        pharmacy_id=2,
        status="processing",
        total_amount=1270.0,
        delivery_type="pickup",
    )
    db.add(order2)
    db.flush()

    order2_items = [
        OrderItem(order_id=order2.id, medicine_id="ibuprofen-400", quantity=1, unit_price=380, total_price=380),
        OrderItem(order_id=order2.id, medicine_id="omeprazole-20", quantity=1, unit_price=890, total_price=890),
    ]
    for item in order2_items:
        db.add(item)

    db.commit()
    print("Добавлено 2 заказа с позициями")


def seed_reviews(db, user_id: int):
    """Заполнить отзывы."""
    reviews = [
        Review(
            user_id=user_id,
            medicine_id="vitamin-d3",
            rating=5,
            title="Отличный витамин!",
            text="Принимаю уже месяц, чувствую себя бодрее. Рекомендую всем, особенно зимой.",
            pros="Качественный состав, удобная форма капсул",
            cons="Высокая цена",
            is_verified=True,
            helpful_count=12,
        ),
        Review(
            user_id=user_id,
            medicine_id="paracetamol-500",
            rating=4,
            title="Классика",
            text="Всегда помогает от головной боли. Держу в аптечке постоянно.",
            pros="Эффективный, доступная цена",
            cons="Нельзя принимать долго",
            is_verified=True,
            helpful_count=8,
        ),
    ]
    for rev in reviews:
        db.add(rev)
    db.commit()
    print(f"Добавлено {len(reviews)} отзывов")


def seed_chat_messages(db, user_id: int):
    """Заполнить историю чата."""
    messages = [
        ChatMessage(user_id=user_id, role="user", content="Привет! Что помогает от головной боли?", session_id="demo-session-1"),
        ChatMessage(user_id=user_id, role="assistant", content="Здравствуйте! При головной боли хорошо помогают обезболивающие препараты, такие как Парацетамол или Ибупрофен. Парацетамол 500мг можно принимать по 1-2 таблетки каждые 4-6 часов, но не более 8 таблеток в сутки. Если головная боль сильная или частая, рекомендую обратиться к врачу.", session_id="demo-session-1"),
        ChatMessage(user_id=user_id, role="user", content="А есть ли противопоказания?", session_id="demo-session-1"),
        ChatMessage(user_id=user_id, role="assistant", content="Да, у обезболивающих есть противопоказания. Парацетамол нельзя при заболеваниях печени. Ибупрофен противопоказан при язвенной болезни желудка и астме. Если у вас есть хронические заболевания, обязательно проконсультируйтесь с врачом перед приёмом.", session_id="demo-session-1"),
    ]
    for msg in messages:
        db.add(msg)
    db.commit()
    print(f"Добавлено {len(messages)} сообщений чата")


def seed_faqs(db):
    """Заполнить FAQ."""
    faqs = [
        Faq(question="Как добавить напоминание о приёме лекарства?", answer="Откройте раздел 'Лечение', выберите препарат и нажмите 'Добавить напоминание'. Укажите время и дни приёма.", sort_order=1),
        Faq(question="Как найти аналог лекарства?", answer="На странице препарата нажмите кнопку 'Аналоги'. Система покажет препараты с похожим действующим веществом.", sort_order=2),
        Faq(question="Как связаться с поддержкой?", answer="Напишите в чат с ИИ-помощником или отправьте email на support@medi.kz", sort_order=3),
        Faq(question="Безопасны ли мои данные?", answer="Да, все данные шифруются и хранятся на защищённых серверах. Мы не передаём информацию третьим лицам.", sort_order=4),
        Faq(question="Можно ли заказать лекарства через приложение?", answer="Да, вы можете выбрать лекарство, сравнить цены в разных аптеках и оформить заказ с доставкой или самовывозом.", sort_order=5),
    ]
    for faq in faqs:
        existing = db.query(Faq).filter(Faq.question == faq.question).first()
        if not existing:
            db.add(faq)
    db.commit()
    print(f"Добавлено {len(faqs)} FAQ")


def main():
    print("=" * 50)
    print("MEDI - Заполнение базы данных демо-данными")
    print("=" * 50)

    create_tables()

    db = SessionLocal()
    try:
        seed_categories(db)
        seed_medicines(db)
        seed_pharmacies(db)
        seed_sellers(db)
        seed_seller_offers(db)
        seed_faqs(db)

        user = seed_demo_user(db)
        seed_treatments(db, user.id)
        seed_reminders(db, user.id)
        seed_appointments(db, user.id)
        seed_orders(db, user.id)
        seed_reviews(db, user.id)
        seed_chat_messages(db, user.id)

        print("=" * 50)
        print("Готово! Демо-аккаунт:")
        print("  Email: demo@medi.kz")
        print("  Пароль: Demo123!")
        print("=" * 50)
    finally:
        db.close()


if __name__ == "__main__":
    main()
