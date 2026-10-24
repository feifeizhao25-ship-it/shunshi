"""连续使用满 2 小时的温和提醒（《人工智能拟人化互动服务管理暂行办法》）。

口径：同一用户相邻两条消息间隔不超过 SESSION_GAP_SECONDS（30 分钟）算同一段使用；
这一段从第一条到「现在」满 2 小时提醒一次，之后每再满 2 小时再提醒一次。
不新增表：用 messages 表里该用户自己的消息时间推算，调用发生在本轮消息写入之前；
「上次提醒的时间」记在 user_settings 里，避免同一段使用里每条消息都提醒。
用户清空对话记录后计时从头开始（消息没了，就无从推算）——这是有意的取舍，见最终报告。
"""

from __future__ import annotations

import json
import time
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..simple_models import Message, UserSetting

SESSION_GAP_SECONDS = 30 * 60
REMINDER_INTERVAL_SECONDS = 2 * 60 * 60
# 回看窗口：最多看最近 24 小时的消息，足够覆盖「连续 2 小时」的判断，也给单次查询设上限。
LOOKBACK_SECONDS = 24 * 60 * 60
MAX_ROWS = 2000

REMINDER_TEXT = (
    "你已经连续使用超过 2 小时了。起来走动走动、看看远处、喝口温水，让身体和眼睛歇一会儿吧。"
)


LAST_REMINDER_KEY = "usage:last-reminder"


def continuous_session(session: Session, user_id: str, now: float | None = None) -> tuple[float, float] | None:
    """当前这一段连续使用的 (开始时间, 最后一条消息时间)；没有进行中的一段则返回 None。"""
    now = time.time() if now is None else now
    rows = session.execute(
        select(Message.created_at)
        .where(
            Message.user_id == user_id,
            Message.role == "user",
            Message.created_at >= now - LOOKBACK_SECONDS,
        )
        .order_by(Message.created_at.desc())
        .limit(MAX_ROWS)
    ).scalars().all()
    if not rows or now - rows[0] > SESSION_GAP_SECONDS:
        return None
    start = rows[0]
    for ts in rows[1:]:
        if start - ts > SESSION_GAP_SECONDS:
            break
        start = ts
    return start, rows[0]


def _last_reminder_at(session: Session, user_id: str) -> float:
    row = session.get(UserSetting, {"user_id": user_id, "key": LAST_REMINDER_KEY})
    if not row:
        return 0.0
    try:
        return float(json.loads(row.value).get("at", 0))
    except (ValueError, TypeError, AttributeError):
        return 0.0


def usage_reminder(session: Session, user_id: str, now: float | None = None) -> dict[str, Any] | None:
    """本轮回答是否要带「连续使用」提醒；不需要时返回 None。需要时同时记下提醒时间。"""
    now = time.time() if now is None else now
    current = continuous_session(session, user_id, now)
    if current is None:
        return None
    start, _ = current
    elapsed = now - start
    if elapsed < REMINDER_INTERVAL_SECONDS:
        return None
    last = _last_reminder_at(session, user_id)
    # 同一段里已经提醒过，且距上次不满 2 小时：不重复。
    if last >= start and now - last < REMINDER_INTERVAL_SECONDS:
        return None
    session.merge(
        UserSetting(user_id=user_id, key=LAST_REMINDER_KEY, value=json.dumps({"at": int(now)}))
    )
    return {"type": "continuous_use", "continuous_minutes": int(elapsed // 60), "text": REMINDER_TEXT}
