"""
支付网关统一接口
所有支付渠道实现此接口，便于对账和新增渠道
"""
from abc import ABC, abstractmethod
from typing import Optional
from dataclasses import dataclass, field
import logging

logger = logging.getLogger(__name__)


@dataclass
class PaymentResult:
    """支付结果"""
    success: bool
    order_id: str
    transaction_id: str = ""
    amount: float = 0.0
    currency: str = "CNY"
    message: str = ""
    raw_response: dict = field(default_factory=dict)


@dataclass
class RefundResult:
    """退款结果"""
    success: bool
    refund_id: str = ""
    amount: float = 0.0
    message: str = ""


class PaymentGateway(ABC):
    """支付网关抽象基类"""

    @abstractmethod
    async def create_order(self, user_id: str, amount: float, currency: str,
                           description: str, metadata: dict = None) -> PaymentResult:
        """创建支付订单"""
        pass

    @abstractmethod
    async def verify_callback(self, request_data: dict) -> PaymentResult:
        """验证支付回调"""
        pass

    @abstractmethod
    async def query_order(self, order_id: str) -> PaymentResult:
        """查询订单状态"""
        pass

    @abstractmethod
    async def refund(self, order_id: str, amount: float, reason: str = "") -> RefundResult:
        """发起退款"""
        pass

    @abstractmethod
    async def verify_webhook(self, headers: dict, body: bytes) -> PaymentResult:
        """验证 Webhook 签名"""
        pass


def get_payment_gateway(provider: str = "stripe") -> Optional[PaymentGateway]:
    """获取支付网关实例（工厂方法）"""
    if provider == "stripe":
        try:
            from .stripe_service import StripeGateway
            return StripeGateway()
        except Exception as e:
            logger.warning(f"[Payment] Stripe gateway unavailable: {e}")
    elif provider == "alipay":
        try:
            from .alipay_service import AlipayGateway
            return AlipayGateway()
        except Exception as e:
            logger.warning(f"[Payment] Alipay gateway unavailable: {e}")
    return None
