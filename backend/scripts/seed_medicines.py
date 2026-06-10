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
from sqlalchemy import text
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
    "citramon": "Бас ауруына арналған",
    "spazmalgon": "Бас ауруына арналған",
    "ibuprofen": "Бас ауруына арналған",
    "ketanov": "Тіс ауруына арналған",
    "nimesil": "Тіс ауруына арналған",
    "paracetamol-500": "Тіс ауруына арналған",
    "cardiomagnyl": "Жүрек-қан тамырына арналған",
    "amoxiclav": "Бактериялық инфекцияларға арналған",
    "bisoprolol": "Жүрек ауруына арналған",
    "vitamin-c": "Иммунитетті нығайтуға арналған",
    "vitamin-d3": "Сүйек пен иммунитетке арналған",
    "magne-b6": "Жүйке жүйесіне арналған",
    "azithromycin": "Бактериялық инфекцияларға арналған",
    "ceftriaxone": "Бактериялық инфекцияларға арналған",
    "omeprazole": "Асқазан қышқылдығына арналған",
    "ketonal": "Ауырсынуды басуға арналған",
    "nurofen": "Бас ауруына арналған",
    "aspirin": "Бас ауруына арналған",
    "pentalgin": "Ауырсынуды басуға арналған",
    "tempalgin": "Бас ауруына арналған",
    "analgin": "Тіс ауруына арналған",
    "naiz": "Тіс ауруына арналған",
    "dolaren": "Тіс ауруына арналған",
    "kalgel": "Тіс ауруына арналған",
    "concor": "Жүрек ауруына арналған",
    "mildronate": "Жүрек ауруына арналған",
    "enalapril": "Жоғары қан қысымына арналған",
    "asparkam": "Жүрек-қан тамырына арналған",
    "multivitamin": "Иммунитетті нығайтуға арналған",
    "omega-3": "Жүрек пен миға арналған",
    "zinc": "Иммунитетті нығайтуға арналған",
    "folic-acid": "Қан түзілуіне арналған",
    "amoxicillin": "Бактериялық инфекцияларға арналған",
    "augmentin": "Бактериялық инфекцияларға арналған",
    "ciprofloxacin": "Бактериялық инфекцияларға арналған",
    "doxycycline": "Бактериялық инфекцияларға арналған",
}

