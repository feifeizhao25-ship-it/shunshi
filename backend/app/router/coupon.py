"""
顺时 — 优惠券 API (shunshi-coupon)
优惠券发放、核销、查询 (PostgreSQL backed)
"""
import uuid
import random
import string
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import Coupon

router = APIRouter(prefix="/api/v1/coupon", tags=["coupon"])

_COUPON_TYPES = [
    {"id": "discount_10", "name": "九折优惠", "description": "会员订阅九折", "value": 0.9, "type": "percent"},
    {"id": "discount_20", "name": "八折优惠", "description": "会员订阅八折", "value": 0.8, "type": "percent"},
    {"id": "free_month", "name": "免费月卡", "description": "赠送一个月会员", "value": 1, "type": "free_month"},
    {"id": "cash_10", "name": "满100减10", "description": "订单满100元减10元", "value": 10.0, "type": "cash"},
    {"id": "cash_30", "name": "满200减30", "description": "订单满200元减30元", "value": 30.0, "type": "cash"},
]

_TYPE_MAP = {t["id"]: t for t in _COUPON_TYPES}


def _gen_code(length: int = 8) -> str:
    chars = string.ascii_uppercase + string.digits
    return "SS" + "".join(random.choices(chars, k=length))


class IssueIn(BaseModel):
    user_id: str
    coupon_type: str


class RedeemIn(BaseModel):
    user_id: str
    coupon_code: str


@router.post("/issue", summary="发放优惠券")
def issue_coupon(body: IssueIn, db: Session = Depends(get_db)):
    if body.coupon_type not in _TYPE_MAP:
        raise HTTPException(status_code=400, detail=f"未知优惠券类型: {body.coupon_type}")
    ctype = _TYPE_MAP[body.coupon_type]

    # Generate unique code
    for _ in range(10):
        code = _gen_code()
        if not db.query(Coupon).filter(Coupon.code == code).first():
            break

    expires_at = datetime.now() + timedelta(days=30)
    coupon = Coupon(
        id=uuid.uuid4(),
        code=code,
        user_id=body.user_id,
        coupon_type=body.coupon_type,
        value=ctype.get("value"),
        is_redeemed=False,
        expires_at=expires_at,
        issued_at=datetime.now(),
    )
    db.add(coupon)
    db.commit()
    db.refresh(coupon)
    return {
        "success": True,
        "data": {
            "coupon_code": code,
            "type": body.coupon_type,
            "type_name": ctype["name"],
            "description": ctype["description"],
            "value": ctype.get("value"),
            "expires_at": expires_at.isoformat(),
        }
    }


@router.get("/my", summary="我的优惠券")
def my_coupons(
    user_id: str = Query(...),
    include_redeemed: bool = Query(False),
    db: Session = Depends(get_db),
):
    q = db.query(Coupon).filter(Coupon.user_id == user_id)
    if not include_redeemed:
        q = q.filter(Coupon.is_redeemed == False)  # noqa: E712
    rows = q.order_by(Coupon.issued_at.desc()).all()
    return {
        "success": True,
        "data": {
            "coupons": [
                {
                    "coupon_code": r.code,
                    "type": r.coupon_type,
                    "type_name": _TYPE_MAP.get(r.coupon_type, {}).get("name", r.coupon_type),
                    "is_redeemed": r.is_redeemed,
                    "expires_at": r.expires_at.isoformat() if r.expires_at else None,
                    "issued_at": r.issued_at.isoformat(),
                }
                for r in rows
            ],
            "total": len(rows),
        }
    }


@router.post("/redeem", summary="核销优惠券")
def redeem_coupon(body: RedeemIn, db: Session = Depends(get_db)):
    coupon = db.query(Coupon).filter(
        Coupon.code == body.coupon_code,
        Coupon.user_id == body.user_id,
    ).first()
    if not coupon:
        raise HTTPException(status_code=404, detail="优惠券不存在或不属于该用户")
    if coupon.is_redeemed:
        raise HTTPException(status_code=400, detail="优惠券已被使用")
    if coupon.expires_at and coupon.expires_at < datetime.now():
        raise HTTPException(status_code=400, detail="优惠券已过期")

    coupon.is_redeemed = True
    coupon.redeemed_at = datetime.now()
    db.commit()
    ctype = _TYPE_MAP.get(coupon.coupon_type, {})
    return {
        "success": True,
        "data": {
            "coupon_code": body.coupon_code,
            "type_name": ctype.get("name", coupon.coupon_type),
            "value": ctype.get("value"),
            "redeemed_at": coupon.redeemed_at.isoformat(),
            "message": "优惠券核销成功",
        }
    }


@router.get("/validate/{coupon_code}", summary="验证优惠券")
def validate_coupon(coupon_code: str, db: Session = Depends(get_db)):
    coupon = db.query(Coupon).filter(Coupon.code == coupon_code).first()
    if not coupon:
        return {"success": True, "data": {"valid": False, "reason": "优惠券不存在"}}
    if coupon.is_redeemed:
        return {"success": True, "data": {"valid": False, "reason": "已使用"}}
    if coupon.expires_at and coupon.expires_at < datetime.now():
        return {"success": True, "data": {"valid": False, "reason": "已过期"}}
    ctype = _TYPE_MAP.get(coupon.coupon_type, {})
    return {
        "success": True,
        "data": {
            "valid": True,
            "coupon_code": coupon_code,
            "type": coupon.coupon_type,
            "type_name": ctype.get("name", coupon.coupon_type),
            "value": ctype.get("value"),
            "expires_at": coupon.expires_at.isoformat() if coupon.expires_at else None,
        }
    }


@router.get("/types", summary="优惠券类型列表")
def coupon_types():
    return {"success": True, "data": {"coupon_types": _COUPON_TYPES}}
