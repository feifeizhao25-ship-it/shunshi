"""
顺时 ShunShi - 支付宝支付服务 (CN版)
支持: 创建订单 / 查询 / 退款 / 回调验证
Mock 模式: ALIPAY_MODE=mock 时返回模拟数据

产品 ID 矩阵:
  养心月付 / 养心年付 / 益阳月付 / 益阳年付 / 佳和月付 / 佳和年付
"""
from __future__ import annotations
import os
import time
import uuid
import hmac
import hashlib
import base64
import logging
from datetime import datetime, timedelta
from typing import Optional
from decimal import Decimal

from pydantic import BaseModel

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

ALIPAY_MODE = os.getenv("ALIPAY_MODE", "mock")  # mock / sandbox / production

ALIPAY_APP_ID = os.getenv("ALIPAY_APP_ID", "")
ALIPAY_PRIVATE_KEY = os.getenv("ALIPAY_PRIVATE_KEY", "")
ALIPAY_PUBLIC_KEY = os.getenv("ALIPAY_PUBLIC_KEY", "")
ALIPAY_NOTIFY_URL = os.getenv("ALIPAY_NOTIFY_URL", "https://api.shunshi.cn/api/v1/payments/alipay/notify")
ALIPAY_RETURN_URL = os.getenv("ALIPAY_RETURN_URL", "https://app.shunshi.cn/payment/success")

# 沙箱网关
ALIPAY_GATEWAY = {
    "production": "https://openapi.alipay.com/gateway.do",
    "sandbox": "https://openapi-sandbox.dl.alipaydev.com/gateway.do",
    "mock": "https://openapi.alipay.com/gateway.do",
}

# ==================== 产品定义 ====================

ALIPAY_PRODUCTS: dict[str, dict] = {
    "yangxin_monthly": {
        "product_id": "shunshi_yangxin_monthly",
        "name": "养心·月付",
        "tier": "yangxin",
        "price": Decimal("29.90"),
        "currency": "CNY",
        "duration_days": 30,
        "max_family_seats": 0,
    },
    "yangxin_yearly": {
        "product_id": "shunshi_yangxin_yearly",
        "name": "养心·年付",
        "tier": "yangxin",
        "price": Decimal("299.00"),
        "currency": "CNY",
        "duration_days": 365,
        "max_family_seats": 0,
    },
    "yiyang_monthly": {
        "product_id": "shunshi_yiyang_monthly",
        "name": "益阳·月付",
        "tier": "yiyang",
        "price": Decimal("59.90"),
        "currency": "CNY",
        "duration_days": 30,
        "max_family_seats": 3,
    },
    "yiyang_yearly": {
        "product_id": "shunshi_yiyang_yearly",
        "name": "益阳·年付",
        "tier": "yiyang",
        "price": Decimal("599.00"),
        "currency": "CNY",
        "duration_days": 365,
        "max_family_seats": 3,
    },
    "family_monthly": {
        "product_id": "shunshi_family_monthly",
        "name": "佳和·月付",
        "tier": "jiahe",
        "price": Decimal("89.90"),
        "currency": "CNY",
        "duration_days": 30,
        "max_family_seats": 5,
    },
    "family_yearly": {
        "product_id": "shunshi_family_yearly",
        "name": "佳和·年付",
        "tier": "jiahe",
        "price": Decimal("899.00"),
        "currency": "CNY",
        "duration_days": 365,
        "max_family_seats": 5,
    },
}


# ==================== 数据模型 ====================

class AlipayOrderResult(BaseModel):
    """支付宝订单创建结果"""
    order_no: str
    pay_url: str
    total_amount: str
    product_id: str
    mode: str


class AlipayQueryResult(BaseModel):
    """支付宝订单查询结果"""
    order_no: str
    trade_no: str
    trade_status: str  # WAIT_BUYER_PAY / TRADE_SUCCESS / TRADE_CLOSED
    total_amount: str
    buyer_id: str


class AlipayRefundResult(BaseModel):
    """支付宝退款结果"""
    order_no: str
    refund_no: str
    refund_amount: str
    refund_status: str


class AlipayNotifyData(BaseModel):
    """支付宝回调数据"""
    out_trade_no: str
    trade_no: str
    trade_status: str
    total_amount: str
    buyer_id: str
    passback_params: str = ""
    gmt_payment: str = ""


# ==================== 服务实现 ====================