# Категории: head | teeth | heart | vitamins | antibiotics
MEDICINES: list[dict] = [
    # Бас ауруы (head)
    {
        "id": "citramon",
        "name": "Цитрамон",
        "category": "head",
        "subcategory": "painkiller",
        "manufacturer": "Фармстандарт",
        "country": "Қазақстан",
        "form": "таблетка",
        "active_ingredients": ["ацетилсалицил қышқылы (аспирин)", "парацетамол", "кофеин"],
        "allergen_tags": ["nsaid", "salicylate", "analgesic"],
        "analog_ids": ["spazmalgon", "ibuprofen"],
        "description": "Бас ауруын және әлсіз дене ауырсынуын басатын, құрамында кофеин бар біріктірілген препарат.",
        "dosage": "1–2 таблетка",
        "instructions": "Тамақтан кейін, тәулігіне 3 ретке дейін қабылдаңыз.",
        "restrictions": "Асқазан жарасы және жоғары қан қысымы кезінде сақтықпен қолданыңыз.",
        "side_effects": "Жүрек айну, ұйқының бұзылуы, қан қысымының жоғарылауы мүмкін.",
        "contraindications": "12 жасқа дейінгі балаларға және асқазан-ішек қан кетулерінде қарсы көрсетілген.",
        "image_url": "assets/голова/цитрамон.png",
        "price": 450.0,
    },
    {
        "id": "spazmalgon",
        "name": "Спазмалгон",
        "category": "head",
        "subcategory": "painkiller",
        "manufacturer": "Actavis",
        "country": "Болгария",
        "form": "таблетка",
        "active_ingredients": ["метамизол натрий", "питофенон", "фенпиверин бромиді"],
        "allergen_tags": ["pyrazolone", "metamizole"],
        "analog_ids": ["citramon", "ibuprofen"],
        "description": "Спазммен қатар жүретін бас және бұлшықет ауырсынуын басатын спазмолитикалық анальгетик.",
        "dosage": "1–2 таблетка",
        "instructions": "Тамақтан кейін, тәулігіне 3 ретке дейін қабылдаңыз.",
        "restrictions": "Қан түзу жүйесі бұзылған жағдайда дәрігер кеңесімен қолданыңыз.",
        "side_effects": "Аллергиялық реакциялар, қан қысымының төмендеуі мүмкін.",
        "contraindications": "Метамизолға аллергия, бүйрек немесе бауыр функциясының ауыр бұзылуы.",
        "image_url": "assets/голова/спазмалгон.png",
        "price": 980.0,
    },
    {
        "id": "ibuprofen",
        "name": "Ибупрофен",
        "category": "head",
        "subcategory": "painkiller",
        "manufacturer": "Borisov ZMP",
        "country": "Беларусь",
        "form": "таблетка",
        "active_ingredients": ["ибупрофен"],
        "allergen_tags": ["nsaid", "ibuprofen"],
        "analog_ids": ["citramon", "ketonal"],
        "description": "Қабынуға қарсы, жоғары температураны түсіретін және ауырсынуды басатын стероидты емес препарат (ҚҚБЕП).",
        "dosage": "200–400 мг",
        "instructions": "Тамақтан кейін, дозалар арасында кемінде 4–6 сағат аралық сақтаңыз.",
        "restrictions": "Асқазан-ішек жолы ауруларында сақтықпен қолданыңыз.",
        "side_effects": "Асқазанның тітіркенуі, жүрек айну, бас айналу мүмкін.",
        "contraindications": "Асқазан жарасы, ауыр бүйрек жеткіліксіздігі кезінде қарсы көрсетілген.",
        "image_url": "assets/голова/ибупрофен.png",
        "price": 650.0,
    },
    # Тіс ауруы (teeth)
    {
        "id": "ketanov",
        "name": "Кетанов",
        "category": "teeth",
        "subcategory": "painkiller",
        "manufacturer": "Ranbaxy",
        "country": "Үндістан",
        "form": "таблетка",
        "active_ingredients": ["кеторолак"],
        "allergen_tags": ["nsaid", "ketorolac"],
        "analog_ids": ["ketonal", "nimesil"],
        "description": "Тіс ауруы сияқты күшті ауырсынуларды басуға арналған қуатты қабынуға қарсы препарат.",
        "dosage": "10 мг",
        "instructions": "Тамақтан кейін, үздіксіз 5 күннен аспайтын қысқа курс ретінде қабылдаңыз.",
        "restrictions": "Ұзақ уақыт қолдануға болмайды.",
        "side_effects": "Асқазан-ішек жолының тітіркенуі, бас ауруы мүмкін.",
        "contraindications": "Асқазан жарасы, қан кетулер, жүктілік кезінде қарсы көрсетілген.",
        "image_url": "assets/зубы/кетонав.png",
        "price": 1450.0,
    },
    {
        "id": "nimesil",
        "name": "Нимесил",
        "category": "teeth",
        "subcategory": "painkiller",
        "manufacturer": "Berlin-Chemie",
        "country": "Германия",
        "form": "ұнтақ",
        "active_ingredients": ["нимесулид"],
        "allergen_tags": ["nsaid", "nimesulide"],
        "analog_ids": ["ketanov", "ketonal"],
        "description": "Тіс ауруы мен қабынуды басуға арналған, суда ерітілетін ұнтақ түріндегі ҚҚБЕП.",
        "dosage": "100 мг (1 пакетик)",
        "instructions": "Пакетті жарты стақан суда ерітіп, тамақтан кейін ішіңіз. Тәулігіне 2 реттен аспайды.",
        "restrictions": "Ұзақ курспен қолдануға болмайды.",
        "side_effects": "Жүрек айну, ас қорыту бұзылыстары мүмкін.",
        "contraindications": "Бауыр ауруы, 12 жасқа дейінгі балаларға қарсы көрсетілген.",
        "image_url": "assets/зубы/нимесил.png",
        "price": 1290.0,
    },
    {
        "id": "paracetamol-500",
        "name": "Парацетамол",
        "category": "teeth",
        "subcategory": "painkiller",
        "manufacturer": "Фармстандарт",
        "country": "Қазақстан",
        "form": "таблетка",
        "active_ingredients": ["парацетамол"],
        "allergen_tags": ["analgesic"],
        "analog_ids": ["ibuprofen", "nimesil"],
        "description": "Қызбаны түсіретін және тіс пен бас ауруын басатын кеңінен қолданылатын дәрі.",
        "dosage": "500–1000 мг",
        "instructions": "Тамақтан кейін, тәулігіне 4 ретке дейін, аралықтары кемінде 4 сағат.",
        "restrictions": "Бауыр ауруларында сақтықпен қолданыңыз.",
        "side_effects": "Сирек жағдайда аллергиялық бөртпе мүмкін.",
        "contraindications": "Бауыр функциясының ауыр бұзылуы кезінде қарсы көрсетілген.",
        "image_url": "assets/зубы/парацетамол.png",
        "price": 380.0,
    },
    # Жүрек (heart)
    {
        "id": "cardiomagnyl",
        "name": "Кардиомагнил",
        "category": "heart",
        "subcategory": "cardio",
        "manufacturer": "Takeda",
        "country": "Норвегия",
        "form": "таблетка",
        "active_ingredients": ["ацетилсалицил қышқылы (аспирин)", "магний гидроксиді"],
        "allergen_tags": ["nsaid", "salicylate"],
        "analog_ids": ["bisoprolol"],
        "description": "Тромб түзілуінің алдын алу және жүрек-қан тамыр асқынуларының қаупін азайту үшін қолданылатын препарат.",
        "dosage": "75–150 мг",
        "instructions": "Тәулігіне 1 рет, тамақтан кейін, дәрігер белгілеген уақытта қабылдаңыз.",
        "restrictions": "Қан кетуге бейім адамдарға сақтықпен тағайындалады.",
        "side_effects": "Асқазанның тітіркенуі, қан кетудің жоғарылауы мүмкін.",
        "contraindications": "Асқазан жарасы, қан ұю бұзылыстары кезінде қарсы көрсетілген.",
        "image_url": "assets/сердце/кардиомагнил.png",
        "price": 1350.0,
    },
    {
        "id": "amoxiclav",
        "name": "Амоксиклав",
        "category": "heart",
        "subcategory": "antibiotic",
        "manufacturer": "Sandoz",
        "country": "Словения",
        "form": "таблетка",
        "prescription_required": True,
        "active_ingredients": ["амоксициллин (пенициллин тобы)", "клавулан қышқылы"],
        "allergen_tags": ["penicillin", "antibiotic"],
        "analog_ids": ["azithromycin", "ceftriaxone"],
        "description": "Тыныс жолдары мен басқа да бактериялық инфекцияларды емдеуге арналған кең спектрлі пенициллин тобындағы антибиотик.",
        "dosage": "500/125 мг",
        "instructions": "Тамақ алдында, күніне 2–3 рет, дәрігер белгілеген курс бойынша қабылдаңыз.",
        "restrictions": "Курсты толық аяқтау қажет, өздігінен тоқтатпаңыз.",
        "side_effects": "Ас қорыту бұзылыстары, аллергиялық бөртпе мүмкін.",
        "contraindications": "Пенициллинге аллергиясы барларға қарсы көрсетілген.",
        "image_url": "assets/сердце/амоксиклав.png",
        "price": 2200.0,
    },
    {
        "id": "bisoprolol",
        "name": "Бисопролол",
        "category": "heart",
        "subcategory": "beta_blocker",
        "manufacturer": "KRKA",
        "country": "Словения",
        "form": "таблетка",
        "prescription_required": True,
        "active_ingredients": ["бисопролол"],
        "allergen_tags": ["beta_blocker"],
        "analog_ids": ["cardiomagnyl"],
        "description": "Артериялық қысымды және жүрек соғу жиілігін реттейтін селективті бета-адреноблокатор.",
        "dosage": "2.5–10 мг",
        "instructions": "Тәулігіне 1 рет, таңертең, тамаққа қарамастан, дәрігер тағайындауы бойынша қабылдаңыз.",
        "restrictions": "Қабылдауды кенеттен тоқтатпаңыз — дәрігермен бірге дозаны біртіндеп азайтыңыз.",
        "side_effects": "Бас айналу, шаршағыштық, жүрек соғысының баяулауы мүмкін.",
        "contraindications": "Брадикардия, төмен қан қысымы, бронх демікпесі кезінде қарсы көрсетілген.",
        "image_url": "assets/сердце/бисопролол.png",
        "price": 850.0,
    },
    # Витаминдер (vitamins)
    {
        "id": "vitamin-c",
        "name": "Витамин C",
        "category": "vitamins",
        "subcategory": "vitamin",
        "manufacturer": "Solgar",
        "country": "АҚШ",
        "form": "таблетка",
        "active_ingredients": ["аскорбин қышқылы"],
        "allergen_tags": [],
        "analog_ids": ["vitamin-d3", "magne-b6"],
        "description": "Иммунитетті нығайтатын және антиоксидантты қорғанысты қамтамасыз ететін дәрумен.",
        "dosage": "500–1000 мг",
        "instructions": "Тамақтан кейін, күніне 1 рет қабылдаңыз.",
        "restrictions": "Гастрит кезінде сақтықпен қолданыңыз.",
        "side_effects": "Жоғары дозада асқазанның тітіркенуі мүмкін.",
        "contraindications": "Аскорбин қышқылына жеке төзбеушілік.",
        "image_url": "assets/витамины/витамин_c.png",
        "price": 320.0,
    },
    {
        "id": "vitamin-d3",
        "name": "Витамин D3",
        "category": "vitamins",
        "subcategory": "vitamin",
        "manufacturer": "Aquion",
        "country": "Ресей",
        "form": "тамшы",
        "active_ingredients": ["холекальциферол"],
        "allergen_tags": [],
        "analog_ids": ["vitamin-c", "magne-b6"],
        "description": "Сүйек тінін нығайтуға және иммундық жүйенің дұрыс жұмысына қолдау көрсетуге арналған дәрумен.",
        "dosage": "1000–2000 ХБ",
        "instructions": "Тамақ кезінде, майлы тағаммен бірге қабылдаңыз.",
        "restrictions": "Дозаны қанда кальций деңгейін бақыламай арттырмаңыз.",
        "side_effects": "Артық дозада жүрек айну, әлсіздік мүмкін.",
        "contraindications": "Гиперкальциемия кезінде қарсы көрсетілген.",
        "image_url": "assets/витамины/д3.jpg",
        "price": 1100.0,
    },
    {
        "id": "magne-b6",
        "name": "Магне B6",
        "category": "vitamins",
        "subcategory": "supplement",
        "manufacturer": "Sanofi",
        "country": "Франция",
        "form": "таблетка",
        "active_ingredients": ["магний лактаты", "пиридоксин (В6 дәрумені)"],
        "allergen_tags": [],
        "analog_ids": ["vitamin-c", "vitamin-d3"],
        "description": "Магний тапшылығын толтыруға және жүйке жүйесінің қалыпты жұмысын қолдауға арналған дәрумендік кешен.",
        "dosage": "1–2 таблетка",
        "instructions": "Тамақ кезінде, көп сумен ішіңіз, тәулігіне 2–3 рет.",
        "restrictions": "Бүйрек жеткіліксіздігінде сақтықпен қолданыңыз.",
        "side_effects": "Сирек жағдайда асқазан ауыруы, диарея мүмкін.",
        "contraindications": "Ауыр бүйрек жеткіліксіздігінде қарсы көрсетілген.",
        "image_url": "assets/витамины/магни6.png",
        "price": 2450.0,
    },
    # Антибиотиктер (antibiotics)
    {
        "id": "azithromycin",
        "name": "Азитромицин",
        "category": "antibiotics",
        "subcategory": "macrolide",
        "manufacturer": "Teva",
        "country": "Израиль",
        "form": "капсула",
        "prescription_required": True,
        "active_ingredients": ["азитромицин"],
        "allergen_tags": ["macrolide", "antibiotic"],
        "analog_ids": ["amoxiclav", "ceftriaxone"],
        "description": "Тыныс жолдары мен ЛОР ауруларын емдеуге арналған, ұзақ әсер ететін макролид тобындағы антибиотик.",
        "dosage": "500 мг",
        "instructions": "Тәулігіне 1 рет, тамақтан 1 сағат бұрын немесе 2 сағаттан кейін, 3 күн бойы қабылдаңыз.",
        "restrictions": "Курсты дәрігердің рұқсатынсыз тоқтатпаңыз.",
        "side_effects": "Іш өту, жүрек айну мүмкін.",
        "contraindications": "Бауыр функциясының ауыр бұзылуы кезінде қарсы көрсетілген.",
        "image_url": "assets/антибиотики/азитромицин.png",
        "price": 1850.0,
    },
    {
        "id": "ceftriaxone",
        "name": "Цефтриаксон",
        "category": "antibiotics",
        "subcategory": "cephalosporin",
        "manufacturer": "Sandoz",
        "country": "Австрия",
        "form": "инъекция үшін ұнтақ",
        "prescription_required": True,
        "active_ingredients": ["цефтриаксон"],
        "allergen_tags": ["cephalosporin", "antibiotic"],
        "analog_ids": ["azithromycin", "amoxiclav"],
        "description": "Ауыр бактериялық инфекцияларды емдеуге арналған кең спектрлі цефалоспорин антибиотигі, инъекция түрінде енгізіледі.",
        "dosage": "1 г",
        "instructions": "Бұлшықетке немесе венаға, тек дәрігердің тағайындауы бойынша енгізіледі.",
        "restrictions": "Тек медициналық мекемеде немесе дәрігер бақылауымен қолданылады.",
        "side_effects": "Енгізу орнындағы ауырсыну, аллергиялық реакциялар мүмкін.",
        "contraindications": "Цефалоспориндер мен пенициллинге аллергиясы барларға қарсы көрсетілген.",
        "image_url": "assets/антибиотики/цефтриаксон.png",
        "price": 1650.0,
    },
    {
        "id": "omeprazole",
        "name": "Омепразол",
        "category": "antibiotics",
        "subcategory": "ppi",
        "manufacturer": "KRKA",
        "country": "Словения",
        "form": "капсула",
        "active_ingredients": ["омепразол"],
        "allergen_tags": [],
        "analog_ids": [],
        "description": "Асқазан сөлінің қышқылдығын азайтатын, ойық жара мен рефлюкс ауруын емдеуге арналған препарат.",
        "dosage": "20 мг",
        "instructions": "Таңертең, тамақтан 30 минут бұрын, бір реттік дозамен қабылдаңыз.",
        "restrictions": "Ұзақ мерзімді қолдану дәрігер бақылауымен жүргізіледі.",
        "side_effects": "Бас ауруы, ішек жұмысының бұзылуы мүмкін.",
        "contraindications": "Препарат құрамына жеке төзбеушілік кезінде қарсы көрсетілген.",
        "image_url": "assets/антибиотики/омепразол.png",
        "price": 990.0,
    },
    {
        "id": "ketonal",
        "name": "Кетонал",
        "category": "antibiotics",
        "subcategory": "painkiller",
        "manufacturer": "Sandoz",
        "country": "Словения",
        "form": "капсула",
        "active_ingredients": ["кетопрофен"],
        "allergen_tags": ["nsaid", "ketoprofen"],
        "analog_ids": ["ibuprofen", "ketanov"],
        "description": "Қабынуға қарсы әсері бар, бұлшықет пен буын ауырсынуын, сондай-ақ тіс ауруын басатын ҚҚБЕП.",
        "dosage": "100 мг",
        "instructions": "Тамақтан кейін, тәулігіне 2 ретке дейін қабылдаңыз.",
        "restrictions": "Ұзақ уақыт қолдануға болмайды.",
        "side_effects": "Асқазанның тітіркенуі, бас айналу мүмкін.",
        "contraindications": "Асқазан жарасы, жүктіліктің соңғы триместрінде қарсы көрсетілген.",
        "image_url": "assets/антибиотики/кетонал.png",
        "price": 1750.0,
    },
    # ---- Қосымша дәрілер (каталогты толтыру үшін) ----
    # Бас ауруы (head)
    {
        "id": "nurofen",
        "name": "Нурофен",
        "category": "head",
        "subcategory": "painkiller",
        "manufacturer": "Reckitt Benckiser",
        "country": "Ұлыбритания",
        "form": "таблетка",
        "active_ingredients": ["ибупрофен"],
        "allergen_tags": ["nsaid", "ibuprofen"],
        "analog_ids": ["ibuprofen", "citramon"],
        "description": "Бас ауруын, қызбаны және қабынуды басатын ибупрофен негізіндегі белгілі препарат.",
        "dosage": "200–400 мг",
        "instructions": "Тамақтан кейін, дозалар арасында кемінде 4–6 сағат аралықпен қабылдаңыз.",
        "restrictions": "Асқазан-ішек ауруларында сақтықпен қолданыңыз.",
        "side_effects": "Жүрек айну, асқазанның тітіркенуі мүмкін.",
        "contraindications": "Ибупрофенге аллергия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 1450.0,
    },
    {
        "id": "aspirin",
        "name": "Аспирин",
        "category": "head",
        "subcategory": "painkiller",
        "manufacturer": "Bayer",
        "country": "Германия",
        "form": "таблетка",
        "active_ingredients": ["ацетилсалицил қышқылы (аспирин)"],
        "allergen_tags": ["nsaid", "salicylate"],
        "analog_ids": ["citramon", "cardiomagnyl"],
        "description": "Бас ауруы мен қызбаны басатын, төмен дозада қан сұйылтқыш ретінде де қолданылатын классикалық ҚҚБЕП.",
        "dosage": "500 мг",
        "instructions": "Тамақтан кейін, көп сумен ішіңіз.",
        "restrictions": "Балаларға дәрігерсіз қолдануға болмайды.",
        "side_effects": "Асқазанның тітіркенуі, қан кетудің жоғарылауы мүмкін.",
        "contraindications": "Асқазан жарасы, аспиринге аллергия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 520.0,
    },
    {
        "id": "pentalgin",
        "name": "Пенталгин",
        "category": "head",
        "subcategory": "painkiller",
        "manufacturer": "Фармстандарт",
        "country": "Ресей",
        "form": "таблетка",
        "active_ingredients": ["парацетамол", "напроксен", "кофеин", "дротаверин"],
        "allergen_tags": ["nsaid", "analgesic"],
        "analog_ids": ["citramon", "ibuprofen"],
        "description": "Әртүрлі сипаттағы ауырсынуды басатын біріктірілген анальгетик.",
        "dosage": "1 таблетка",
        "instructions": "Тамақтан кейін, тәулігіне 3 таблеткадан аспайды.",
        "restrictions": "Асқазан-ішек проблемалары кезінде қолданбаңыз.",
        "side_effects": "Ұйқышылдық, аузының құрғауы мүмкін.",
        "contraindications": "Бүйрек және бауыр функциясының ауыр бұзылуында қарсы көрсетілген.",
        "image_url": None,
        "price": 1180.0,
    },
    {
        "id": "tempalgin",
        "name": "Темпалгин",
        "category": "head",
        "subcategory": "painkiller",
        "manufacturer": "Sopharma",
        "country": "Болгария",
        "form": "таблетка",
        "active_ingredients": ["метамизол натрий", "темпидон"],
        "allergen_tags": ["pyrazolone", "metamizole"],
        "analog_ids": ["spazmalgon", "citramon"],
        "description": "Бас және тіс ауруын, бұлшықет ауырсынуын басатын анальгетик.",
        "dosage": "1 таблетка",
        "instructions": "Тамақтан кейін, тәулігіне 3 ретке дейін.",
        "restrictions": "Қан түзу жүйесі бұзылғанда сақтықпен қолданыңыз.",
        "side_effects": "Аллергиялық реакциялар мүмкін.",
        "contraindications": "Метамизолға аллергия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 890.0,
    },
    # Тіс ауруы (teeth)
    {
        "id": "analgin",
        "name": "Анальгин",
        "category": "teeth",
        "subcategory": "painkiller",
        "manufacturer": "Дарница",
        "country": "Украина",
        "form": "таблетка",
        "active_ingredients": ["метамизол натрий"],
        "allergen_tags": ["pyrazolone", "metamizole"],
        "analog_ids": ["tempalgin", "naiz"],
        "description": "Тіс ауруы мен жоғары температураны басатын кең таралған анальгетик.",
        "dosage": "500 мг",
        "instructions": "Тамақтан кейін, тәулігіне 3 ретке дейін.",
        "restrictions": "Ұзақ уақыт қолдануға болмайды.",
        "side_effects": "Қан түзу жүйесінің бұзылуы сирек жағдайда мүмкін.",
        "contraindications": "Метамизолға аллергия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 410.0,
    },
    {
        "id": "naiz",
        "name": "Найз",
        "category": "teeth",
        "subcategory": "painkiller",
        "manufacturer": "Dr. Reddy's",
        "country": "Үндістан",
        "form": "таблетка",
        "active_ingredients": ["нимесулид"],
        "allergen_tags": ["nsaid", "nimesulide"],
        "analog_ids": ["nimesil", "ketanov"],
        "description": "Тіс ауруы мен қабынуды басатын ҚҚБЕП тобындағы препарат.",
        "dosage": "100 мг",
        "instructions": "Тамақтан кейін, тәулігіне 2 рет.",
        "restrictions": "Бауыр ауруларында қолдануға болмайды.",
        "side_effects": "Жүрек айну, бас ауруы мүмкін.",
        "contraindications": "12 жасқа дейінгі балаларға қарсы көрсетілген.",
        "image_url": None,
        "price": 1050.0,
    },
    {
        "id": "dolaren",
        "name": "Доларен",
        "category": "teeth",
        "subcategory": "painkiller",
        "manufacturer": "Sandoz",
        "country": "Швейцария",
        "form": "таблетка",
        "active_ingredients": ["диклофенак натрий", "парацетамол"],
        "allergen_tags": ["nsaid", "diclofenac"],
        "analog_ids": ["ketanov", "nimesil"],
        "description": "Тіс және буын ауырсынуын басатын біріктірілген қабынуға қарсы препарат.",
        "dosage": "1 таблетка",
        "instructions": "Тамақтан кейін, тәулігіне 2 ретке дейін.",
        "restrictions": "Жүрек-қан тамыр аурулары кезінде сақтықпен қолданыңыз.",
        "side_effects": "Асқазанның тітіркенуі мүмкін.",
        "contraindications": "Асқазан жарасы кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 1320.0,
    },
    {
        "id": "kalgel",
        "name": "Калгель",
        "category": "teeth",
        "subcategory": "topical",
        "manufacturer": "GSK",
        "country": "Ұлыбритания",
        "form": "гель",
        "active_ingredients": ["лидокаин", "цетилпиридиний хлориді"],
        "allergen_tags": ["lidocaine"],
        "analog_ids": [],
        "description": "Тіс шығу кезіндегі ауырсыну мен қызаруды басатын жергілікті гель.",
        "dosage": "аздаған мөлшер",
        "instructions": "Қажет болған жерге жұқа қабатпен жағыңыз, тәулігіне 6 реттен аспайды.",
        "restrictions": "Тек сыртқа қолданылады.",
        "side_effects": "Жағылған жерде жеңіл ұю сезімі мүмкін.",
        "contraindications": "Лидокаинге аллергия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 2350.0,
    },
    # Жүрек (heart)
    {
        "id": "concor",
        "name": "Конкор",
        "category": "heart",
        "subcategory": "beta_blocker",
        "manufacturer": "Merck",
        "country": "Германия",
        "form": "таблетка",
        "prescription_required": True,
        "active_ingredients": ["бисопролол"],
        "allergen_tags": ["beta_blocker"],
        "analog_ids": ["bisoprolol"],
        "description": "Артериялық гипертония мен жүрек ишемиясын емдеуге арналған бета-адреноблокатор.",
        "dosage": "2.5–10 мг",
        "instructions": "Тәулігіне 1 рет, таңертең, дәрігер тағайындауы бойынша.",
        "restrictions": "Қабылдауды кенеттен тоқтатпаңыз.",
        "side_effects": "Бас айналу, шаршағыштық мүмкін.",
        "contraindications": "Брадикардия, бронх демікпесі кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 2350.0,
    },
    {
        "id": "mildronate",
        "name": "Милдронат",
        "category": "heart",
        "subcategory": "cardio_metabolic",
        "manufacturer": "Grindeks",
        "country": "Латвия",
        "form": "капсула",
        "prescription_required": True,
        "active_ingredients": ["мельдоний"],
        "allergen_tags": [],
        "analog_ids": ["cardiomagnyl"],
        "description": "Жүрек пен миының оттегі тапшылығына төзімділігін арттыратын кардиометаболиялық препарат.",
        "dosage": "250–500 мг",
        "instructions": "Күннің бірінші жартысында, дәрігер белгілеген курс бойынша.",
        "restrictions": "Тек дәрігердің тағайындауы бойынша.",
        "side_effects": "Қозу, қан қысымының өзгеруі мүмкін.",
        "contraindications": "Бас сүйек ішілік қысымның жоғарылауы кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 4200.0,
    },
    {
        "id": "enalapril",
        "name": "Эналаприл",
        "category": "heart",
        "subcategory": "ace_inhibitor",
        "manufacturer": "KRKA",
        "country": "Словения",
        "form": "таблетка",
        "prescription_required": True,
        "active_ingredients": ["эналаприл"],
        "allergen_tags": ["ace_inhibitor"],
        "analog_ids": ["bisoprolol"],
        "description": "Жоғары қан қысымын төмендетуге арналған АӨФ ингибиторлар тобындағы препарат.",
        "dosage": "5–20 мг",
        "instructions": "Тәулігіне 1–2 рет, дәрігер тағайындауы бойынша.",
        "restrictions": "Жүктілік кезінде қарсы көрсетілген.",
        "side_effects": "Құрғақ жөтел, бас айналу мүмкін.",
        "contraindications": "Ангионевроздық ісінудің анамнезінде болуы кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 980.0,
    },
    {
        "id": "asparkam",
        "name": "Аспаркам",
        "category": "heart",
        "subcategory": "cardio_metabolic",
        "manufacturer": "Фармак",
        "country": "Украина",
        "form": "таблетка",
        "active_ingredients": ["калий аспартаты", "магний аспартаты"],
        "allergen_tags": [],
        "analog_ids": ["magne-b6"],
        "description": "Калий мен магний тапшылығын толтыруға, жүрек ырғағын қалыпқа келтіруге көмектеседі.",
        "dosage": "1–2 таблетка",
        "instructions": "Тамақтан кейін, тәулігіне 3 рет.",
        "restrictions": "Бүйрек жеткіліксіздігінде сақтықпен қолданыңыз.",
        "side_effects": "Жүрек айну, іш өту мүмкін.",
        "contraindications": "Гиперкалиемия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 760.0,
    },
    # Витаминдер (vitamins)
    {
        "id": "multivitamin",
        "name": "Мультивитамин",
        "category": "vitamins",
        "subcategory": "vitamin",
        "manufacturer": "Centrum",
        "country": "АҚШ",
        "form": "таблетка",
        "active_ingredients": ["дәрумендер мен минералдар кешені"],
        "allergen_tags": [],
        "analog_ids": ["vitamin-c", "vitamin-d3"],
        "description": "Тәуліктік дәрумен мен минерал қажеттілігін толтыруға арналған кешен.",
        "dosage": "1 таблетка",
        "instructions": "Тамақтан кейін, күніне 1 рет.",
        "restrictions": "Басқа дәрумен кешендерімен бірге қолданбаңыз.",
        "side_effects": "Сирек жағдайда аллергиялық реакция мүмкін.",
        "contraindications": "Құрамына жеке төзбеушілік кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 3200.0,
    },
    {
        "id": "omega-3",
        "name": "Омега-3",
        "category": "vitamins",
        "subcategory": "supplement",
        "manufacturer": "Solgar",
        "country": "АҚШ",
        "form": "капсула",
        "active_ingredients": ["балық майы (ЭПҚ, ДГҚ)"],
        "allergen_tags": ["fish"],
        "analog_ids": ["multivitamin"],
        "description": "Жүрек пен ми қызметін қолдайтын пайдалы май қышқылдары.",
        "dosage": "1–2 капсула",
        "instructions": "Тамақтан кейін, күніне 1 рет.",
        "restrictions": "Балыққа аллергиясы барларда сақтықпен қолданыңыз.",
        "side_effects": "Ауыздың балық дәмі болуы мүмкін.",
        "contraindications": "Балық өнімдеріне аллергия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 4800.0,
    },
    {
        "id": "zinc",
        "name": "Мырыш (Цинк)",
        "category": "vitamins",
        "subcategory": "supplement",
        "manufacturer": "Solgar",
        "country": "АҚШ",
        "form": "таблетка",
        "active_ingredients": ["мырыш цитраты"],
        "allergen_tags": [],
        "analog_ids": ["vitamin-c"],
        "description": "Иммунитетті нығайтуға және жараның жазылуын жылдамдатуға көмектесетін микроэлемент.",
        "dosage": "15–25 мг",
        "instructions": "Тамақ кезінде, күніне 1 рет.",
        "restrictions": "Ұзақ мерзімде жоғары дозада қолданбаңыз.",
        "side_effects": "Жүрек айну мүмкін.",
        "contraindications": "Құрамына жеке төзбеушілік кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 2900.0,
    },
    {
        "id": "folic-acid",
        "name": "Фол қышқылы",
        "category": "vitamins",
        "subcategory": "vitamin",
        "manufacturer": "Озон",
        "country": "Ресей",
        "form": "таблетка",
        "active_ingredients": ["фол қышқылы (В9 дәрумені)"],
        "allergen_tags": [],
        "analog_ids": ["multivitamin"],
        "description": "Жасуша бөлінуі мен қан түзілуіне қажетті В тобындағы дәрумен.",
        "dosage": "400–800 мкг",
        "instructions": "Тамақтан кейін, күніне 1 рет.",
        "restrictions": "Дозаны дәрігермен келісіңіз.",
        "side_effects": "Сирек жағдайда аллергиялық реакция мүмкін.",
        "contraindications": "В12 тапшылығы анемиясында сақтықпен қолданыңыз.",
        "image_url": None,
        "price": 650.0,
    },
    # Антибиотиктер (antibiotics)
    {
        "id": "amoxicillin",
        "name": "Амоксициллин",
        "category": "antibiotics",
        "subcategory": "penicillin",
        "manufacturer": "Дарница",
        "country": "Украина",
        "form": "капсула",
        "prescription_required": True,
        "active_ingredients": ["амоксициллин (пенициллин тобы)"],
        "allergen_tags": ["penicillin", "antibiotic"],
        "analog_ids": ["amoxiclav", "azithromycin"],
        "description": "Тыныс жолдары, ЛОР және несеп жолдары инфекцияларын емдеуге арналған пенициллин тобындағы кең спектрлі антибиотик.",
        "dosage": "500 мг",
        "instructions": "Тамаққа қарамастан, тәулігіне 3 рет, курс 5–7 күн.",
        "restrictions": "Курсты толық аяқтаңыз.",
        "side_effects": "Аллергиялық бөртпе, диарея мүмкін.",
        "contraindications": "Пенициллинге аллергия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 980.0,
    },
    {
        "id": "augmentin",
        "name": "Аугментин",
        "category": "antibiotics",
        "subcategory": "penicillin",
        "manufacturer": "GSK",
        "country": "Ұлыбритания",
        "form": "таблетка",
        "prescription_required": True,
        "active_ingredients": ["амоксициллин (пенициллин тобы)", "клавулан қышқылы"],
        "allergen_tags": ["penicillin", "antibiotic"],
        "analog_ids": ["amoxiclav", "amoxicillin"],
        "description": "Қорғалған пенициллин тобындағы антибиотик, тұрақты бактерияларға да тиімді.",
        "dosage": "625 мг",
        "instructions": "Тамақ алдында, тәулігіне 2–3 рет, курс бойынша.",
        "restrictions": "Курсты толық аяқтаңыз.",
        "side_effects": "Ас қорыту бұзылыстары мүмкін.",
        "contraindications": "Пенициллинге аллергия кезінде қарсы көрсетілген.",
        "image_url": None,
        "price": 3100.0,
    },
    {
        "id": "ciprofloxacin",
        "name": "Ципрофлоксацин",
        "category": "antibiotics",
        "subcategory": "fluoroquinolone",
        "manufacturer": "Bayer",
        "country": "Германия",
        "form": "таблетка",
        "prescription_required": True,
        "active_ingredients": ["ципрофлоксацин"],
        "allergen_tags": ["fluoroquinolone", "antibiotic"],
        "analog_ids": ["azithromycin", "ceftriaxone"],
        "description": "Несеп жолдары мен ішек инфекцияларын емдеуге арналған фторхинолон тобындағы антибиотик.",
        "dosage": "500 мг",
        "instructions": "Тәулігіне 2 рет, көп сумен ішіңіз.",
        "restrictions": "Балалар мен жүкті әйелдерге қарсы көрсетілген.",
        "side_effects": "Сіңір ауруы, жүрек айну мүмкін.",
        "contraindications": "18 жасқа дейінгілерге қарсы көрсетілген.",
        "image_url": None,
        "price": 1420.0,
    },
    {
        "id": "doxycycline",
        "name": "Доксициклин",
        "category": "antibiotics",
        "subcategory": "tetracycline",
        "manufacturer": "Озон",
        "country": "Ресей",
        "form": "капсула",
        "prescription_required": True,
        "active_ingredients": ["доксициклин"],
        "allergen_tags": ["tetracycline", "antibiotic"],
        "analog_ids": ["azithromycin"],
        "description": "Кең спектрлі тетрациклин тобындағы антибиотик, тыныс жолдары мен тері инфекцияларына қолданылады.",
        "dosage": "100 мг",
        "instructions": "Тамақтан кейін, тәулігіне 1–2 рет.",
        "restrictions": "Қабылдау кезінде күн сәулесінен сақтаныңыз.",
        "side_effects": "Фотосезімталдық, жүрек айну мүмкін.",
        "contraindications": "8 жасқа дейінгі балалар мен жүкті әйелдерге қарсы көрсетілген.",
        "image_url": None,
        "price": 1290.0,
    },
]


