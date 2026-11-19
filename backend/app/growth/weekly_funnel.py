"""每周漏斗汇总（只读、只出聚合）。

周按上海时间（Asia/Shanghai，UTC+8，无夏令时）切：周日 00:00:00 到周六 23:59:59，
即左闭右开 ``[周日 00:00, 下周日 00:00)``。

字段口径（详见 docs/FUNNEL_WEEKLY_READONLY_2026-11-19.md）：

- ``new_signups``：产品库 ``users`` 表里非游客账号，``created_at`` 落在本周。已注销（行被删）的
  账号不再计入历史周。
- ``new_paid``：本周付款、且此前从没有付过款的用户数（按用户去重）。
- ``renewals``：本周付款的订单里，付款人此前已有付款记录的订单数。
- ``order_amount_cents``：本周付款的订单金额合计（分，人民币）。之后被退款的订单仍算在付款那一周。
- ``refund_amount_cents``：本周结算成功（``outcome='settled'``）的退款金额合计（分）。
  部分退款目前只记 ``deferred``、不结算，不计入。
- ``expirations``：会员到期人数——每位用户仍为 ``active`` 的国内会员里最晚的到期时间落在本周、
  且已经过去（当前周只算到此刻）。
- ``signups_by_source``：注册来源题（``growth_signup_source`` 表）的计数。表不存在时为 ``null``，
  并在 ``signups_by_source_note`` 里说明。

付款类只统计国内渠道：``currency='CNY'`` 且 ``platform IN ('alipay','wechat')``，
``status IN ('paid','refunded')`` 且 ``paid_at`` 不为空。

本模块只做 SELECT，不写任何表；输出里没有用户 id、订单号、手机号或任何用户级数据。
"""

from __future__ import annotations

from contextlib import contextmanager
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import func, inspect, text
from sqlalchemy.orm import Session

SHANGHAI = ZoneInfo("Asia/Shanghai")
WEEKLY_PATH = "/api/v1/admin/growth/funnel/weekly"
READONLY_TOKEN_ENV = "SHUNSHI_FUNNEL_READONLY_TOKEN"
MAX_WEEKS = 26
DOMESTIC_PLATFORMS = ("alipay", "wechat")
PAID_STATUSES = ("paid", "refunded")


class WeekError(ValueError):
    pass


def week_start_of(moment: datetime) -> datetime:
    """``moment`` 所在周（上海时间）的周日 00:00，带 +08:00 时区。"""
    local = moment.astimezone(SHANGHAI)
    # Python: Monday=0 … Sunday=6；离上一个周日的天数 = (weekday + 1) % 7
    sunday = local.date() - timedelta(days=(local.weekday() + 1) % 7)
    return datetime.combine(sunday, time(0, 0), tzinfo=SHANGHAI)


def parse_week_start(value: str) -> datetime:
    try:
        day = date.fromisoformat(value)
    except ValueError:
        raise WeekError("week_start 须为 YYYY-MM-DD") from None
    if day.weekday() != 6:
        raise WeekError("week_start 须为周日（上海时间）")
    return datetime.combine(day, time(0, 0), tzinfo=SHANGHAI)


def week_ranges(last_week_start: datetime, weeks: int) -> list[tuple[datetime, datetime]]:
    if weeks < 1 or weeks > MAX_WEEKS:
        raise WeekError(f"weeks 须在 1 到 {MAX_WEEKS} 之间")
    ranges = []
    for back in range(weeks - 1, -1, -1):
        start_day = last_week_start.date() - timedelta(days=7 * back)
        start = datetime.combine(start_day, time(0, 0), tzinfo=SHANGHAI)
        end = datetime.combine(start_day + timedelta(days=7), time(0, 0), tzinfo=SHANGHAI)
        ranges.append((start, end))
    return ranges


