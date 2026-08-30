"""
顺时 ShunShi - 支付宝支付 API (CN版)
路由: /api/v1/payments/alipay/*
"""
import logging
from typing import Optional
from decimal import Decimal, InvalidOperation

from fastapi import APIRouter, Depends, HTTPException, Request, Query
from pydantic import BaseModel

from app.database.db import get_db
from app.deps import current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/payments/alipay", tags=["Alipay支付"])


# ==================== 请求模型 ====================

class CreateAlipayOrderRequest(BaseModel):
    product_sku: str  # yangxin_monthly / yiyang_yearly / family_monthly etc.
    user_id: str
    return_url: Optional[str] = None


class QueryOrderRequest(BaseModel):
    order_no: str


class RefundRequest(BaseModel):
    order_no: str
    refund_amount: str
    refund_reason: str = "用户申请退款"


# ==================== API 端点 ====================

@router.get("/products")
async def list_products():
    """列出所有支付宝产品"""
    from app.services.alipay_service import ALIPAY_PRODUCTS
    products = []
    for sku, product in ALIPAY_PRODUCTS.items():
        products.append({
            "sku": sku,
            "product_id": product["product_id"],
            "name": product["name"],
            "tier": product["tier"],
            "price": str(product["price"]),
            "currency": product["currency"],
            "duration_days": product["duration_days"],
            "max_family_seats": product["max_family_seats"],
        })
    return {"success": True, "data": products}


@router.post("/create-order")
async def create_order(request: CreateAlipayOrderRequest):
    """停用旁路入口，订单统一由订阅状态机创建并持久化。"""
    raise HTTPException(status_code=410, detail="请使用 /api/v1/subscription/create-order")


@router.get("/query-order")
async def query_order(
    order_no: str = Query(...),
    user_id: str = Depends(current_user),
):
    """查询订单状态"""
    from app.services.alipay_service import alipay_service

    _require_order_owner(order_no, user_id)
    result = alipay_service.query_order(order_no=order_no)
    return {"success": True, "data": result.model_dump()}


@router.post("/refund")
async def refund_order(
    request: RefundRequest,
    user_id: str = Depends(current_user),
):
    """申请退款"""
    from app.services.alipay_service import alipay_service

    _require_order_owner(request.order_no, user_id)
    result = alipay_service.refund(
        order_no=request.order_no,
        refund_amount=request.refund_amount,
        refund_reason=request.refund_reason,
    )
    return {"success": True, "data": result.model_dump()}


def _require_order_owner(order_no: str, user_id: str) -> None:
    row = get_db().execute(
        "SELECT user_id FROM payment_orders WHERE order_no = ?", (order_no,)
    ).fetchone()
    if not row or row["user_id"] != user_id:
        raise HTTPException(status_code=404, detail="订单不存在")