def reset_catalog(db: Session) -> None:
    """Полностью очищает старый каталог лекарств перед загрузкой нового."""
    db.execute(text("DELETE FROM order_items"))
    db.execute(text("DELETE FROM reviews"))
    db.execute(text("DELETE FROM seller_offers"))
    db.execute(text("UPDATE treatments SET medicine_id = NULL"))
    db.execute(text("DELETE FROM medicines"))


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

    for m in MEDICINES:
        mid = m["id"]
        base = float(m.get("price") or 400)
        upsert_offer(mid, "amir", round(base, 2), "Доставка, ертең, тегін", ["delivery", "today"])
        upsert_offer(
            mid,
            "europharma",
            round(max(base * 0.92, 50), 2),
            "Өзің алып кету, бүгін",
            ["today"],
        )
        upsert_offer(
            mid,
            "sadykhan",
            round(base * 1.05, 2),
            "Жеткізу, 2 күн ішінде",
            ["delivery"],
        )


FAQ_SEED: list[tuple[str, str, int]] = [
    (
        "Алғашқы көмекті қалай көрсетуге болады?",
        "112/103 нөміріне қоңырау шалыңыз, орынды қауіпсіз етіңіз, тыныс алу мен пульсті тексеріңіз, қажет болса алгоритм бойынша жүрек-өкпе реанимациясын бастаңыз.",
        1,
    ),
    (
        "Коронавирус деген не?",
        "SARS-CoV-2 вирусы тудыратын жұқпалы ауру. Көпшілік адамдарда тыныс алу жолдарының жеңіл белгілері байқалады.",
        2,
    ),
    (
        "Қолды қалай таңуға болады?",
        "Стерильді бинт қолданыңыз, аяқ-қолды қыспай таңыңыз; қатты қан кету кезінде — уақытын белгілеп жгут салыңыз.",
        3,
    ),
    (
        "Дәріні қалай дұрыс сақтау керек?",
        "Дәрілерді құрғақ, салқын және күн сәулесі түспейтін жерде, балалардың қолы жетпейтін жерде сақтаңыз. Жарамдылық мерзімін үнемі тексеріп тұрыңыз.",
        4,
    ),
    (
        "Дәрі қабылдаудан кейін аллергия пайда болса не істеу керек?",
        "Дәріні қабылдауды дереу тоқтатыңыз, антигистаминді препарат қабылдаңыз және дәрігерге хабарласыңыз. Тыныс алу қиындаса — жедел жәрдемге қоңырау шалыңыз.",
        5,
    ),
    (
        "Дәрілерді бір-бірімен қалай үйлестіруге болады?",
        "Бірнеше дәріні бір мезгілде қабылдамас бұрын дәрігер немесе дәріханашымен кеңесіңіз — кейбір препараттар бір-бірінің әсерін күшейтуі немесе әлсіретуі мүмкін.",
        6,
    ),
]


