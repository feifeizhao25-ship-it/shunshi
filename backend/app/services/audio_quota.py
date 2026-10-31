"""Listening minutes per day, for the membership quota ``audio_daily_minutes``.

The apps report how long audio actually played (``listened_seconds`` on the progress report). Seconds are added to one
Redis counter per user per Beijing day (same day boundary as the chat quota) that expires at the next Beijing midnight.
A counter that cannot be read is ``None`` - never 0 or a guess. The count is client-reported, so it is a soft limit:
each report is capped, and the daily total is clamped at the limit so it can never read above it.
"""
from __future__ import annotations

import hashlib
import logging
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

import redis.asyncio as redis

from ..entitlements import get_registry

logger = logging.getLogger(__name__)
SH = ZoneInfo("Asia/Shanghai")
MAX_REPORT_SECONDS = 3600  # one report covers at most an hour of listening

# add up to the limit; returns the new total (clamped at the limit when the limit is >= 0)
ADD = """
local used = tonumber(redis.call('GET', KEYS[1]) or '0')
local add = tonumber(ARGV[1])
local limit = tonumber(ARGV[2])
local total = used + add
if limit >= 0 and total > limit then total = limit end
redis.call('SET', KEYS[1], total, 'EXAT', ARGV[3])
return total
"""


def key_for(user_id: str, now: datetime | None = None) -> tuple[str, int]:
    now = (now or datetime.now(SH)).astimezone(SH)
    expires = int(datetime.combine(now.date() + timedelta(days=1), datetime.min.time(), tzinfo=SH).timestamp())
    identity = hashlib.sha256(user_id.encode()).hexdigest()
    return f"shunshi:audio:{{{now.date()}:{identity}}}", expires


def limit_minutes(tier: str) -> int:
    return get_registry()["tiers"][tier]["quotas"]["audio_daily_minutes"]


async def used_seconds(redis_url: str, user_id: str, now: datetime | None = None) -> int | None:
    if not redis_url:
        return None
    key, _ = key_for(user_id, now)
    try:
        async with redis.from_url(redis_url, socket_timeout=3, socket_connect_timeout=3) as client:
            value = await client.get(key)
    except Exception as exc:  # noqa: BLE001
        logger.error("Audio counter unavailable (%s)", type(exc).__name__)
        return None
    return int(value or 0)


async def add_listened(redis_url: str, user_id: str, tier: str, seconds: int, now: datetime | None = None) -> dict:
    """Add listening time. Never raises: a counter outage must not break playback or progress saving."""
    limit = limit_minutes(tier)
    seconds = max(0, min(int(seconds), MAX_REPORT_SECONDS))
    out = {"counted": False, "listened_today_seconds": None, "limit_minutes": None if limit == -1 else limit, "limit_reached": False}
    if not redis_url:
        return out
    key, expires = key_for(user_id, now)
    try:
        async with redis.from_url(redis_url, socket_timeout=3, socket_connect_timeout=3) as client:
            total = int(await client.eval(ADD, 1, key, seconds, limit * 60 if limit >= 0 else -1, expires))
    except Exception as exc:  # noqa: BLE001
        logger.error("Audio counter unavailable (%s)", type(exc).__name__)
        return out
    out.update(counted=True, listened_today_seconds=total, limit_reached=(limit >= 0 and total >= limit * 60))
    return out