@router.post("/notify")
async def alipay_notify(request: Request):
    """支付宝回调通知"""
    from app.services.alipay_service import alipay_service
    from app.database.db import get_db
    from datetime import datetime, timedelta

    # 解析表单数据
    form_data = await request.form()
    params = dict(form_data)

    try:
        notify_data = alipay_service.verify_notify(params)
    except ValueError as e:
        logger.error(f"[Alipay] 回调验签失败: {e}")
        raise HTTPException(status_code=400, detail="签名验证失败")

    trade_status = notify_data.trade_status
    out_trade_no = notify_data.out_trade_no
    if not out_trade_no or not notify_data.trade_no:
        raise HTTPException(status_code=400, detail="支付宝交易标识缺失")

    logger.info(
        f"[Alipay] 回调: order={out_trade_no}, "
        f"status={trade_status}, trade_no={notify_data.trade_no}"
    )

    if trade_status == "TRADE_SUCCESS":
        # 支付成功 - 激活订阅
        db = get_db()
        now_dt = datetime.now()
        now = now_dt.isoformat()

        # 解析 passback_params 获取 user_id 和 sku
        passback = {}
        if notify_data.passback_params:
            for kv in notify_data.passback_params.split("&"):
                k, v = kv.split("=", 1)
                passback[k] = v

        user_id = passback.get("user_id", "")
        sku = passback.get("sku", "yangxin_monthly")

        from app.services.alipay_service import ALIPAY_PRODUCTS
        product = ALIPAY_PRODUCTS.get(sku)
        if not user_id or not product:
            logger.error("[Alipay] 回调缺少有效 user_id/sku")
            raise HTTPException(status_code=400, detail="订单归属信息无效")
        try:
            paid_amount = Decimal(notify_data.total_amount)
        except InvalidOperation as exc:
            raise HTTPException(status_code=400, detail="支付金额格式无效") from exc
        if paid_amount != product["price"]:
            logger.error("[Alipay] 回调金额不匹配: order=%s", out_trade_no)
            raise HTTPException(status_code=400, detail="支付金额不匹配")

        order_row = db.execute(
            "SELECT * FROM payment_orders WHERE order_no = ?", (out_trade_no,)
        ).fetchone()
        if not order_row:
            raise HTTPException(status_code=404, detail="支付订单不存在")
        expected_product_id = {
            "family_monthly": "jiahe_monthly",
            "family_yearly": "jiahe_yearly",
        }.get(sku, sku)
        if (
            order_row["user_id"] != user_id
            or order_row["product_id"] != expected_product_id
            or order_row["amount_cents"] != int(product["price"] * 100)
        ):
            raise HTTPException(status_code=400, detail="支付订单归属或金额不匹配")

        subscription_id = f"sub_alipay_{out_trade_no}"
        existing = db.execute(
            "SELECT id FROM subscriptions WHERE id = ?", (subscription_id,)
        ).fetchone()
        expires_at = (now_dt + timedelta(days=product["duration_days"])).isoformat()

        if not existing:
            # 记录库与认证库为独立 SQLite；先建立最小用户镜像以满足外键。
            db.execute(
                "INSERT OR IGNORE INTO users (id, name) VALUES (?, ?)",
                (user_id, "顺时用户"),
            )
            db.execute(
                """INSERT OR REPLACE INTO subscriptions
                   (id, user_id, plan, status, started_at, expires_at, auto_renew, platform, subscribed_at)
                   VALUES (?, ?, ?, 'active', ?, ?, 0, 'alipay', ?)""",
                (subscription_id, user_id, product["tier"], now, expires_at, now),
            )
            db.commit()

        db.execute(
            """UPDATE payment_orders
               SET status = 'paid', transaction_id = ?, payment_method = 'alipay', paid_at = ?
               WHERE order_no = ?""",
            (notify_data.trade_no, now, out_trade_no),
        )
        db.commit()

        # 同步统一权益表；移动端 /subscription/status 以此为事实来源。
        session_factory = getattr(request.app.state, "session_factory", None)
        if session_factory is None:
            raise HTTPException(status_code=503, detail="会员权益存储不可用")
        from app.simple_models import Entitlement

        with session_factory() as session:
            entitlement = session.get(Entitlement, user_id)
            expires_ts = int(datetime.fromisoformat(expires_at).timestamp())
            if entitlement:
                entitlement.product_id = sku
                entitlement.store = "alipay"
                entitlement.expires_at = expires_ts
                entitlement.original_transaction_id = notify_data.trade_no
                entitlement.updated_at = int(now_dt.timestamp())
            else:
                session.add(
                    Entitlement(
                        user_id=user_id,
                        product_id=sku,
                        store="alipay",
                        expires_at=expires_ts,
                        original_transaction_id=notify_data.trade_no,
                        updated_at=int(now_dt.timestamp()),
                    )
                )
            session.commit()

        # 当前进程内同步订单状态，确保客户端轮询立即得到 paid。
        from app.router import subscription as subscription_router

        for order in subscription_router.payment_orders.values():
            if order.get("order_no") != out_trade_no:
                continue
            if order.get("user_id") != user_id:
                raise HTTPException(status_code=400, detail="订单用户不匹配")
            order.update(
                {
                    "status": "paid",
                    "transaction_id": notify_data.trade_no,
                    "payment_method": "alipay",
                    "paid_at": now,
                }
            )
            break
        logger.info(f"[Alipay] 订阅激活: user={user_id}, sku={sku}")

    # 支付宝要求返回 success
    return {"success": True}