def seed_faqs(db: Session) -> None:
    db.query(Faq).delete()
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
    # Белсенді емдеулер (басты бетте көрсетіледі)
    {
        "disease_name": "Тұмау",
        "medicine_id": "paracetamol-500",
        "medicine_name": "Парацетамол",
        "start_date": date(2026, 6, 1),
        "end_date": date(2026, 6, 20),
        "intake_time": "19:00 – 20:00",
        "color_index": 0,
    },
    {
        "disease_name": "Дәрумен курсы",
        "medicine_id": "vitamin-c",
        "medicine_name": "Витамин C",
        "start_date": date(2026, 5, 20),
        "end_date": date(2026, 7, 1),
        "intake_time": "08:00 – 08:30",
        "color_index": 1,
    },
    {
        "disease_name": "Бас ауруы",
        "medicine_id": "citramon",
        "medicine_name": "Цитрамон",
        "start_date": date(2026, 6, 5),
        "end_date": date(2026, 6, 15),
        "intake_time": "13:00 – 13:30",
        "color_index": 2,
    },
    {
        "disease_name": "Жүрек-қан тамырын алдын алу",
        "medicine_id": "cardiomagnyl",
        "medicine_name": "Кардиомагнил",
        "start_date": date(2026, 6, 8),
        "end_date": date(2026, 8, 8),
        "intake_time": "09:00 – 09:30",
        "color_index": 3,
    },
    {
        "disease_name": "Магний тапшылығы",
        "medicine_id": "magne-b6",
        "medicine_name": "Магне B6",
        "start_date": date(2026, 6, 10),
        "end_date": date(2026, 7, 10),
        "intake_time": "21:00 – 21:30",
        "color_index": 4,
    },
    # Аяқталған емдеулер (журналда көрсетіледі)
    {
        "disease_name": "Тіс ауруы",
        "medicine_id": "ketanov",
        "medicine_name": "Кетанов",
        "start_date": date(2026, 5, 1),
        "end_date": date(2026, 5, 6),
        "intake_time": "08:00 – 08:30",
        "color_index": 1,
    },
    {
        "disease_name": "Қабыну",
        "medicine_id": "azithromycin",
        "medicine_name": "Азитромицин",
        "start_date": date(2026, 4, 10),
        "end_date": date(2026, 4, 13),
        "intake_time": "09:00 – 09:30",
        "color_index": 2,
    },
    {
        "disease_name": "Асқазан қышқылдығы",
        "medicine_id": "omeprazole",
        "medicine_name": "Омепразол",
        "start_date": date(2026, 3, 1),
        "end_date": date(2026, 3, 14),
        "intake_time": "08:00 – 08:30",
        "color_index": 0,
    },
]


def seed_treatments(db: Session) -> None:
    user = db.query(User).filter(User.email == "demo@example.com").one_or_none()
    if user is None:
        return
    db.query(Treatment).filter(Treatment.user_id == user.id).delete()
    for t in DEMO_TREATMENTS:
        db.add(Treatment(user_id=user.id, **t))
    print(f"Создано {len(DEMO_TREATMENTS)} демо-лечений для {user.email}")


def main() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        reset_catalog(db)
        db.commit()
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
