"""
顺时 ShunShi - 体质相关模型
包含 3 张表: Constitution, ConstitutionQuestion, ConstitutionResult
"""
from datetime import datetime
from typing import Optional

from sqlalchemy import String, Integer, Boolean, Text, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, IDMixin


# ==================== 模型定义 ====================

class Constitution(IDMixin, Base):
    """体质定义表（九种体质）"""
    __tablename__ = "sa_constitutions"

    name: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="体质名称（如 气虚质）"
    )
    description: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="体质描述"
    )
    characteristics: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="典型特征（JSON）"
    )
    diet_advice: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="饮食建议（JSON）"
    )
    tea_advice: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="茶饮建议（JSON）"
    )
    exercise_advice: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="运动建议（JSON）"
    )
    avoid_list: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="禁忌列表（JSON）"
    )
    season_advice: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="四季建议（JSON）"
    )

    def __repr__(self) -> str:
        return f"<Constitution name={self.name!r}>"


class ConstitutionQuestion(IDMixin, Base):
    """体质评估问卷题目表"""
    __tablename__ = "sa_constitution_questions"

    question_text: Mapped[str] = mapped_column(
        Text, nullable=False, comment="题目文本"
    )
    category: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="判断哪种体质"
    )
    options: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="选项列表 [{text, score_map}]"
    )
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="排序权重"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, comment="是否启用"
    )

    def __repr__(self) -> str:
        return f"<ConstitutionQuestion category={self.category!r}>"


class ConstitutionResult(IDMixin, Base):
    """用户体质评估结果表"""
    __tablename__ = "sa_constitution_results"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    primary_type: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="主要体质（如 气虚质）"
    )
    secondary_types: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="倾向体质列表（JSON 数组）"
    )
    scores: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="各体质分数（JSON）"
    )
    advice: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="AI 生成的建议（JSON）"
    )
    version: Mapped[int] = mapped_column(
        Integer, nullable=False, default=1, comment="问卷版本号"
    )
    completed_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="完成时间"
    )

    def __repr__(self) -> str:
        return f"<ConstitutionResult user_id={self.user_id!r} primary={self.primary_type!r}>"
