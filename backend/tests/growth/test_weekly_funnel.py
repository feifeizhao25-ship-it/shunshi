"""每周漏斗只读汇总：上海时间周边界、各字段口径、只读令牌的范围、不出用户级数据。"""

import sqlite3
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import text

from app.growth import weekly_funnel as wf
from app.simple_models import User

SH = wf.SHANGHAI
RO_TOKEN = "readonly-funnel-token-for-tests"
ADMIN_OPS_TOKEN = "ops-hub-token-for-tests"

# 2026-11-01（周日）开始的一周记作 A，2026-11-08（周日）开始的一周记作 B。
WEEK_A = datetime(2026, 11, 1, tzinfo=SH)
WEEK_B = datetime(2026, 11, 8, tzinfo=SH)
SAT_LAST_SECOND_A = datetime(2026, 11, 7, 23, 59, 59, tzinfo=SH)
SUN_FIRST_SECOND_B = datetime(2026, 11, 8, 0, 0, 0, tzinfo=SH)
NOW = datetime(2026, 11, 11, 12, 0, tzinfo=SH)  # B 周的周三

RECORD_SCHEMA = """
CREATE TABLE payment_orders (
    id TEXT PRIMARY KEY, order_no TEXT NOT NULL UNIQUE, user_id TEXT NOT NULL,
    product_id TEXT NOT NULL, tier TEXT NOT NULL, platform TEXT NOT NULL,
    amount_cents INTEGER NOT NULL, currency TEXT NOT NULL DEFAULT 'CNY',
    status TEXT NOT NULL DEFAULT 'pending', created_at TEXT NOT NULL, expires_at TEXT NOT NULL,
    transaction_id TEXT, payment_method TEXT, paid_at TEXT);
CREATE TABLE subscriptions (
    id TEXT PRIMARY KEY, user_id TEXT NOT NULL, plan TEXT NOT NULL, status TEXT DEFAULT 'active',
    started_at TEXT, expires_at TEXT, auto_renew INTEGER DEFAULT 1, platform TEXT, subscribed_at TEXT);
CREATE TABLE domestic_refund_events (
    provider TEXT NOT NULL, event_key TEXT NOT NULL, order_no TEXT NOT NULL, trade_no TEXT NOT NULL,
    user_id TEXT NOT NULL, refund_cents INTEGER NOT NULL, outcome TEXT NOT NULL,
    created_at TEXT NOT NULL, PRIMARY KEY (provider, event_key));
"""


def _utc(moment: datetime) -> str:
    # 写入方（payment_activation / refund_settlement）存的是 UTC isoformat。
    return moment.astimezone(timezone.utc).isoformat()


