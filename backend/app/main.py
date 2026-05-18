from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.database import Base, engine
from app.routers.appointments import router as appointments_router
from app.routers.auth import router as auth_router
from app.routers.chat import router as chat_router
from app.routers.checkout import router as checkout_router
from app.routers.faqs import router as faqs_router
from app.routers.health import router as health_router
from app.routers.medicines import router as medicines_router
from app.routers.reminders import router as reminders_router
from app.routers.treatments import router as treatments_router
from app.routers.users import router as users_router


@asynccontextmanager
async def lifespan(_app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


settings = get_settings()
app = FastAPI(
    title="MEDI API",
    description="Backend для дипломного проекта MEDI (пациент, лекарства, аллергии).",
    version="0.2.0",
    lifespan=lifespan,
)

_origins = settings.cors_origin_list
_use_cred = _origins != ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=_use_cred,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(medicines_router)
app.include_router(treatments_router)
app.include_router(appointments_router)
app.include_router(reminders_router)
app.include_router(checkout_router)
app.include_router(faqs_router)
app.include_router(chat_router)


@app.get("/")
def root() -> dict[str, str]:
    return {"name": "MEDI API", "docs": "/docs"}
