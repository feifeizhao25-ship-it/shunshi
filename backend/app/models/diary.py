"""
顺时 ShunShi - 日记与报告相关模型
包含 3 张表: DiaryEntry, WeeklyReport, MonthlyReport
"""
from datetime import date
from typing import Optional

from sqlalchemy import String, Integer, Float, Text, Date, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base, IDMixin


# ==================== 模型定义 ====================

class DiaryEntry(IDMixin, Base):
    """健康日记表"""
    __tablename__ = "sa_diary_entries"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    entry_date: Mapped[date] = mapped_column(
        Date, nullable=False, index=True, comment="日记日期"
    )
    mood: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="心情评分 (1-5)"
    )
    sleep_quality: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="睡眠质量 (1-5)"
    )
    sleep_hours: Mapped[Optional[float]] = mapped_column(
        Float, nullable=True, comment="睡眠时长（小时）"
    )
    diet: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="饮食记录"
    )
    water_glasses: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="饮水杯数"
    )
    exercise: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="运动记录"
    )
    exercise_minutes: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="运动时长（分钟）"
    )
    notes: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="备注"
    )
    ai_comment: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="AI 评语（可空）"
    )

    def __repr__(self) -> str:
        return f"<DiaryEntry user_id={self.user_id!r} date={self.entry_date!r}>"


class WeeklyReport(IDMixin, Base):
    """周报表"""
    __tablename__ = "sa_weekly_reports"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    week_start: Mapped[date] = mapped_column(
        Date, nullable=False, comment="周开始日期"
    )
    week_end: Mapped[date] = mapped_column(
        Date, nullable=False, comment="周结束日期"
    )
    summary: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="周总结"
    )
    insights: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="洞察分析（JSON）"
    )
    suggestions: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="建议列表（JSON）"
    )
    mood_trend: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="心情趋势（JSON）"
    )
    sleep_trend: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="睡眠趋势（JSON）"
    )
    generated_by: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True, comment="生成模型名称"
    )

    def __repr__(self) -> str:
        return f"<WeeklyReport user_id={self.user_id!r} week={self.week_start!r}>"


class MonthlyReport(IDMixin, Base):
    """月报表"""
    __tablename__ = "sa_monthly_reports"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("sa_users.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联用户 ID"
    )
    month: Mapped[str] = mapped_column(
        String(7), nullable=False, comment="月份（如 2026-03）"
    )
    summary: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="月总结"
    )
    insights: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="洞察分析（JSON）"
    )
    suggestions: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="建议列表（JSON）"
    )
    mood_trend: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="心情趋势（JSON）"
    )
    sleep_trend: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="睡眠趋势（JSON）"
    )
    generated_by: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True, comment="生成模型名称"
    )

    def __repr__(self) -> str:
        return f"<MonthlyReport user_id={self.user_id!r} month={self.month!r}>"
