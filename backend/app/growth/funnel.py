"""漏斗汇总。收入预测用可配置的 ARPU，不用单笔金额。"""

from __future__ import annotations

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.growth.constants import FUNNEL_EVENTS
from app.growth.models import GrowthEvent


def summarize(session: Session, arpu_yuan: float) -> dict:
    counts = {name: 0 for name in FUNNEL_EVENTS}
    rows = (
        session.query(GrowthEvent.event_type, func.count(GrowthEvent.id))
        .group_by(GrowthEvent.event_type)
        .all()
    )
    for event_type, count in rows:
        if event_type in counts:
            counts[event_type] = int(count)
    attributed = (
        session.query(func.count(GrowthEvent.id))
        .filter(
            GrowthEvent.event_type == "signup",
            GrowthEvent.inviter_user_id != "",
        )
        .scalar()
    )
    paid = counts["subscription_paid"]
    return {
        "counts": counts,
        "attributed_signups": int(attributed or 0),
        "arpu_yuan": arpu_yuan,
        "projected_revenue_yuan": paid * arpu_yuan,
    }
