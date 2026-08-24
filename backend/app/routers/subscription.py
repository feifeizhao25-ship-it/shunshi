"""订阅模块：状态查询 + 购买回调占位。

回调 fail-closed：未配置 SHUNSHI_PAYMENT_CALLBACK_SECRET 时一律 503
configured:false，绝不假开通会员；配置后按 HMAC-SHA256 验签才入账。
"""

import hashlib
import hmac
import time

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..config import Settings
from ..deps import current_user, get_session, get_settings
from ..entitlements import get_registry, tier_for_product
from ..simple_models import Entitlement

router = APIRouter(prefix="/api/v1", tags=["subscription"])

SIGNATURE_HEADER = "X-Payment-Signature"


class CallbackBody(BaseModel):
    user_id: str
    product_id: str = Field(min_length=1, max_length=64)
    store: str = Field(default="unknown", max_length=32)
    expires_at: int = Field(gt=0)
    original_transaction_id: str = Field(min_length=1, max_length=128)


@router.get("/entitlements")
def entitlements_registry():
    """会员权益注册表：唯一权益事实来源，直接返回内建 JSON。"""
    return get_registry()


@router.get("/subscription/status")
def subscription_status(
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    row = session.get(Entitlement, user_id)
    if row and row.expires_at > time.time():
        # tier 由注册表 product_tier_map 同源推导，未登记商品不拔高权益
        return {
            "active": True,
            "product_id": row.product_id,
            "store": row.store,
            "expires_at": row.expires_at,
            "tier": tier_for_product(row.product_id),
        }
    return {"active": False, "plan": "free", "tier": "free"}


@router.post("/billing/callback")
async def billing_callback(
    request: Request,
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    if not settings.payment_callback_secret:
        # fail-closed：无支付商户配置时禁止开通任何会员
        raise HTTPException(
            status_code=503,
            detail={
                "detail": "支付回调未配置（缺少 SHUNSHI_PAYMENT_CALLBACK_SECRET）",
                "configured": False,
            },
        )
    raw = await request.body()
    signature = request.headers.get(SIGNATURE_HEADER, "")
    expected = hmac.new(settings.payment_callback_secret.encode(), raw, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(signature, expected):
        raise HTTPException(status_code=401, detail="回调签名验证失败")

    body = CallbackBody.model_validate(await request.json())
    if body.expires_at <= time.time():
        raise HTTPException(status_code=400, detail="订阅已过期，拒绝入账")

    existing = session.get(Entitlement, body.user_id)
    if existing:
        existing.product_id = body.product_id
        existing.store = body.store
        existing.expires_at = body.expires_at
        existing.original_transaction_id = body.original_transaction_id
        existing.updated_at = int(time.time())
    else:
        session.add(
            Entitlement(
                user_id=body.user_id,
                product_id=body.product_id,
                store=body.store,
                expires_at=body.expires_at,
                original_transaction_id=body.original_transaction_id,
            )
        )
    return {"active": True, "product_id": body.product_id, "expires_at": body.expires_at}
