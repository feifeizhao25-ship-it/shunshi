"""来源保鲜。过期降权，超过两倍保鲜期就归档并不再检索。"""

from __future__ import annotations

from datetime import date, datetime, timedelta

FRESHNESS_DAYS = {
    "platform_rules": 30,
    "laws": 180,
    "papers": 90,
    "performance": 28,
}


def parse_day(value: str) -> date:
    return datetime.strptime(value[:10], "%Y-%m-%d").date()


def expires_on(published_at: str, tier: str) -> str:
    days = FRESHNESS_DAYS[tier]
    return (parse_day(published_at) + timedelta(days=days)).isoformat()


def weight_and_archive(published_at: str, tier: str, today: date) -> tuple[float, bool]:
    """返回 (检索权重, 是否应归档)。"""
    days = FRESHNESS_DAYS[tier]
    age = (today - parse_day(published_at)).days
    if age > days * 2:
        return 0.0, True
    if age > days:
        return 0.5, False
    return 1.0, False
