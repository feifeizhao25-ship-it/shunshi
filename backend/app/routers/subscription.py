"""订阅模块：状态查询 + 购买回调。

回调 fail-closed：未配置 SHUNSHI_PAYMENT_CALLBACK_SECRET 时一律 503
configured:false，绝不假开通会员。配置后除 HMAC-SHA256 验签外，还要求
商品在权益注册表内、金额与在售标价一致（有标价时），并且存在一笔用户、
商品、金额都相符的待支付订单，否则拒绝入账。
"""

import hashlib
import json
from pydantic import ValidationError
import hmac
import time

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..config import Settings
from ..deps import current_user, get_session, get_settings
from ..entitlements import get_registry
from ..locale_context import RequestLocale, request_locale
from ..simple_models import Entitlement

router = APIRouter(prefix="/api/v1", tags=["subscription"])

SIGNATURE_HEADER = "X-Payment-Signature"


class CallbackBody(BaseModel):
    user_id: str
    product_id: str = Field(min_length=1, max_length=64)
    store: str = Field(default="unknown", max_length=32)
    expires_at: int = Field(gt=0)
    original_transaction_id: str = Field(min_length=1, max_length=128)
    order_no: str = Field(min_length=1, max_length=64)
    amount_cents: int = Field(gt=0)


@router.get("/entitlements")
def entitlements_registry():
    """会员权益注册表：唯一权益事实来源，直接返回内建 JSON。"""
    return get_registry()


@router.get("/subscription/status")
def subscription_status(
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    from ..services.membership_status import membership_status
    return membership_status(session, user_id)


@router.get("/subscription/plan-usage")
async def subscription_usage(
    locale: RequestLocale = Depends(request_locale),
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    """Plan, limits and today's real usage for the plan & usage page (English for the international edition)."""
    from ..services.usage_report import build

    return await build(session, settings.redis_url, user_id, "en" if locale.is_global else "zh")


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

    try:
        body = CallbackBody.model_validate(json.loads(raw))
    except (ValueError, ValidationError) as exc:
        # 签名已通过但请求体格式不对：属于调用方错误，返回 422 而不是 500
        raise HTTPException(status_code=422, detail="回调请求体格式不正确") from exc
    if body.expires_at <= time.time():
        raise HTTPException(status_code=400, detail="订阅已过期，拒绝入账")
    _reject_unlisted_or_overlong(body.product_id, body.expires_at, body.amount_cents)
    replay = _claim_matching_pending_order(
        order_no=body.order_no,
        user_id=body.user_id,
        product_id=body.product_id,
        amount_cents=body.amount_cents,
        transaction_id=body.original_transaction_id,
    )
    existing = session.get(Entitlement, body.user_id)
    if replay and existing is not None:
        # 同一笔流水重放只回读已入账的到期时间，不再按回调里的 expires_at 延长。
        return {"active": True, "product_id": existing.product_id, "expires_at": existing.expires_at}
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


def _registered_product(product_id: str) -> bool:
    registry = get_registry()
    return product_id in (registry.get("product_tier_map") or {}) or product_id in (
        registry.get("legacy_product_tier_map") or {}
    )


def _catalog_price_cents(product_id: str) -> int | None:
    """Server price for this SKU. None when the registry product is not on the price list."""
    from ..router.subscription import SUBSCRIPTION_PRODUCTS

    prices = {
        int(product["price_cents"])
        for product in SUBSCRIPTION_PRODUCTS
        if product.get("product_id") == product_id and product.get("price_cents")
    }
    if len(prices) == 1:
        return prices.pop()
    return None


def _reject_unlisted_or_overlong(product_id: str, expires_at: int, amount_cents: int) -> None:
    if not _registered_product(product_id):
        raise HTTPException(status_code=400, detail="未知商品，拒绝入账")
    catalog_price = _catalog_price_cents(product_id)
    if catalog_price is not None and int(amount_cents) != catalog_price:
        raise HTTPException(status_code=400, detail="支付金额与商品标价不一致")
    window = 40 * 86400 if product_id.endswith(("_monthly", ".monthly")) else 400 * 86400
    if expires_at > int(time.time()) + window:
        raise HTTPException(status_code=400, detail="订阅到期时间超出该商品的有效期限")


def _claim_matching_pending_order(
    *,
    order_no: str,
    user_id: str,
    product_id: str,
    amount_cents: int,
    transaction_id: str,
) -> bool:
    """Mark one pending order paid. Return True when this transaction was already claimed."""
    from ..database.db import close_test_connection, get_db
    from ..router.subscription import _ensure_payment_orders_table, payment_orders

    db = get_db()
    try:
        _ensure_payment_orders_table(db)
        row = db.execute(
            "SELECT * FROM payment_orders WHERE order_no = ?",
            (order_no,),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=400, detail="没有匹配的待支付订单")
        order = dict(row)
        if order["user_id"] != user_id or order["product_id"] != product_id:
            raise HTTPException(status_code=400, detail="订单与回调的用户或商品不一致")
        if int(order["amount_cents"]) != int(amount_cents):
            raise HTTPException(status_code=400, detail="支付金额与订单不匹配")
        if order["status"] == "paid" and order.get("transaction_id") == transaction_id:
            return True
        if order["status"] != "pending":
            raise HTTPException(status_code=409, detail="订单状态不允许入账")
        paid_at = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        changed = db.execute(
            """UPDATE payment_orders
               SET status='paid', transaction_id=?, paid_at=?
               WHERE order_no=? AND status='pending' AND user_id=?
                 AND product_id=? AND amount_cents=?""",
            (transaction_id, paid_at, order_no, user_id, product_id, int(amount_cents)),
        )
        if changed.rowcount != 1:
            db.rollback()
            raise HTTPException(status_code=409, detail="订单状态已变化，拒绝入账")
        db.commit()
    finally:
        close_test_connection(db)
    for cached in payment_orders.values():
        if cached.get("order_no") == order_no:
            cached.update(status="paid", transaction_id=transaction_id, paid_at=paid_at)
    return False
