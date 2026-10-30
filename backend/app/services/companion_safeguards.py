"""AI 陪伴（app/router/ai_companion.py）按《人工智能拟人化互动服务管理暂行办法》保守处理。

由环境变量 SHUNSHI_COMPANION_SAFEGUARDS 控制，默认开启（"0" 才关闭）。开启时：
1. 每个响应带显式 AI 标识与「你在和人工智能对话，不是真人」；
2. 连续使用满 2 小时给出休息提醒（相邻两次交互间隔超过 30 分钟视为新会话）；
3. 亲密度只作内部统计，对外封顶 2 级，问候不使用更亲昵的话术（不诱导依赖、不过度迎合）；
4. 用户备注先过安全守卫：命中危机 → 直接返回危机资源，不再给「陪伴式」回应；
5. 用户可删除自己的陪伴数据（见 ai_companion.delete_my_data）。

注意：该路由目前没有挂到 create_app，且接口用请求体里的 user_id、没有鉴权，也没有年龄核验。
**在接入鉴权与 age_policy 之前不得挂载**（tests/test_companion_safeguards.py 里有断言）。
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta

from ..aigc import ai_disclosure

FLAG_ENV = "SHUNSHI_COMPANION_SAFEGUARDS"
SESSION_GAP = timedelta(minutes=30)
REMIND_AFTER = timedelta(hours=2)
REMINDER_TEXT = "你已经连续使用两个多小时了，起来活动一下、喝杯温水，也可以和身边的家人朋友聊聊。"
INTIMACY_PUBLIC_CAP = 2


def enabled(env=None) -> bool:
    env = os.environ if env is None else env
    return str(env.get(FLAG_ENV, "1")).strip() not in ("0", "false", "off", "no")


class UseTracker:
    """内存里的连续使用计时。重启即清零，只用于提醒，不做任何画像。"""

    def __init__(self):
        self._sessions: dict[str, tuple[datetime, datetime, bool]] = {}  # user -> (start, last, reminded)

    def touch(self, user_id: str, now: datetime | None = None) -> str | None:
        now = now or datetime.now()
        start, last, reminded = self._sessions.get(user_id, (now, now, False))
        if now - last > SESSION_GAP:
            start, reminded = now, False
        text = None
        if now - start >= REMIND_AFTER and not reminded:
            text, reminded = REMINDER_TEXT, True
        self._sessions[user_id] = (start, now, reminded)
        return text

    def forget(self, user_id: str) -> None:
        self._sessions.pop(user_id, None)


def public_intimacy(level: int) -> int:
    return min(int(level), INTIMACY_PUBLIC_CAP)


def screen_text(text: str | None, user_id: str):
    """返回安全守卫结果；没有文本时返回 None。"""
    if not text:
        return None
    from ..safety.guard import safety_guard

    return safety_guard.check_input(text, {"user_id": user_id})


def decorate(data: dict, user_id: str, tracker: UseTracker, now: datetime | None = None) -> dict:
    """给响应的 data 加上标识 / 提醒 / 封顶亲密度。关闭开关时原样返回。"""
    if not enabled():
        return data
    out = {**data, **ai_disclosure()}
    if "intimacy_level" in out:
        out["intimacy_level"] = public_intimacy(out["intimacy_level"])
    reminder = tracker.touch(user_id, now)
    if reminder:
        out["usage_reminder"] = reminder
    return out
