"""
顺时 ShunShi - 会员支付相关模型
包含 3 张表: SubscriptionProduct, SubscriptionOrder, UserSubscription
"""
import enum
from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import String, Integer, Numeric, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, IDMixin


# ==================== 枚举定义 ====================

class SubscriptionTier(str, enum.Enum):
    """会员等级"""
    free = "free"
    yangxin = "yangxin"      # 养心
    yiyang = "yiyang"        # 益阳
    jiahe = "jiahe"          # 佳和


class PayPlatform(str, enum.Enum):
    """支付平台"""
    alipay = "alipay"
    apple = "apple"
    google = "google"


class OrderStatus(str, enum.Enum):
    """订单状态"""
    pending = "pending"
    paid = "paid"
    failed = "failed"
    refunded = "refunded"
    expired = "expired"


class SubscriptionStatus(str, enum.Enum):
    """订阅状态"""
    active = "active"
    expired = "expired"
    cancelled = "cancelled"


class ProductStatus(str, enum.Enum):
    """产品状态"""
    active = "active"
    inactive = "inactive"


class SubscriptionSource(str, enum.Enum):
    """订阅来源"""
    purchase = "purchase"
    restore = "restore"
    gift = "gift"
    admin = "admin"


# ==================== 模型定义 ====================

class SubscriptionProduct(IDMixin, Base):
    """订阅产品表"""
    __tablename__ = "sa_subscription_products"

    product_id: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, comment="产品 SKU（如 shunshi_yangxin_yearly）"
    )
    name: Mapped[str] = mapped_column(
        String(200), nullable=False, comment="产品名称"
    )
    tier: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="会员等级: free/yangxin/yiyang/jiahe"
    )
    platform: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True, comment="支付平台: alipay/apple/google"
    )
    price: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), nullable=False, default=Decimal("0.00"), comment="价格"
    )
    currency: Mapped[str] = mapped_column(
        String(10), nullable=False, default="CNY", comment="货币（默认 CNY）"
    )
    duration_days: Mapped[int] = mapped_column(
        Integer, nullable=False, default=30, comment="有效天数"
    )
    max_family_seats: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="最大家庭席位数"
    )
    features: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="权益列表（JSON）"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default=ProductStatus.active.value,
        comment="产品状态: active/inactive"
    )
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="排序权重"
    )

    # ---- 关系 ----
    orders: Mapped[list["SubscriptionOrder"]] = relationship(
        "SubscriptionOrder", back_populates="product"
    )

    def __repr__(self) -> str:
        return f"<SubscriptionProduct product_id={self.product_id!r} name={self.name!r}>"


class SubscriptionOrder(IDMixin, Base):
    """订阅订单表"""
    __tablename__ = "sa_subscription_orders"

    order_no: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, comment="订单号（唯一）"
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    product_id: Mapped[str] = mapped_column(
        ForeignKey("sa_subscription_products.id", ondelete="SET NULL"),
        nullable=True, index=True, comment="关联产品 ID"
    )
    platform: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True, comment="支付平台: alipay/apple/google"
    )
    amount: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), nullable=False, default=Decimal("0.00"), comment="实际支付金额"
    )
    currency: Mapped[str] = mapped_column(
        String(10), nullable=False, default="CNY", comment="货币"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default=OrderStatus.pending.value,
        comment="订单状态: pending/paid/failed/refunded/expired"
    )
    transaction_id: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True, comment="第三方交易号"
    )
    paid_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="支付时间"
    )
    expires_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="过期时间"
    )
    refund_reason: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True, comment="退款原因（可空）"
    )

    # ---- 关系 ----
    product: Mapped[Optional["SubscriptionProduct"]] = relationship(
        "SubscriptionProduct", back_populates="product"
    )

    def __repr__(self) -> str:
        return f"<SubscriptionOrder order_no={self.order_no!r} status={self.status!r}>"


class UserSubscription(IDMixin, Base):
    """用户订阅表（当前有效订阅）"""
    __tablename__ = "sa_user_subscriptions"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, unique=True, index=True, comment="关联用户 ID（同一用户同时仅一个活跃订阅）"
    )
    tier: Mapped[str] = mapped_column(
        String(20), nullable=False, default=SubscriptionTier.free.value,
        comment="会员等级: free/yangxin/yiyang/jiahe"
    )
    order_id: Mapped[Optional[str]] = mapped_column(
        ForeignKey("sa_subscription_orders.id", ondelete="SET NULL"),
        nullable=True, comment="关联订单 ID"
    )
    start_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="订阅开始时间"
    )
    end_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="订阅结束时间"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default=SubscriptionStatus.active.value,
        comment="订阅状态: active/expired/cancelled"
    )
    auto_renew: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, comment="是否自动续费"
    )
    source: Mapped[str] = mapped_column(
        String(20), nullable=False, default=SubscriptionSource.purchase.value,
        comment="订阅来源: purchase/restore/gift/admin"
    )

    def __repr__(self) -> str:
        return f"<UserSubscription user_id={self.user_id!r} tier={self.tier!r} status={self.status!r}>"
