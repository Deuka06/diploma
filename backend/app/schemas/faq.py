from app.schemas.common import ORMModel


class FaqOut(ORMModel):
    id: int
    question: str
    answer: str
    sort_order: int
