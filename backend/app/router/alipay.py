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

    if trade_status in {"TRADE_SUCCESS", "TRADE_FINISHED"}:
        from app.services.payment_activation import activate_verified_domestic_payment
        try:
            amount_cents = int((Decimal(notify_data.total_amount) * 100).quantize(Decimal("1")))
        except (InvalidOperation, ValueError) as exc:
            raise HTTPException(status_code=400, detail="支付金额格式无效") from exc
        activate_verified_domestic_payment(
            request, order_no=out_trade_no, transaction_id=notify_data.trade_no,
            amount_cents=amount_cents, provider="alipay",
        )
        return {"success": True}

    # 支付宝要求返回 success
    return {"success": True}
