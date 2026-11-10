"""Settle a domestic entitlement only after a verified Alipay refund notice.

The notice must already have passed ``AlipayService.verify_notify`` (the SDK
RSA2 ``verify``). This module does not call the merchant refund API and does
not invent a signature. WeChat refund notices are not implemented; that
channel stays closed.

A pending refund request is not a refund. Entitlement changes happen only when
the signed ``refund_fee`` equals the server order amount and ``gmt_refund`` is
present. A smaller verified fee is stored and does not change entitlements.
"""
from __future__ import annotations

import sqlite3
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, Request

from app.services.alipay_service import AlipayNotifyData, alipay_amount_cents

CN_TZ = timezone(timedelta(hours=8))


def is_alipay_refund_notice(notify: AlipayNotifyData) -> bool:
    return bool(notify.gmt_refund.strip() and notify.refund_fee.strip())


def apply_verified_alipay_refund(request: Request, notify: AlipayNotifyData) -> dict:
    from app.database.db import close_test_connection, get_db
    from app.router import subscription as sub

    if not is_alipay_refund_notice(notify):
        raise HTTPException(status_code=400, detail="退款通知缺少退款时间或金额")
    try:
        refund_cents = alipay_amount_cents(notify.refund_fee)
        refunded_at = _refund_time(notify.gmt_refund)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="退款通知金额或时间无效") from exc

    db = get_db()
    try:
        _ensure_events(db)
        from app.router.subscription import _ensure_payment_orders_table
        _ensure_payment_orders_table(db)
        db.execute("BEGIN IMMEDIATE")
        order = db.execute(
            "SELECT * FROM payment_orders WHERE order_no=?", (notify.out_trade_no,)
        ).fetchone()
        if order is None:
            raise HTTPException(status_code=404, detail="支付订单不存在")
        if order["platform"] != "alipay" or order["currency"] != "CNY":
            raise HTTPException(status_code=400, detail="退款通知与订单渠道或币种不匹配")
        if not order["transaction_id"] or order["transaction_id"] != notify.trade_no:
            raise HTTPException(status_code=409, detail="退款通知与原支付流水不匹配")
        if order["status"] == "pending":
            raise HTTPException(status_code=503, detail="原交易尚未入账，退款通知稍后重试")
        if order["status"] not in {"paid", "refunded"}:
            raise HTTPException(status_code=409, detail="订单状态不允许按退款通知结算")

        event_key = _event_key(notify, refund_cents)
        existing = db.execute(
            "SELECT outcome FROM domestic_refund_events WHERE provider=? AND event_key=?",
            ("alipay", event_key),
        ).fetchone()
        if existing is not None:
            db.rollback()
            return {"outcome": existing["outcome"], "duplicate": True}

        paid_cents = int(order["amount_cents"])
        if refund_cents > paid_cents:
            outcome = "rejected"
        elif refund_cents < paid_cents:
            outcome = "deferred"
        elif order["status"] == "refunded":
            outcome = "already_settled"
        else:
            outcome = "settled"

        try:
            db.execute(
                """INSERT INTO domestic_refund_events
                (provider,event_key,order_no,trade_no,user_id,refund_cents,outcome,created_at)
                VALUES (?,?,?,?,?,?,?,?)""",
                ("alipay", event_key, order["order_no"], notify.trade_no, order["user_id"],
                 refund_cents, outcome, refunded_at.isoformat()),
            )
        except sqlite3.IntegrityError:
            db.rollback()
            stored = db.execute(
                "SELECT outcome FROM domestic_refund_events WHERE provider=? AND event_key=?",
                ("alipay", event_key),
            ).fetchone()
            return {"outcome": stored["outcome"] if stored else "duplicate", "duplicate": True}
        if outcome == "settled":
            changed = db.execute(
                """UPDATE payment_orders SET status='refunded'
                WHERE order_no=? AND status='paid' AND transaction_id=?""",
                (order["order_no"], notify.trade_no),
            )
            if changed.rowcount != 1:
                raise HTTPException(status_code=409, detail="订单在结算时已变化")
            db.execute(
                """UPDATE subscriptions SET status='refunded'
                WHERE id=? AND user_id=? AND status='active'""",
                (f"sub_alipay_{order['order_no']}", order["user_id"]),
            )
            _mark_request_settled(db, order["order_no"])
            _project_entitlement(request, db, order["user_id"], refunded_at)
            if order["id"] in sub.payment_orders:
                sub.payment_orders[order["id"]]["status"] = "refunded"
            _refresh_cache(sub, db, order["user_id"])
        db.commit()
        if outcome == "settled":
            sub._write_audit_log("refund_settled", order["user_id"], {
                "order_no": order["order_no"], "trade_no": notify.trade_no,
                "refund_cents": refund_cents,
            })
        return {"outcome": outcome, "duplicate": False}
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


def _event_key(notify: AlipayNotifyData, refund_cents: int) -> str:
    biz = notify.out_biz_no.strip() or f"{refund_cents}:{notify.gmt_refund.strip()}"
    return f"{notify.out_trade_no}:{notify.trade_no}:{biz}"


