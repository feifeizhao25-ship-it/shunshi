"""What the user's plan includes and how much of it they used today - for the plan & usage page.

Every number comes from the entitlements registry (limits) or a real counter (chat messages in Redis, reflections in
the database). A counter that cannot be read is reported as ``null`` with ``used_known: false``, never as 0 or a guess.
Audio minutes have no server-side counter, so they are reported as limit only.
"""
from __future__ import annotations

import time
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..entitlements import get_registry
from ..simple_models import Reflection
from . import chat_quota
from .membership_status import membership_status

SH = ZoneInfo("Asia/Shanghai")
PLAN_NAMES = {
    "free": ("免费版", "Free"), "yangxin": ("内容订阅", "Content plan"), "yiyang": ("会员", "Member"), "jiahe": ("家和版", "Family"),
}


def _reset_at(now: datetime) -> datetime:
    local = now.astimezone(SH)
    return datetime.combine(local.date() + timedelta(days=1), datetime.min.time(), tzinfo=SH)


def _item(key: str, limit, used, unit: str) -> dict:
    unlimited = limit == -1
    known = used is not None
    return {
        "key": key, "limit": None if unlimited else limit, "unlimited": unlimited, "used": used, "used_known": known,
        "remaining": None if (unlimited or not known) else max(limit - used, 0), "unit": unit,
    }


async def build(session: Session, redis_url: str, user_id: str, lang: str = "zh", now: datetime | None = None) -> dict:
    now = now or datetime.now(timezone.utc)
    status = membership_status(session, user_id)
    tier = status["tier"]
    quotas = get_registry()["tiers"][tier]["quotas"]
    start = int(now.astimezone(SH).replace(hour=0, minute=0, second=0, microsecond=0).timestamp())
    reflections = session.execute(
        select(func.count()).select_from(Reflection).where(Reflection.user_id == user_id, Reflection.created_at >= start)
    ).scalar_one()
    chat_used = await chat_quota.used_today(redis_url, user_id)
    reset = _reset_at(now)
    plan = status["plan"]
    return {
        "plan": plan,
        "plan_name": PLAN_NAMES[plan][1 if lang == "en" else 0],
        "tier": tier,
        "active": status["active"],
        "expires_at": status["expires_at"],
        "resets_at": reset.astimezone(timezone.utc).isoformat(),
        "reset_note": ("Daily limits reset at 00:00 Beijing time (16:00 UTC)." if lang == "en" else "每日额度于北京时间零点重置。"),
        "items": [
            _item("chat_messages", quotas["ai_daily_messages"], chat_used, "messages"),
            _item("reflections", quotas["reflections_per_day"], int(reflections), "entries"),
            _item("audio_minutes", quotas["audio_daily_minutes"], None, "minutes"),
        ],
        "generated_at": int(now.timestamp()),
    }