def _order(db, n, user, paid_at, amount=39900, status="paid", platform="alipay", currency="CNY"):
    db.execute(
        """INSERT INTO payment_orders (id,order_no,user_id,product_id,tier,platform,amount_cents,
        currency,status,created_at,expires_at,transaction_id,payment_method,paid_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
        (f"id{n}", f"ORDER{n}", user, "content_yearly", "yearly", platform, amount, currency,
         status, _utc(WEEK_A - timedelta(days=30)), _utc(WEEK_A + timedelta(days=60)),
         f"trade{n}" if paid_at else None, platform if paid_at else None,
         _utc(paid_at) if paid_at else None),
    )


def _sub(db, n, user, expires_at, status="active", platform="alipay"):
    db.execute(
        "INSERT INTO subscriptions (id,user_id,plan,status,expires_at,platform) VALUES (?,?,?,?,?,?)",
        (f"sub{n}", user, "yearly", status, _utc(expires_at), platform),
    )


def _refund(db, n, cents, at, outcome="settled"):
    db.execute(
        """INSERT INTO domestic_refund_events (provider,event_key,order_no,trade_no,user_id,
        refund_cents,outcome,created_at) VALUES ('alipay',?,?,?,?,?,?,?)""",
        (f"k{n}", f"ORDER{n}", f"trade{n}", "u-x", cents, outcome, _utc(at)),
    )


@pytest.fixture()
def records(tmp_path):
    path = tmp_path / "records.db"
    db = sqlite3.connect(path)
    db.executescript(RECORD_SCHEMA)
    # 订单：u1 在 A 首付、B 续费；u2 在 B 首付后全额退款；其余不该计入。
    _order(db, 1, "u1", SAT_LAST_SECOND_A)
    _order(db, 2, "u1", SUN_FIRST_SECOND_B)
    _order(db, 3, "u2", SUN_FIRST_SECOND_B + timedelta(hours=1), status="refunded")
    _order(db, 4, "u3", None, status="pending")
    _order(db, 5, "u4", SUN_FIRST_SECOND_B, platform="stripe")
    _order(db, 6, "u5", SUN_FIRST_SECOND_B, currency="USD")
    _order(db, 7, "u6", SUN_FIRST_SECOND_B, status="cancelled")
    _order(db, 8, "u7", SUN_FIRST_SECOND_B, platform="wechat", amount=1990)
    # 退款：只计 settled；A 周最后一秒那笔在 A，B 周第一秒那笔在 B。
    _refund(db, 3, 39900, SUN_FIRST_SECOND_B)
    _refund(db, 9, 1000, SAT_LAST_SECOND_A)
    _refund(db, 10, 500, SUN_FIRST_SECOND_B, outcome="deferred")
    _refund(db, 11, 700, SUN_FIRST_SECOND_B, outcome="rejected")
    # 会员到期：看每人 active 国内会员里最晚的那条。
    _sub(db, 1, "u1", SAT_LAST_SECOND_A)  # 旧的一条，u1 已续费，不算到期
    _sub(db, 2, "u1", WEEK_B + timedelta(days=400))
    _sub(db, 3, "e1", SAT_LAST_SECOND_A)  # A 周到期
    _sub(db, 4, "e2", SUN_FIRST_SECOND_B)  # B 周到期（已过）
    _sub(db, 5, "e3", NOW + timedelta(days=1))  # B 周还没到，不算
    _sub(db, 6, "e4", SUN_FIRST_SECOND_B, status="refunded")
    _sub(db, 7, "e5", SUN_FIRST_SECOND_B, platform="apple")
    db.commit()
    db.close()
    return path


@contextmanager
def _open(path):
    conn = sqlite3.connect(path)
    conn.execute("PRAGMA query_only=ON")
    try:
        yield conn
    finally:
        conn.close()


def _add_users(session):
    session.add_all([
        User(id="s-a", phone="13800000001", created_at=int(SAT_LAST_SECOND_A.timestamp())),
        User(id="s-b", phone="13800000002", created_at=int(SUN_FIRST_SECOND_B.timestamp())),
        User(id="s-b2", phone="13800000003", created_at=int((NOW - timedelta(hours=1)).timestamp())),
        User(id="guest-b", is_guest=True, created_at=int(SUN_FIRST_SECOND_B.timestamp())),
        User(id="s-old", phone="13800000004", created_at=int((WEEK_A - timedelta(seconds=1)).timestamp())),
    ])
    session.commit()


def _two_weeks(growth_session, records):
    with _open(records) as conn:
        return wf.summarize_weeks(
            growth_session, conn, wf.week_ranges(WEEK_B, 2), now=NOW.astimezone(timezone.utc)
        )


# ---------- 周边界 ----------

def test_week_starts_sunday_shanghai_and_saturday_last_second_stays_in_previous_week():
    assert wf.week_start_of(SAT_LAST_SECOND_A) == WEEK_A
    assert wf.week_start_of(SUN_FIRST_SECOND_B) == WEEK_B
    # 同一时刻用 UTC 表达：周六 15:59:59Z 是上海周六 23:59:59，16:00:00Z 已是上海周日 00:00。
    assert wf.week_start_of(datetime(2026, 11, 7, 15, 59, 59, tzinfo=timezone.utc)) == WEEK_A
    assert wf.week_start_of(datetime(2026, 11, 7, 16, 0, 0, tzinfo=timezone.utc)) == WEEK_B
    # UTC 仍是周六白天，但上海已经是周日。
    assert wf.week_start_of(datetime(2026, 11, 7, 17, 0, tzinfo=timezone.utc)).weekday() == 6


def test_week_ranges_are_contiguous_and_validated():
    ranges = wf.week_ranges(WEEK_B, 3)
    assert [r[0].date().isoformat() for r in ranges] == ["2026-10-25", "2026-11-01", "2026-11-08"]
    for (_, end), (start, _) in zip(ranges, ranges[1:]):
        assert end == start
    assert all(r[0].utcoffset() == timedelta(hours=8) for r in ranges)
    with pytest.raises(wf.WeekError):
        wf.week_ranges(WEEK_B, 0)
    with pytest.raises(wf.WeekError):
        wf.week_ranges(WEEK_B, wf.MAX_WEEKS + 1)
    with pytest.raises(wf.WeekError):
        wf.parse_week_start("2026-11-07")  # 周六
    with pytest.raises(wf.WeekError):
        wf.parse_week_start("not-a-date")
    assert wf.parse_week_start("2026-11-08") == WEEK_B


# ---------- 各字段 ----------

def test_each_field_counts_the_right_rows(growth_session, records):
    _add_users(growth_session)
    week_a, week_b = _two_weeks(growth_session, records)

    assert week_a["week_start"] == "2026-11-01T00:00:00+08:00"
    assert week_a["week_end"] == "2026-11-07T23:59:59+08:00"
    assert week_a["complete"] is True and week_b["complete"] is False

    # 注册：非游客；周六最后一秒在 A，周日第一秒在 B。
    assert week_a["new_signups"] == 1
    assert week_b["new_signups"] == 2

    # 新付费：此前从未付过款的人。u1 在 A；u2、u7 在 B（u2 后来退款也算付款那周）。
    assert week_a["new_paid"] == 1
    assert week_b["new_paid"] == 2
    # 续费：付款人此前已付过款。u1 的第二单在 B。
    assert week_a["renewals"] == 0
    assert week_b["renewals"] == 1

    # 订单金额（分）：只算 CNY + 支付宝/微信 + paid/refunded。
    assert week_a["order_amount_cents"] == 39900
    assert week_b["order_amount_cents"] == 39900 + 39900 + 1990

    # 退款金额（分）：只算 settled。
    assert week_a["refund_amount_cents"] == 1000
    assert week_b["refund_amount_cents"] == 39900

    # 到期：每人最晚一条 active 国内会员到期且已过去。
    assert week_a["expirations"] == 1
    assert week_b["expirations"] == 1


def test_signup_source_breakdown_is_null_with_note_when_table_missing(growth_session, records):
    week_a, _ = _two_weeks(growth_session, records)
    assert week_a["signups_by_source"] is None
    assert "growth_signup_source" in week_a["signups_by_source_note"]


def test_signup_source_breakdown_counts_by_week_when_table_present(growth_session, records):
    from app.growth.models import GrowthEvent

    growth_session.execute(text(
        "CREATE TABLE IF NOT EXISTS growth_signup_source "
        "(event_id VARCHAR(64) PRIMARY KEY, source VARCHAR(16), created_at INTEGER)"
    ))
    for event_id, at in (("ev-a", SAT_LAST_SECOND_A), ("ev-b1", SUN_FIRST_SECOND_B),
                         ("ev-b2", SUN_FIRST_SECOND_B), ("ev-b3", SUN_FIRST_SECOND_B)):
        growth_session.add(GrowthEvent(id=event_id, event_type="signup", user_id=event_id,
                                       created_at=int(at.timestamp())))
    growth_session.flush()
    for event_id, source in (("ev-a", "xiaohongshu"), ("ev-b1", "douyin"), ("ev-b2", "douyin")):
        growth_session.execute(
            text("INSERT INTO growth_signup_source (event_id, source, created_at) VALUES (:e,:s,0)"),
            {"e": event_id, "s": source},
        )
    growth_session.commit()

    week_a, week_b = _two_weeks(growth_session, records)
    assert week_a["signups_by_source"]["xiaohongshu"] == 1
    assert week_a["signups_by_source"]["unanswered"] == 0
    assert week_b["signups_by_source"]["douyin"] == 2
    assert week_b["signups_by_source"].get("xiaohongshu", 0) == 0
    assert week_b["signups_by_source"]["unanswered"] == 1
    assert "signups_by_source_note" not in week_b


def test_missing_record_tables_give_zero_not_error(growth_session, tmp_path):
    empty = tmp_path / "empty.db"
    sqlite3.connect(empty).close()
    with _open(empty) as conn:
        (week,) = wf.summarize_weeks(growth_session, conn, wf.week_ranges(WEEK_B, 1), now=NOW)
    assert week["order_amount_cents"] == 0 and week["expirations"] == 0


# ---------- HTTP：令牌范围 ----------

FORBIDDEN_KEYS = {"user_id", "userId", "phone", "nickname", "email", "order_no", "transaction_id",
                  "trade_no", "id", "name", "event_id"}


def _walk_keys(value):
    if isinstance(value, dict):
        for key, inner in value.items():
            yield key
            yield from _walk_keys(inner)
    elif isinstance(value, list):
        for inner in value:
            yield from _walk_keys(inner)


@pytest.fixture()
def wired(anonymous_client, records, monkeypatch):
    monkeypatch.setattr(wf, "open_records", lambda: _open(records))
    monkeypatch.setenv(wf.READONLY_TOKEN_ENV, RO_TOKEN)
    monkeypatch.setenv("OPENCLAW_SHUNSHI_ADMIN_TOKEN", ADMIN_OPS_TOKEN)
    session = anonymous_client.app.state.session_factory()
    _add_users(session)
    session.close()
    return anonymous_client


def _ro():
    return {"Authorization": f"Bearer {RO_TOKEN}"}


def test_readonly_token_reads_weekly_summary_without_user_level_data(wired):
    response = wired.get(f"{wf.WEEKLY_PATH}?week_start=2026-11-08&weeks=2", headers=_ro())
    assert response.status_code == 200, response.text
    data = response.json()["data"]
    assert data["timezone"] == "Asia/Shanghai"
    assert data["money_unit"] == "分"
    assert [w["week_start"] for w in data["weeks"]] == [
        "2026-11-01T00:00:00+08:00", "2026-11-08T00:00:00+08:00"]
    assert data["weeks"][1]["order_amount_cents"] == 39900 + 39900 + 1990
    keys = set(_walk_keys(response.json()))
    assert not keys & FORBIDDEN_KEYS
    for marker in ("u1", "u2", "s-a", "s-b", "138000", "ORDER", "trade"):
        assert marker not in response.text


def test_readonly_token_cannot_reach_other_admin_routes_or_write(wired):
    for path in ("/api/v1/admin/growth/funnel", "/api/v1/admin/growth/metrics",
                 "/api/v1/admin/growth/audit", "/api/v1/admin/growth/queue",
                 "/api/v1/admin/growth/sources", "/api/v1/admin/dashboard"):
        assert wired.get(path, headers=_ro()).status_code == 403, path
    for path, body in (("/api/v1/admin/growth/cycle", {"proposals": []}),
                       ("/api/v1/admin/growth/rollback", {"object_key": "x"}),
                       ("/api/v1/admin/growth/approvals",
                        {"channel": "in_app_card", "content_sha256": "0" * 64})):
        assert wired.post(path, headers=_ro(), json=body).status_code == 403, path
    # 同一路径的写方法没有放行。
    assert wired.post(wf.WEEKLY_PATH, headers=_ro(), json={}).status_code in (403, 405)
    assert wired.delete(wf.WEEKLY_PATH, headers=_ro()).status_code in (403, 405)
    # 也不能当普通用户令牌用。
    assert wired.get("/api/v1/growth/cards", headers=_ro()).status_code == 401
    # 放在 X-Admin-Token 里不算（没有 Bearer 时门禁按「没登录」回 401）。
    assert wired.get(wf.WEEKLY_PATH, headers={"X-Admin-Token": RO_TOKEN}).status_code in (401, 403)


def test_missing_wrong_or_unconfigured_token_is_rejected(wired, monkeypatch):
    assert wired.get(wf.WEEKLY_PATH).status_code == 401
    bad = wired.get(wf.WEEKLY_PATH, headers={"Authorization": "Bearer not-the-token"})
    assert bad.status_code == 403
    monkeypatch.delenv(wf.READONLY_TOKEN_ENV)
    assert wired.get(wf.WEEKLY_PATH, headers=_ro()).status_code == 403
    monkeypatch.setenv(wf.READONLY_TOKEN_ENV, "")
    assert wired.get(wf.WEEKLY_PATH, headers={"Authorization": "Bearer "}).status_code == 401


def test_admin_tokens_still_work(wired, admin_client, records, monkeypatch):
    ops = wired.get(wf.WEEKLY_PATH, headers={"Authorization": f"Bearer {ADMIN_OPS_TOKEN}"})
    assert ops.status_code == 200
    assert wired.get("/api/v1/admin/growth/funnel",
                     headers={"Authorization": f"Bearer {ADMIN_OPS_TOKEN}"}).status_code == 200
    monkeypatch.setattr(wf, "open_records", lambda: _open(records))
    signed_in = admin_client.get(wf.WEEKLY_PATH, params={"weeks": 1})
    assert signed_in.status_code == 200
    assert len(signed_in.json()["data"]["weeks"]) == 1


def test_bad_week_parameters_return_422(wired):
    assert wired.get(f"{wf.WEEKLY_PATH}?week_start=2026-11-07", headers=_ro()).status_code == 422
    assert wired.get(f"{wf.WEEKLY_PATH}?weeks=27", headers=_ro()).status_code == 422
    assert wired.get(f"{wf.WEEKLY_PATH}?weeks=0", headers=_ro()).status_code == 422
    assert wired.get(f"{wf.WEEKLY_PATH}?week_start=2999-01-04", headers=_ro()).status_code == 422


def test_future_week_is_rejected_and_current_week_is_default(growth_session, records, monkeypatch):
    monkeypatch.setattr(wf, "open_records", lambda: _open(records))
    with pytest.raises(wf.WeekError):
        wf.build_report(growth_session, week_start="2026-11-15", now=NOW)
    report = wf.build_report(growth_session, weeks=1, now=NOW)
    assert report["weeks"][0]["week_start"] == "2026-11-08T00:00:00+08:00"
    assert report["weeks"][0]["complete"] is False
    assert report["generated_at"] == "2026-11-11T12:00:00+08:00"


def test_readonly_token_compare_uses_digests(monkeypatch):
    monkeypatch.setenv(wf.READONLY_TOKEN_ENV, RO_TOKEN)
    assert wf.readonly_token_ok(RO_TOKEN)
    assert not wf.readonly_token_ok(RO_TOKEN + "x")
    assert not wf.readonly_token_ok("")
    monkeypatch.delenv(wf.READONLY_TOKEN_ENV)
    assert not wf.readonly_token_ok(RO_TOKEN)
