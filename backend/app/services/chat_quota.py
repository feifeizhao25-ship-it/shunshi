"""Atomic CN quota reservations; Redis failure never authorizes a model call."""
import hashlib
import logging
import uuid
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

import redis.asyncio as redis
from fastapi import HTTPException

from app.entitlements import get_registry

logger = logging.getLogger(__name__)
RESERVE = """
local used = tonumber(redis.call('GET', KEYS[1]) or '0')
local limit = tonumber(ARGV[1])
if limit >= 0 and used >= limit then return 0 end
redis.call('INCR', KEYS[1])
redis.call('EXPIREAT', KEYS[1], ARGV[2])
redis.call('SET', KEYS[2], '1', 'EXAT', ARGV[2])
return 1
"""
REFUND = """
if redis.call('DEL', KEYS[2]) == 1 then
  local used = tonumber(redis.call('GET', KEYS[1]) or '0')
  if used > 0 then redis.call('DECR', KEYS[1]) end
end
return 1
"""


def keys_for(user_id: str, now: datetime | None = None):
    now = (now or datetime.now(ZoneInfo('Asia/Shanghai'))).astimezone(ZoneInfo('Asia/Shanghai'))
    tomorrow = now.date() + timedelta(days=1)
    expires = int(datetime.combine(tomorrow, datetime.min.time(), tzinfo=ZoneInfo('Asia/Shanghai')).timestamp())
    identity = hashlib.sha256(user_id.encode()).hexdigest()
    # Same hash slot for Redis Cluster's two-key scripts.
    counter = f"shunshi:cn:chat:{{{now.date()}:{identity}}}"
    return counter, f"{counter}:{uuid.uuid4().hex}", expires


async def reserve(redis_url: str, user_id: str, tier: str):
    if not redis_url:
        raise HTTPException(503, detail="对话额度服务暂不可用，请稍后重试")
    limit = get_registry()['tiers'][tier]['quotas']['ai_daily_messages']
    if isinstance(limit, bool) or not isinstance(limit, int) or limit < -1:
        raise HTTPException(503, detail="对话额度配置异常，请稍后重试")
    counter, token, expires = keys_for(user_id)
    try:
        async with redis.from_url(redis_url, socket_timeout=3, socket_connect_timeout=3) as client:
            accepted = await client.eval(RESERVE, 2, counter, token, limit, expires)
    except Exception as exc:
        logger.error('Quota reservation unavailable (%s)', type(exc).__name__)
        raise HTTPException(503, detail="对话额度服务暂不可用，请稍后重试") from None
    if accepted != 1:
        raise HTTPException(429, detail="今日对话次数已达上限，将于北京时间零点重置")
    return counter, token


async def refund(redis_url: str, reservation):
    try:
        async with redis.from_url(redis_url, socket_timeout=3, socket_connect_timeout=3) as client:
            await client.eval(REFUND, 2, *reservation)
    except Exception as exc:
        # Never turn a failed provider call into success because refund failed.
        logger.error('Quota refund requires reconciliation (%s)', type(exc).__name__)