def _refund_time(value: str) -> datetime:
    text = value.strip()
    try:
        parsed = datetime.strptime(text, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        parsed = datetime.fromisoformat(text)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=CN_TZ)
    return parsed.astimezone(timezone.utc)


def _ensure_events(db) -> None:
    db.execute("""CREATE TABLE IF NOT EXISTS domestic_refund_events (
        provider TEXT NOT NULL, event_key TEXT NOT NULL,
        order_no TEXT NOT NULL, trade_no TEXT NOT NULL, user_id TEXT NOT NULL,
        refund_cents INTEGER NOT NULL, outcome TEXT NOT NULL, created_at TEXT NOT NULL,
        PRIMARY KEY (provider, event_key))""")


def _mark_request_settled(db, order_no: str) -> None:
    db.execute("""CREATE TABLE IF NOT EXISTS domestic_refund_requests (
        order_no TEXT PRIMARY KEY, refund_no TEXT NOT NULL UNIQUE,
        user_id TEXT NOT NULL, amount_cents INTEGER NOT NULL,
        reason TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'pending_review',
        created_at TEXT NOT NULL)""")
    db.execute(
        """UPDATE domestic_refund_requests SET status='settled'
        WHERE order_no=? AND status='pending_review'""",
        (order_no,),
    )


def _remaining_paid(db, user_id: str):
    return db.execute(
        """SELECT p.*, s.expires_at AS membership_expires_at FROM subscriptions s
        JOIN payment_orders p ON s.id=('sub_' || p.platform || '_' || p.order_no)
        WHERE p.user_id=? AND s.user_id=p.user_id AND p.status='paid' AND s.status='active'
        AND p.platform IN ('alipay','wechat')
        ORDER BY s.expires_at DESC""",
        (user_id,),
    ).fetchall()


def _project_entitlement(request: Request, db, user_id: str, refunded_at: datetime) -> None:
    from app.simple_models import Entitlement, User
    from sqlalchemy import update

    session_factory = getattr(request.app.state, "session_factory", None)
    if session_factory is None:
        raise HTTPException(status_code=503, detail="会员权益存储不可用，请稍后重试")
    remaining = _remaining_paid(db, user_id)
    with session_factory() as session:
        locked = session.execute(
            update(User).where(User.id == user_id).values(nickname=User.nickname)
        ).rowcount
        if locked != 1:
            raise HTTPException(status_code=410, detail="账号已不存在，不能结算退款权益")
        entitlement = session.get(Entitlement, user_id)
        if entitlement and entitlement.store not in {"alipay", "wechat"}:
            session.rollback()
            return
        if remaining:
            latest = dict(remaining[0])
            expiry = datetime.fromisoformat(latest["membership_expires_at"])
            if expiry.tzinfo is None:
                expiry = expiry.replace(tzinfo=timezone.utc)
            values = dict(
                product_id=latest["product_id"], store=latest["platform"],
                expires_at=int(expiry.timestamp()),
                original_transaction_id=latest["transaction_id"],
                updated_at=int(refunded_at.timestamp()),
            )
        else:
            if entitlement is None:
                session.rollback()
                return
            values = dict(
                expires_at=int(refunded_at.timestamp()),
                updated_at=int(refunded_at.timestamp()),
            )
        if entitlement is None:
            session.add(Entitlement(user_id=user_id, **values))
        else:
            for key, value in values.items():
                setattr(entitlement, key, value)
        session.commit()


def _refresh_cache(sub, db, user_id: str) -> None:
    remaining = _remaining_paid(db, user_id)
    if not remaining:
        current = sub.subscriptions.get(user_id)
        if current:
            current["status"] = "expired"
        return
    latest = dict(remaining[0])
    sub.subscriptions[user_id] = {
        "plan": latest["tier"], "status": "active",
        "expires_at": latest["membership_expires_at"], "auto_renew": False,
        "platform": latest["platform"], "order_id": latest["id"],
        "order_no": latest["order_no"], "activated_at": latest["paid_at"],
        "features": sub.SUBSCRIPTION_PLANS[latest["tier"]]["features"],
    }
    order = db.execute(
        "SELECT * FROM payment_orders WHERE order_no=?", (latest["order_no"],)
    ).fetchone()
    if order is not None:
        sub.payment_orders[order["id"]] = dict(order)


def project_after_refund_if_no_paid_source(request: Request, db, user_id: str) -> bool:
    """Recovery must not rebuild a grant whose only domestic source was refunded."""
    _ensure_events(db)
    if _remaining_paid(db, user_id):
        return False
    row = db.execute(
        """SELECT e.created_at FROM domestic_refund_events e
        JOIN payment_orders o ON o.order_no=e.order_no
        WHERE o.user_id=? AND o.status='refunded' AND e.outcome='settled'
        ORDER BY e.created_at DESC LIMIT 1""",
        (user_id,),
    ).fetchone()
    if row is None:
        return False
    from app.router import subscription as sub
    _project_entitlement(request, db, user_id, datetime.fromisoformat(row["created_at"]))
    _refresh_cache(sub, db, user_id)
    return True
