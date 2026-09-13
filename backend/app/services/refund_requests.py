"""Persist refund requests; acceptance is not a merchant refund result."""
from datetime import datetime, timezone
import uuid

from fastapi import HTTPException

from app.database.db import get_db, close_test_connection
from app.services.alipay_service import alipay_amount_cents


def _ensure_table(db):
    db.execute("""CREATE TABLE IF NOT EXISTS domestic_refund_requests (
        order_no TEXT PRIMARY KEY, refund_no TEXT NOT NULL UNIQUE,
        user_id TEXT NOT NULL, amount_cents INTEGER NOT NULL CHECK(amount_cents>0),
        reason TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'pending_review',
        created_at TEXT NOT NULL)""")


def _order(db, order_no, user_id):
    from app.router.subscription import _ensure_payment_orders_table
    _ensure_payment_orders_table(db)
    row = db.execute('SELECT * FROM payment_orders WHERE order_no=?', (order_no,)).fetchone()
    if row is None or row['user_id'] != user_id:
        raise HTTPException(status_code=404, detail='订单不存在')
    return row


def _view(row):
    if row['status'] != 'pending_review':
        raise HTTPException(status_code=503, detail='退款处理状态需要核对')
    return {'order_no': row['order_no'], 'refund_no': row['refund_no'],
        'refund_amount': f"{row['amount_cents'] // 100}.{row['amount_cents'] % 100:02d}",
        'refund_status': 'PENDING_REVIEW', 'status_label': '待处理',
        'refund_completed': False, 'created_at': row['created_at']}


def submit_refund_request(order_no, user_id, amount, reason):
    try:
        cents = alipay_amount_cents(amount)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail='退款金额格式无效') from exc
    db = get_db()
    try:
        _ensure_table(db)
        # Initialize legacy order schema before taking the shared writer lock.
        _order(db, order_no, user_id)
        db.execute('BEGIN IMMEDIATE')
        order = _order(db, order_no, user_id)
        if order['platform'] != 'alipay' or order['currency'] != 'CNY':
            raise HTTPException(status_code=400, detail='订单支付渠道或币种不支持该退款申请')
        if order['status'] != 'paid' or not order['transaction_id']:
            raise HTTPException(status_code=409, detail='订单尚未确认付款，不能申请退款')
        if cents > order['amount_cents']:
            raise HTTPException(status_code=400, detail='申请退款金额不能超过订单实付金额')
        existing = db.execute('SELECT * FROM domestic_refund_requests WHERE order_no=?',
            (order_no,)).fetchone()
        if existing is not None:
            if existing['amount_cents'] != cents:
                raise HTTPException(status_code=409, detail='该订单已有退款申请，请先核对原申请')
            result = _view(existing)
        else:
            db.execute("""INSERT INTO domestic_refund_requests
                (order_no,refund_no,user_id,amount_cents,reason,created_at)
                VALUES (?,?,?,?,?,?)""", (order_no, 'RF' + uuid.uuid4().hex,
                    user_id, cents, reason, datetime.now(timezone.utc).isoformat()))
            result = _view(db.execute('SELECT * FROM domestic_refund_requests WHERE order_no=?',
                (order_no,)).fetchone())
        db.commit()
        return result
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


def get_refund_request(order_no, user_id):
    db = get_db()
    try:
        _order(db, order_no, user_id)
        _ensure_table(db)
        row = db.execute('SELECT * FROM domestic_refund_requests WHERE order_no=?',
            (order_no,)).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail='退款申请不存在')
        return _view(row)
    finally:
        close_test_connection(db)
