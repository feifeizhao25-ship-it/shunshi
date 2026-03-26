"""
顺时 ShunShi - 节气相关模型
包含 2 张表: SolarTerm, SolarTermContent
"""
import enum
from datetime import date
from typing import Optional

from sqlalchemy import String, Integer, Text, Date, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, IDMixin


# ==================== 枚举定义 ====================

class SolarTermSeason(str, enum.Enum):
    """节气所属季节"""
    spring = "spring"
    summer = "summer"
    autumn = "autumn"
    winter = "winter"


class SolarTermStatus(str, enum.Enum):
    """节气状态"""
    active = "active"
    inactive = "inactive"


# ==================== 模型定义 ====================

class SolarTerm(IDMixin, Base):
    """二十四节气表"""
    __tablename__ = "sa_solar_terms"

    name: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="节气名称（如 春分）"
    )
    name_en: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, comment="英文名称"
    )
    date: Mapped[Optional[date]] = mapped_column(
        Date, nullable=True, comment="该年日期"
    )
    month: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="月份"
    )
    day: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="日期"
    )
    season: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="所属季节: spring/summer/autumn/winter"
    )
    description: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="节气描述"
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
    acupoint_advice: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="穴位建议（JSON）"
    )
    emotion_advice: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="情绪调理建议（JSON）"
    )
    seven_day_plan: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="七日养生计划（JSON）"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default=SolarTermStatus.active.value,
        comment="状态: active/inactive"
    )

    # ---- 关系 ----
    content_relations: Mapped[list["SolarTermContent"]] = relationship(
        "SolarTermContent", back_populates="solar_term", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<SolarTerm name={self.name!r} season={self.season!r}>"


class SolarTermContent(IDMixin, Base):
    """节气-内容 关联表"""
    __tablename__ = "sa_solar_term_contents"

    solar_term_id: Mapped[str] = mapped_column(
        ForeignKey("sa_solar_terms.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联节气 ID"
    )
    content_id: Mapped[str] = mapped_column(
        ForeignKey("sa_content_items.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联内容 ID"
    )

    # ---- 关系 ----
    solar_term: Mapped["SolarTerm"] = relationship(
        "SolarTerm", back_populates="content_relations"
    )

    def __repr__(self) -> str:
        return f"<SolarTermContent solar_term_id={self.solar_term_id!r} content_id={self.content_id!r}>"
