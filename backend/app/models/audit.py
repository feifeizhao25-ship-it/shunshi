"""
顺时 ShunShi - 审计与配置相关模型
包含 3 张表: AiAuditLog, PromptVersion, FeatureFlag
"""
from decimal import Decimal
from datetime import datetime
from typing import Optional

from sqlalchemy import String, Integer, Numeric, Boolean, Text, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, IDMixin


# ==================== 模型定义 ====================

class AiAuditLog(IDMixin, Base):
    """AI 调用审计日志表"""
    __tablename__ = "sa_ai_audit_logs"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="SET NULL"),
        nullable=True, index=True, comment="关联用户 ID"
    )
    session_id: Mapped[Optional[str]] = mapped_column(
        ForeignKey("sa_conversation_sessions.id", ondelete="SET NULL"),
        nullable=True, index=True, comment="关联对话会话 ID（可空）"
    )
    provider_name: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="AI 提供商名称"
    )
    model_name: Mapped[str] = mapped_column(
        String(100), nullable=False, comment="模型名称"
    )
    prompt_versions: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="使用的 prompt 版本列表（JSON）"
    )
    skill_chain: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="skill 链（JSON）"
    )
    tokens_in: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="输入 token 数"
    )
    tokens_out: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="输出 token 数"
    )
    latency_ms: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="响应延迟（毫秒）"
    )
    safety_flag: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, comment="安全标记"
    )
    route_decision: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="路由决策（JSON）"
    )
    response_status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="success",
        comment="响应状态: success/failed/timeout/filtered"
    )
    error_message: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="错误信息（可空）"
    )
    cost_usd: Mapped[Decimal] = mapped_column(
        Numeric(10, 6), nullable=False, default=Decimal("0.000000"), comment="调用成本（美元）"
    )

    def __repr__(self) -> str:
        return f"<AiAuditLog user_id={self.user_id!r} model={self.model_name!r} status={self.response_status!r}>"


class PromptVersion(IDMixin, Base):
    """Prompt 版本管理表"""
    __tablename__ = "sa_prompt_versions"

    prompt_type: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="Prompt 类型: core/policy/task"
    )
    version: Mapped[int] = mapped_column(
        Integer, nullable=False, default=1, comment="版本号"
    )
    content: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="Prompt 内容"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, comment="是否为当前活跃版本"
    )
    model_filter: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="适用模型过滤条件（JSON）"
    )
    created_by: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True, comment="创建者"
    )

    def __repr__(self) -> str:
        return f"<PromptVersion type={self.prompt_type!r} version={self.version!r}>"


class FeatureFlag(IDMixin, Base):
    """功能开关表"""
    __tablename__ = "sa_feature_flags"

    flag_name: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, comment="功能名称（唯一）"
    )
    flag_type: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="开关类型: bool/percentage/variant"
    )
    value: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="开关值（JSON）"
    )
    description: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True, comment="功能描述"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, comment="是否启用"
    )
    target_users: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="目标用户白名单（JSON，可空表示所有用户）"
    )

    def __repr__(self) -> str:
        return f"<FeatureFlag name={self.flag_name!r} active={self.is_active}>"