class AlipayService:
    """支付宝支付服务"""

    def __init__(self) -> None:
        self.mode = ALIPAY_MODE
        self.gateway = ALIPAY_GATEWAY.get(self.mode, ALIPAY_GATEWAY["production"])
        self._client = None

    def _get_client(self):
        """延迟初始化支付宝 SDK 客户端"""
        if self._client:
            return self._client

        if self.mode == "mock":
            return None

        if not ALIPAY_APP_ID or not ALIPAY_PRIVATE_KEY:
            logger.warning("[Alipay] 缺少 APP_ID 或 PRIVATE_KEY，降级到 mock 模式")
            self.mode = "mock"
            return None

        try:
            from alipay import AliPay
            self._client = AliPay(
                appid=ALIPAY_APP_ID,
                app_notify_url=ALIPAY_NOTIFY_URL,
                app_private_key_string=ALIPAY_PRIVATE_KEY,
                alipay_public_key_string=ALIPAY_PUBLIC_KEY,
                sign_type="RSA2",
                debug=(self.mode == "sandbox"),
            )
            logger.info(f"[Alipay] SDK 初始化完成 (mode={self.mode})")
            return self._client
        except ImportError:
            logger.warning("[Alipay] python-alipay-sdk 未安装，运行 mock 模式")
            self.mode = "mock"
            return None

    def create_order(
        self,
        product_sku: str,
        user_id: str,
        return_url: Optional[str] = None,
    ) -> AlipayOrderResult:
        """创建支付订单

        Args:
            product_sku: 产品 SKU，如 yangxin_monthly
            user_id: 用户 ID
            return_url: 支付完成跳转 URL

        Returns:
            AlipayOrderResult
        """
        product = ALIPAY_PRODUCTS.get(product_sku)
        if not product:
            raise ValueError(f"未知产品 SKU: {product_sku}")

        order_no = f"AP{datetime.now().strftime('%Y%m%d%H%M%S')}{uuid.uuid4().hex[:8]}"
        total_amount = str(product["price"])

        client = self._get_client()

        if client and self.mode != "mock":
            # 真实支付宝调用
            pay_url = client.api_alipay_trade_page_pay(
                out_trade_no=order_no,
                total_amount=total_amount,
                subject=product["name"],
                return_url=return_url or ALIPAY_RETURN_URL,
                notify_url=ALIPAY_NOTIFY_URL,
                passback_params=f"user_id={user_id}&sku={product_sku}",
            )
            logger.info(f"[Alipay] 创建订单: {order_no}, sku={product_sku}")
        else:
            # Mock 模式 — 优雅降级
            logger.warning("Alipay APP_ID/PRIVATE_KEY not configured, payment disabled")
            raise RuntimeError("支付服务未配置，请联系管理员")

        return AlipayOrderResult(
            order_no=order_no,
            pay_url=pay_url,
            total_amount=total_amount,
            product_id=product["product_id"],
            mode=self.mode,
        )

    def query_order(self, order_no: str) -> AlipayQueryResult:
        """查询订单状态"""
        client = self._get_client()

        if client and self.mode != "mock":
            result = client.api_alipay_trade_query(out_trade_no=order_no)
            return AlipayQueryResult(
                order_no=result.get("out_trade_no", order_no),
                trade_no=result.get("trade_no", ""),
                trade_status=result.get("trade_status", "UNKNOWN"),
                total_amount=result.get("total_amount", "0.00"),
                buyer_id=result.get("buyer_id", ""),
            )
        else:
            # Mock 模式 — 优雅降级
            logger.warning("Alipay not configured, query disabled")
            raise RuntimeError("支付服务未配置，请联系管理员")

    def refund(
        self,
        order_no: str,
        refund_amount: str,
        refund_reason: str = "用户申请退款",
    ) -> AlipayRefundResult:
        """申请退款"""
        client = self._get_client()
        refund_no = f"RF{datetime.now().strftime('%Y%m%d%H%M%S')}{uuid.uuid4().hex[:8]}"

        if client and self.mode != "mock":
            result = client.api_alipay_trade_refund(
                out_trade_no=order_no,
                refund_amount=refund_amount,
                refund_reason=refund_reason,
                out_request_no=refund_no,
            )
            return AlipayRefundResult(
                order_no=order_no,
                refund_no=refund_no,
                refund_amount=refund_amount,
                refund_status="SUCCESS" if result.get("code") == "10000" else "FAILED",
            )
        else:
            logger.warning("Alipay not configured, refund disabled")
            raise RuntimeError("支付服务未配置，请联系管理员")

    def verify_notify(self, params: dict) -> AlipayNotifyData:
        """验证支付宝回调签名并解析数据"""
        client = self._get_client()

        if client and self.mode != "mock":
            signature = params.pop("sign", None)
            sign_type = params.pop("sign_type", None)
            # python-alipay-sdk 验签
            is_valid = client.verify(params, signature)
            if not is_valid:
                raise ValueError("支付宝回调签名验证失败")
        else:
            logger.info("[Alipay] Mock 模式 - 跳过回调验签")

        return AlipayNotifyData(
            out_trade_no=params.get("out_trade_no", ""),
            trade_no=params.get("trade_no", ""),
            trade_status=params.get("trade_status", ""),
            total_amount=params.get("total_amount", "0.00"),
            buyer_id=params.get("buyer_id", ""),
            passback_params=params.get("passback_params", ""),
            gmt_payment=params.get("gmt_payment", ""),
        )


