"""
顺时 ShunShi - 支付宝支付 API (CN版)
路由: /api/v1/payments/alipay/*
"""
import logging
from typing import Optional

from fastapi import APIRouter, HTTPException, Request, Query
from pydantic import BaseModel

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
    """创建支付宝支付订单"""
    from app.services.alipay_service import alipay_service

    try:
        result = alipay_service.create_order(
            product_sku=request.product_sku,
            user_id=request.user_id,
            return_url=request.return_url,
        )
        return {"success": True, "data": result.model_dump()}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/query-order")
async def query_order(order_no: str = Query(...)):
    """查询订单状态"""
    from app.services.alipay_service import alipay_service

    result = alipay_service.query_order(order_no=order_no)
    return {"success": True, "data": result.model_dump()}


@router.post("/refund")
async def refund_order(request: RefundRequest):
    """申请退款"""
    from app.services.alipay_service import alipay_service

    result = alipay_service.refund(
        order_no=request.order_no,
        refund_amount=request.refund_amount,
        refund_reason=request.refund_reason,
    )
    return {"success": True, "data": result.model_dump()}


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

    logger.info(
        f"[Alipay] 回调: order={out_trade_no}, "
        f"status={trade_status}, trade_no={notify_data.trade_no}"
    )

    if trade_status == "TRADE_SUCCESS":
        # 支付成功 - 激活订阅
        db = get_db()
        now = datetime.now().isoformat()
        expires_at = (datetime.now() + timedelta(days=30)).isoformat()

        # 解析 passback_params 获取 user_id 和 sku
        passback = {}
        if notify_data.passback_params:
            for kv in notify_data.passback_params.split("&"):
                k, v = kv.split("=", 1)
                passback[k] = v

        user_id = passback.get("user_id", "")
        sku = passback.get("sku", "yangxin_monthly")

        from app.services.alipay_service import ALIPAY_PRODUCTS
        product = ALIPAY_PRODUCTS.get(sku, {})

        # 更新用户订阅
        db.execute(
            """INSERT OR REPLACE INTO subscriptions
               (id, user_id, plan, status, started_at, expires_at, auto_renew, platform, subscribed_at)
               VALUES (?, ?, ?, 'active', ?, ?, 1, 'alipay', ?)""",
            (f"sub_alipay_{out_trade_no}", user_id, product.get("tier", sku),
             now, expires_at, now),
        )
        db.commit()
        logger.info(f"[Alipay] 订阅激活: user={user_id}, sku={sku}")

    # 支付宝要求返回 success
    return {"success": True}
