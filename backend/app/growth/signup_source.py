"""注册来源题「从哪知道我们」：可跳过的单选，默认关闭。

只存一个枚举代码，挂在这位用户的 ``signup`` 增长事件上（``growth_signup_source``
表以 ``event_id`` 关联 ``growth_event``，表里不放用户 id、手机号、昵称）。

- 开关：环境变量 ``SHUNSHI_GROWTH_SIGNUP_SOURCE_ENABLED``（Settings 字段
  ``growth_signup_source_enabled``），默认 ``False``。关着时题目不下发、提交的值一律丢弃。
- 服务端只认 ``SIGNUP_SOURCES`` 里的代码，未知值、自由文本直接丢弃，不报错也不落库。
- 任何接口响应、日志、导出都不把来源和身份信息放在一起；本模块不写日志。
"""

from __future__ import annotations

import time

from sqlalchemy.orm import Session

from app.growth.models import GrowthEvent, GrowthSignupSource

# 顺序即客户端展示顺序。代码一经上线不要改名，只能追加。
SIGNUP_SOURCES: tuple[tuple[str, str], ...] = (
    ("xiaohongshu", "小红书"),
    ("douyin", "抖音"),
    ("shipinhao", "视频号"),
    ("gongzhonghao", "公众号"),
    ("zhihu", "知乎"),
    ("bilibili", "哔哩哔哩"),
    ("search", "搜索"),
    ("friend", "朋友推荐"),
    ("other", "其他"),
)
SIGNUP_SOURCE_CODES = frozenset(code for code, _ in SIGNUP_SOURCES)
FLAG_ENV = "SHUNSHI_GROWTH_SIGNUP_SOURCE_ENABLED"
# 只接受注册后这么久之内的回答，避免老用户换设备后被算成一次新注册。
ANSWER_WINDOW_SECONDS = 72 * 3600


def enabled(settings) -> bool:
    return bool(getattr(settings, "growth_signup_source_enabled", False))


def normalize(value) -> str:
    """返回合法代码；其余（含空、自由文本、大小写不符）一律返回空串。"""
    if not isinstance(value, str):
        return ""
    return value if value in SIGNUP_SOURCE_CODES else ""


def public_options(settings) -> dict:
    if not enabled(settings):
        return {"enabled": False, "options": []}
    return {
        "enabled": True,
        "question": "从哪知道我们",
        "skippable": True,
        "options": [{"code": code, "label": label} for code, label in SIGNUP_SOURCES],
    }


def attach_to_event(session: Session, settings, event: GrowthEvent, value) -> bool:
    """给一条刚记下的 signup 事件挂上来源。成功返回 True。"""
    if not enabled(settings) or event.event_type != "signup":
        return False
    code = normalize(value)
    if not code or session.get(GrowthSignupSource, event.id) is not None:
        return False
    session.add(GrowthSignupSource(event_id=event.id, source=code))
    session.flush()
    return True


def record_for_user(session: Session, settings, user_id: str, value) -> bool:
    """注册后页面上的作答：挂到本人的 signup 事件上；没有就补记一条 signup 事件。

    只记一次。游客、找不到账号、注册超过 72 小时的账号都不记。
    """
    if not enabled(settings) or not user_id:
        return False
    code = normalize(value)
    if not code:
        return False
    from app.simple_models import User

    user = session.get(User, user_id)
    if user is None or bool(user.is_guest):
        return False
    created_at = int(user.created_at or 0)
    if created_at <= 0 or time.time() - created_at > ANSWER_WINDOW_SECONDS:
        return False
    events = (
        session.query(GrowthEvent)
        .filter(GrowthEvent.event_type == "signup", GrowthEvent.user_id == user_id)
        .order_by(GrowthEvent.created_at.asc())
        .all()
    )
    for event in events:
        if session.get(GrowthSignupSource, event.id) is not None:
            return False
    if events:
        event = events[0]
    else:
        event = GrowthEvent(event_type="signup", user_id=user_id)
        session.add(event)
        session.flush()
    session.add(GrowthSignupSource(event_id=event.id, source=code))
    session.flush()
    return True


def count_by_source(session: Session) -> dict:
    """只出聚合计数，不出任何用户级数据。未作答的计入 ``unanswered``。"""
    from sqlalchemy import func

    counts = {code: 0 for code in SIGNUP_SOURCE_CODES}
    rows = (
        session.query(GrowthSignupSource.source, func.count(GrowthSignupSource.event_id))
        .group_by(GrowthSignupSource.source)
        .all()
    )
    answered = 0
    for source, count in rows:
        if source in counts:
            counts[source] = int(count)
            answered += int(count)
    total = (
        session.query(func.count(GrowthEvent.id))
        .filter(GrowthEvent.event_type == "signup")
        .scalar()
    )
    ordered = {code: counts[code] for code, _ in SIGNUP_SOURCES}
    ordered["unanswered"] = max(int(total or 0) - answered, 0)
    return ordered
