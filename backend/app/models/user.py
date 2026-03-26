"""
顺时 ShunShi - 用户相关模型
包含 4 张表: User, UserPreference, UserDevice, UserMemory
"""
import enum
from datetime import time, datetime
from typing import Optional, Any

from sqlalchemy import String, Integer, Float, Boolean, DateTime, Time, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, IDMixin


# ==================== 枚举定义 ====================

class Gender(str, enum.Enum):
    """性别"""
    male = "male"
    female = "female"
    other = "other"


class LifeStage(str, enum.Enum):
    """人生阶段（根据年龄自动映射）"""
    exploring = "exploring"      # 探索期 (18-30)
    stressed = "stressed"        # 压力期 (30-40)
    healthy = "healthy"          # 养生期 (40-55)
    companion = "companion"      # 陪伴期 (55+)


class UserStatus(str, enum.Enum):
    """用户状态"""
    active = "active"
    suspended = "suspended"
    deleted = "deleted"


class AuthProvider(str, enum.Enum):
    """认证方式"""
    phone = "phone"
    apple = "apple"
    wechat = "wechat"
    guest = "guest"


class ReminderStyle(str, enum.Enum):
    """提醒风格"""
    gentle = "gentle"
    moderate = "moderate"


class InteractionStyle(str, enum.Enum):
    """交互风格"""
    warm = "warm"
    professional = "professional"
    playful = "playful"


class MemoryType(str, enum.Enum):
    """记忆类型"""
    preference = "preference"
    habit = "habit"
    life_phase_summary = "life_phase_summary"
    interaction_style = "interaction_style"


class MemorySource(str, enum.Enum):
    """记忆来源"""
    manual = "manual"
    ai_inferred = "ai_inferred"


class MemoryCreatedBy(str, enum.Enum):
    """记忆创建者"""
    user = "user"
    ai_system = "ai_system"


class DevicePlatform(str, enum.Enum):
    """设备平台"""
    ios = "ios"
    android = "android"
    web = "web"


# ==================== 模型定义 ====================

class User(IDMixin, Base):
    """用户表"""
    __tablename__ = "sa_users"

    # 基本信息
    phone: Mapped[Optional[str]] = mapped_column(
        String(20), unique=True, nullable=True, comment="手机号（唯一，可空）"
    )
    email: Mapped[Optional[str]] = mapped_column(
        String(255), unique=True, nullable=True, comment="邮箱（唯一，可空）"
    )
    nickname: Mapped[str] = mapped_column(
        String(100), nullable=False, default="用户", comment="昵称"
    )
    avatar: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True, comment="头像 URL"
    )

    # 人口统计
    gender: Mapped[Optional[str]] = mapped_column(
        String(10), nullable=True, comment="性别: male/female/other"
    )
    age: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="年龄"
    )
    life_stage: Mapped[str] = mapped_column(
        String(20), nullable=False, default=LifeStage.exploring.value,
        comment="人生阶段: exploring/stressed/healthy/companion"
    )

    # 状态
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default=UserStatus.active.value,
        comment="用户状态: active/suspended/deleted"
    )

    # 认证信息
    auth_provider: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True, comment="认证方式: phone/apple/wechat/guest"
    )
    auth_provider_id: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True, comment="第三方认证 ID"
    )

    # 登录信息
    last_login_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="最后登录时间"
    )
    last_login_ip: Mapped[Optional[str]] = mapped_column(
        String(45), nullable=True, comment="最后登录 IP"
    )

    # ---- 关系 ----
    preferences: Mapped["UserPreference"] = relationship(
        "UserPreference", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    devices: Mapped[list["UserDevice"]] = relationship(
        "UserDevice", back_populates="user", cascade="all, delete-orphan"
    )
    memories: Mapped[list["UserMemory"]] = relationship(
        "UserMemory", back_populates="user", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<User id={self.id!r} nickname={self.nickname!r}>"


class UserPreference(IDMixin, Base):
    """用户偏好设置表"""
    __tablename__ = "sa_user_preferences"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, unique=True, index=True, comment="关联用户 ID"
    )

    # 作息
    sleep_time: Mapped[time] = mapped_column(
        Time, nullable=False, default=time(23, 0), comment="睡眠时间，默认 23:00"
    )
    wake_time: Mapped[time] = mapped_column(
        Time, nullable=False, default=time(7, 0), comment="起床时间，默认 07:00"
    )

    # 风格
    reminder_style: Mapped[str] = mapped_column(
        String(20), nullable=False, default=ReminderStyle.gentle.value,
        comment="提醒风格: gentle/moderate"
    )
    interaction_style: Mapped[str] = mapped_column(
        String(20), nullable=False, default=InteractionStyle.warm.value,
        comment="交互风格: warm/professional/playful"
    )

    # 开关
    memory_enabled: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, comment="是否启用记忆功能"
    )
    proactive_enabled: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, comment="是否启用主动关怀"
    )

    # 免打扰时段
    quiet_hours_start: Mapped[time] = mapped_column(
        Time, nullable=False, default=time(23, 0), comment="免打扰开始时间，默认 23:00"
    )
    quiet_hours_end: Mapped[time] = mapped_column(
        Time, nullable=False, default=time(7, 0), comment="免打扰结束时间，默认 07:00"
    )

    # 语言
    locale: Mapped[str] = mapped_column(
        String(10), nullable=False, default="zh-CN", comment="语言设置，默认 zh-CN"
    )

    # JSON 字段
    dietary_restrictions: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="饮食限制"
    )
    interests: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="兴趣标签"
    )

    # ---- 关系 ----
    user: Mapped["User"] = relationship("User", back_populates="preferences")

    def __repr__(self) -> str:
        return f"<UserPreference user_id={self.user_id!r}>"


class UserDevice(IDMixin, Base):
    """用户设备表"""
    __tablename__ = "sa_user_devices"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    device_id: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, comment="设备唯一标识"
    )
    platform: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="平台: ios/android/web"
    )
    push_token: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True, comment="推送令牌"
    )
    app_version: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, comment="APP 版本"
    )
    os_version: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, comment="操作系统版本"
    )
    last_active_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="最后活跃时间"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, comment="设备是否活跃"
    )

    # ---- 关系 ----
    user: Mapped["User"] = relationship("User", back_populates="devices")

    def __repr__(self) -> str:
        return f"<UserDevice device_id={self.device_id!r} platform={self.platform!r}>"


class UserMemory(IDMixin, Base):
    """用户记忆表（AI 记忆 / 用户标记）"""
    __tablename__ = "sa_user_memories"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    memory_type: Mapped[str] = mapped_column(
        String(30), nullable=False,
        comment="记忆类型: preference/habit/life_phase_summary/interaction_style"
    )
    content: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="记忆内容（JSON）"
    )
    source: Mapped[str] = mapped_column(
        String(20), nullable=False, default=MemorySource.ai_inferred.value,
        comment="来源: manual/ai_inferred"
    )
    confidence: Mapped[float] = mapped_column(
        Float, nullable=False, default=1.0, comment="置信度 (0-1)"
    )
    expires_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="过期时间（可空，永不过期）"
    )
    created_by: Mapped[str] = mapped_column(
        String(20), nullable=False, default=MemoryCreatedBy.ai_system.value,
        comment="创建者: user/ai_system"
    )

    # ---- 关系 ----
    user: Mapped["User"] = relationship("User", back_populates="memories")

    def __repr__(self) -> str:
        return f"<UserMemory user_id={self.user_id!r} type={self.memory_type!r}>"
