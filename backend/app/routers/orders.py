from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.deps_auth import get_current_user
from app.models.medicine import Medicine
from app.models.order import Order, OrderItem
from app.models.user import User
from app.schemas.order import OrderCreate, OrderItemOut, OrderOut

router = APIRouter(prefix="/orders", tags=["orders"])


def _to_out(order: Order) -> OrderOut:
    return OrderOut(
        id=order.id,
        status=order.status,
        total_amount=order.total_amount,
        currency=order.currency,
        delivery_type=order.delivery_type,
        notes=order.notes,
        created_at=order.created_at,
        items=[
            OrderItemOut(
                id=item.id,
                medicine_id=item.medicine_id,
                medicine_name=item.medicine.name,
                medicine_image_url=item.medicine.image_url,
                quantity=item.quantity,
                unit_price=item.unit_price,
                total_price=item.total_price,
            )
            for item in order.items
        ],
    )


@router.get("", response_model=list[OrderOut])
def list_orders(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[OrderOut]:
    orders = (
        db.query(Order)
        .options(selectinload(Order.items).selectinload(OrderItem.medicine))
        .filter(Order.user_id == user.id)
        .order_by(Order.created_at.desc())
        .all()
    )
    return [_to_out(o) for o in orders]


@router.post("", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    payload: OrderCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> OrderOut:
    if not payload.items:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Тапсырыста тауар жоқ")

    total = 0.0
    items: list[OrderItem] = []
    for item in payload.items:
        medicine = db.get(Medicine, item.medicine_id)
        if medicine is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Дәрі табылмады")
        total_price = item.unit_price * item.quantity
        total += total_price
        items.append(
            OrderItem(
                medicine_id=item.medicine_id,
                quantity=item.quantity,
                unit_price=item.unit_price,
                total_price=total_price,
            )
        )

    order = Order(
        user_id=user.id,
        status="confirmed",
        total_amount=total,
        delivery_type="delivery" if payload.delivery_text else "pickup",
        notes=payload.delivery_text,
        items=items,
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    order = (
        db.query(Order)
        .options(selectinload(Order.items).selectinload(OrderItem.medicine))
        .filter(Order.id == order.id)
        .one()
    )
    return _to_out(order)