def _parse_ts(value) -> datetime | None:
    """记录库里的时间是 ISO 字符串；没有时区的按 UTC（写入方用的是 UTC）。"""
    if value in (None, ""):
        return None
    try:
        parsed = datetime.fromisoformat(str(value).strip().replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


@contextmanager
def open_records():
    """记录库（订单、退款、会员）的只读连接：query_only，短忙等。"""
    from app.database.db import record_store_read

    with record_store_read(timeout_seconds=2.0) as conn:
        yield conn


def _record_tables(conn) -> set[str]:
    return {
        row[0]
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
    }


def _paid_orders(conn, tables: set[str]) -> list[tuple[str, datetime, int]]:
    if "payment_orders" not in tables:
        return []
    placeholders_p = ",".join("?" for _ in DOMESTIC_PLATFORMS)
    placeholders_s = ",".join("?" for _ in PAID_STATUSES)
    rows = conn.execute(
        f"""SELECT user_id, paid_at, amount_cents FROM payment_orders
        WHERE currency='CNY' AND platform IN ({placeholders_p})
        AND status IN ({placeholders_s}) AND paid_at IS NOT NULL AND paid_at <> ''""",
        (*DOMESTIC_PLATFORMS, *PAID_STATUSES),
    ).fetchall()
    out = []
    for user_id, paid_at, amount in rows:
        moment = _parse_ts(paid_at)
        if moment is not None:
            out.append((str(user_id), moment, int(amount or 0)))
    out.sort(key=lambda item: item[1])
    return out


def _settled_refunds(conn, tables: set[str]) -> list[tuple[datetime, int]]:
    if "domestic_refund_events" not in tables:
        return []
    rows = conn.execute(
        "SELECT created_at, refund_cents FROM domestic_refund_events WHERE outcome='settled'"
    ).fetchall()
    out = []
    for created_at, cents in rows:
        moment = _parse_ts(created_at)
        if moment is not None:
            out.append((moment, int(cents or 0)))
    return out


def _membership_ends(conn, tables: set[str]) -> list[datetime]:
    """每位用户仍 active 的国内会员中最晚的到期时间。"""
    if "subscriptions" not in tables:
        return []
    placeholders = ",".join("?" for _ in DOMESTIC_PLATFORMS)
    rows = conn.execute(
        f"""SELECT user_id, expires_at FROM subscriptions
        WHERE status='active' AND platform IN ({placeholders})""",
        DOMESTIC_PLATFORMS,
    ).fetchall()
    latest: dict[str, datetime] = {}
    for user_id, expires_at in rows:
        moment = _parse_ts(expires_at)
        if moment is None:
            continue
        key = str(user_id)
        if key not in latest or moment > latest[key]:
            latest[key] = moment
    return list(latest.values())


def _signups(session: Session, start: datetime, end: datetime) -> int:
    from app.simple_models import User

    return int(
        session.query(func.count(User.id))
        .filter(
            User.is_guest.is_(False),
            User.created_at >= int(start.timestamp()),
            User.created_at < int(end.timestamp()),
        )
        .scalar()
        or 0
    )


def _source_order() -> list[str]:
    try:
        from app.growth.signup_source import SIGNUP_SOURCES  # 注册来源题（PR #153）合入后才有
    except ImportError:
        return []
    return [code for code, _ in SIGNUP_SOURCES]


def _signups_by_source(session: Session, start: datetime, end: datetime) -> dict | None:
    bind = session.get_bind()
    if not inspect(bind).has_table("growth_signup_source"):
        return None
    rows = session.execute(
        text(
            """SELECT s.source, COUNT(*) FROM growth_signup_source s
            JOIN growth_event e ON e.id = s.event_id
            WHERE e.event_type = 'signup' AND e.created_at >= :start AND e.created_at < :end
            GROUP BY s.source"""
        ),
        {"start": int(start.timestamp()), "end": int(end.timestamp())},
    ).all()
    counts = {code: 0 for code in _source_order()}
    for source, count in rows:
        counts[str(source)] = counts.get(str(source), 0) + int(count)
    signup_events = int(
        session.execute(
            text(
                """SELECT COUNT(*) FROM growth_event WHERE event_type = 'signup'
                AND created_at >= :start AND created_at < :end"""
            ),
            {"start": int(start.timestamp()), "end": int(end.timestamp())},
        ).scalar()
        or 0
    )
    counts["unanswered"] = max(signup_events - sum(counts.values()), 0)
    return counts


SOURCE_TABLE_MISSING_NOTE = (
    "注册来源表 growth_signup_source 不存在（注册来源题尚未上线或未合入），本项为空，不代表 0。"
)


def summarize_weeks(
    session: Session,
    records,
    ranges: list[tuple[datetime, datetime]],
    now: datetime | None = None,
) -> list[dict]:
    now = now or datetime.now(timezone.utc)
    tables = _record_tables(records)
    orders = _paid_orders(records, tables)
    refunds = _settled_refunds(records, tables)
    ends = _membership_ends(records, tables)

    first_paid: dict[str, datetime] = {}
    for user_id, moment, _ in orders:
        first_paid.setdefault(user_id, moment)

    weeks = []
    for start, end in ranges:
        week_orders = [o for o in orders if start <= o[1] < end]
        new_paid_users = {
            user_id for user_id, moment, _ in week_orders if first_paid[user_id] == moment
        }
        renewals = sum(1 for user_id, moment, _ in week_orders if first_paid[user_id] < moment)
        cutoff = min(end, now)
        by_source = _signups_by_source(session, start, end)
        week = {
            "week_start": start.isoformat(),
            "week_end": (end - timedelta(seconds=1)).isoformat(),
            "complete": now >= end,
            "new_signups": _signups(session, start, end),
            "new_paid": len(new_paid_users),
            "renewals": renewals,
            "order_amount_cents": sum(amount for _, _, amount in week_orders),
            "refund_amount_cents": sum(c for moment, c in refunds if start <= moment < end),
            "expirations": sum(1 for moment in ends if start <= moment < cutoff),
            "signups_by_source": by_source,
        }
        if by_source is None:
            week["signups_by_source_note"] = SOURCE_TABLE_MISSING_NOTE
        weeks.append(week)
    return weeks


def build_report(
    session: Session,
    *,
    week_start: str | None = None,
    weeks: int = 1,
    now: datetime | None = None,
) -> dict:
    now = now or datetime.now(timezone.utc)
    current = week_start_of(now)
    last = parse_week_start(week_start) if week_start else current
    if last > current:
        raise WeekError("week_start 不能晚于本周（上海时间）")
    ranges = week_ranges(last, weeks)
    with open_records() as records:
        data = summarize_weeks(session, records, ranges, now=now)
    return {
        "timezone": "Asia/Shanghai",
        "week_definition": "周日 00:00:00 至周六 23:59:59（上海时间）",
        "currency": "CNY",
        "money_unit": "分",
        "generated_at": now.astimezone(SHANGHAI).isoformat(timespec="seconds"),
        "weeks": data,
    }


def readonly_token_ok(token: str) -> bool:
    """只读漏斗令牌。环境变量没设就关闭；比较哈希摘要，常量时间、不受长度影响。"""
    import hashlib
    import hmac
    import os

    expected = os.environ.get(READONLY_TOKEN_ENV) or ""
    if not token or not expected:
        return False
    return hmac.compare_digest(
        hashlib.sha256(token.encode()).digest(),
        hashlib.sha256(expected.encode()).digest(),
    )