# ==================== PaymentGateway 适配器 ====================


class AlipayGateway:
    """Alipay PaymentGateway 适配器 — 委托给 AlipayService 单例"""

    def __init__(self) -> None:
        self._svc = alipay_service

    async def create_order(self, user_id: str, amount: float, currency: str,
                           description: str, metadata: dict = None) -> "PaymentResult":  # noqa: F821
        """创建支付订单"""
        from .payment_gateway import PaymentResult
        try:
            sku = (metadata or {}).get("sku", "yangxin_monthly")
            result = self._svc.create_order(product_sku=sku, user_id=user_id)
            return PaymentResult(
                success=True,
                order_id=result.order_no,
                transaction_id=result.order_no,
                amount=float(result.total_amount),
                currency=currency,
                message="Alipay order created",
                raw_response={"pay_url": result.pay_url, "mode": result.mode},
            )
        except Exception as e:
            return PaymentResult(
                success=False, order_id="", amount=amount, currency=currency,
                message=str(e),
            )

    async def verify_callback(self, request_data: dict) -> "PaymentResult":  # noqa: F821
        """验证支付回调"""
        from .payment_gateway import PaymentResult
        try:
            notify = self._svc.verify_notify(params=dict(request_data))
            return PaymentResult(
                success=notify.trade_status == "TRADE_SUCCESS",
                order_id=notify.out_trade_no,
                transaction_id=notify.trade_no,
                amount=float(notify.total_amount),
                currency="CNY",
                message=notify.trade_status,
                raw_response=notify.model_dump(),
            )
        except Exception as e:
            return PaymentResult(success=False, order_id="", message=str(e))

    async def query_order(self, order_id: str) -> "PaymentResult":  # noqa: F821
        """查询订单状态"""
        from .payment_gateway import PaymentResult
        try:
            result = self._svc.query_order(order_no=order_id)
            return PaymentResult(
                success=result.trade_status == "TRADE_SUCCESS",
                order_id=result.order_no,
                transaction_id=result.trade_no,
                amount=float(result.total_amount),
                currency="CNY",
                message=result.trade_status,
            )
        except Exception as e:
            return PaymentResult(success=False, order_id=order_id, message=str(e))

    async def refund(self, order_id: str, amount: float, reason: str = "") -> "RefundResult":  # noqa: F821
        """发起退款"""
        from .payment_gateway import RefundResult
        try:
            result = self._svc.refund(
                order_no=order_id, refund_amount=str(amount), refund_reason=reason,
            )
            return RefundResult(
                success=result.refund_status == "SUCCESS",
                refund_id=result.refund_no,
                amount=float(result.refund_amount),
                message=result.refund_status,
            )
        except Exception as e:
            return RefundResult(success=False, amount=amount, message=str(e))

    async def verify_webhook(self, headers: dict, body: bytes) -> "PaymentResult":  # noqa: F821
        """验证 Webhook 签名 — 支付宝通过回调参数验签"""
        from .payment_gateway import PaymentResult
        try:
            import json
            data = json.loads(body) if isinstance(body, bytes) else body
            notify = self._svc.verify_notify(params=dict(data))
            return PaymentResult(
                success=notify.trade_status == "TRADE_SUCCESS",
                order_id=notify.out_trade_no,
                transaction_id=notify.trade_no,
                amount=float(notify.total_amount),
                currency="CNY",
                message=notify.trade_status,
                raw_response=notify.model_dump(),
            )
        except Exception as e:
            return PaymentResult(success=False, order_id="", message=str(e))


# ==================== 单例 ====================

alipay_service = AlipayService()
