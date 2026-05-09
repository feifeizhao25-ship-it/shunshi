"""
顺时 — 健康礼品 API (shunshi-gifting)
健康礼品套装、节气礼盒、礼品卡发送 (PostgreSQL backed)
"""
import uuid
import random
import string
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import GiftOrder, GiftCard

router = APIRouter(prefix="/api/v1/gifting", tags=["gifting"])

_PRODUCTS = {
    "tcm_tea_set": {
        "product_id": "tcm_tea_set",
        "name": "节气养生茶礼盒",
        "description": "精选二十四节气对应养生茶，包含春夏秋冬四季茶各2款，共8款",
        "price": 288.0,
        "category": "tea",
        "image_url": "/images/gifts/tcm_tea_set.jpg",
    },
    "herbal_kit": {
        "product_id": "herbal_kit",
        "name": "中草药养生套装",
        "description": "枸杞、红枣、黄芪、党参精选组合，补气养血",
        "price": 168.0,
        "category": "herbal",
        "image_url": "/images/gifts/herbal_kit.jpg",
    },
    "acupoint_tool": {
        "product_id": "acupoint_tool",
        "name": "经络养生工具套装",
        "description": "艾灸棒、刮痧板、穴位按摩棒三件套",
        "price": 198.0,
        "category": "tool",
        "image_url": "/images/gifts/acupoint_tool.jpg",
    },
    "membership_gift": {
        "product_id": "membership_gift",
        "name": "顺时会员礼品卡",
        "description": "3个月高级会员资格，享受全部TCM健康功能",
        "price": 99.0,
        "category": "membership",
        "image_url": "/images/gifts/membership_gift.jpg",
    },
    "wellness_book": {
        "product_id": "wellness_book",
        "name": "中医养生精装书籍",
        "description": "《顺时养生》精装版，涵盖节气、体质、食疗全知识",
        "price": 68.0,
        "category": "book",
        "image_url": "/images/gifts/wellness_book.jpg",
    },
}

_DENOMINATIONS = [50, 100, 200, 500]


def _gen_card_code() -> str:
    return "GC" + "".join(random.choices(string.ascii_uppercase + string.digits, k=10))


class OrderIn(BaseModel):
    buyer_id: str
    product_id: str
    recipient_id: Optional[str] = None
    message: Optional[str] = None


class GiftCardCreateIn(BaseModel):
    buyer_id: str
    denomination: float = Field(..., gt=0)
    message: Optional[str] = None


class GiftCardRedeemIn(BaseModel):
    user_id: str


@router.get("/products", summary="礼品产品列表")
def list_products(category: Optional[str] = None):
    products = list(_PRODUCTS.values())
    if category:
        products = [p for p in products if p["category"] == category]
    return {
        "success": True,
        "data": {"products": products, "total": len(products)}
    }


@router.get("/products/{product_id}", summary="礼品详情")
def get_product(product_id: str):
    if product_id not in _PRODUCTS:
        raise HTTPException(status_code=404, detail="礼品不存在")
    return {"success": True, "data": _PRODUCTS[product_id]}


@router.post("/orders", summary="创建礼品订单")
def create_order(body: OrderIn, db: Session = Depends(get_db)):
    if body.product_id not in _PRODUCTS:
        raise HTTPException(status_code=404, detail="礼品不存在")
    order = GiftOrder(
        id=uuid.uuid4(),
        buyer_id=body.buyer_id,
        recipient_id=body.recipient_id,
        product_id=body.product_id,
        message=body.message,
        status="pending",
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    product = _PRODUCTS[body.product_id]
    return {
        "success": True,
        "data": {
            "order_id": str(order.id),
            "product": product,
            "recipient_id": body.recipient_id,
            "status": "pending",
            "message": body.message,
            "created_at": order.created_at.isoformat(),
        }
    }


@router.get("/orders/{order_id}", summary="查询订单状态")
def get_order(order_id: str, db: Session = Depends(get_db)):
    try:
        oid = uuid.UUID(order_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="订单不存在")
    order = db.query(GiftOrder).filter(GiftOrder.id == oid).first()
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    return {
        "success": True,
        "data": {
            "order_id": str(order.id),
            "buyer_id": order.buyer_id,
            "recipient_id": order.recipient_id,
            "product": _PRODUCTS.get(order.product_id, {"product_id": order.product_id}),
            "status": order.status,
            "message": order.message,
            "created_at": order.created_at.isoformat(),
        }
    }


@router.post("/gift-cards/create", summary="创建礼品卡")
def create_gift_card(body: GiftCardCreateIn, db: Session = Depends(get_db)):
    if body.denomination not in _DENOMINATIONS:
        raise HTTPException(
            status_code=400,
            detail=f"支持的礼品卡面额: {_DENOMINATIONS}",
        )
    for _ in range(10):
        code = _gen_card_code()
        if not db.query(GiftCard).filter(GiftCard.code == code).first():
            break

    card = GiftCard(
        id=uuid.uuid4(),
        code=code,
        buyer_id=body.buyer_id,
        denomination=body.denomination,
        message=body.message,
        is_redeemed=False,
        created_at=datetime.now(),
    )
    db.add(card)
    db.commit()
    db.refresh(card)
    return {
        "success": True,
        "data": {
            "card_code": code,
            "denomination": body.denomination,
            "message": body.message,
            "created_at": card.created_at.isoformat(),
        }
    }


@router.post("/gift-cards/{code}/redeem", summary="兑换礼品卡")
def redeem_gift_card(code: str, body: GiftCardRedeemIn, db: Session = Depends(get_db)):
    card = db.query(GiftCard).filter(GiftCard.code == code).first()
    if not card:
        raise HTTPException(status_code=404, detail="礼品卡不存在")
    if card.is_redeemed:
        raise HTTPException(status_code=400, detail="礼品卡已被兑换")
    card.is_redeemed = True
    card.redeemed_by = body.user_id
    card.redeemed_at = datetime.now()
    db.commit()
    return {
        "success": True,
        "data": {
            "card_code": code,
            "denomination": card.denomination,
            "redeemed_by": body.user_id,
            "redeemed_at": card.redeemed_at.isoformat(),
            "message": f"礼品卡兑换成功！获得 ¥{card.denomination} 账户余额",
        }
    }


@router.get("/denominations", summary="礼品卡面额")
def get_denominations():
    return {
        "success": True,
        "data": {
            "denominations": [
                {"value": d, "label": f"¥{d}"} for d in _DENOMINATIONS
            ]
        }
    }
