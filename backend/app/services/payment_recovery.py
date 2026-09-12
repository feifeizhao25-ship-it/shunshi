"""Durable recovery jobs created atomically with verified domestic payments."""
import asyncio
import logging
import time
from types import SimpleNamespace

from fastapi import HTTPException
from starlette.concurrency import run_in_threadpool

logger = logging.getLogger(__name__)


def ensure_recovery_jobs(db):
    db.execute("""CREATE TABLE IF NOT EXISTS domestic_payment_recovery (
        user_id TEXT PRIMARY KEY, generation INTEGER NOT NULL DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'pending', attempts INTEGER NOT NULL DEFAULT 0,
        next_attempt_at INTEGER NOT NULL DEFAULT 0, last_error TEXT)""")
    db.execute("""CREATE INDEX IF NOT EXISTS idx_domestic_payment_recovery_due
        ON domestic_payment_recovery(status,next_attempt_at)""")


def enqueue_recovery(db, user_id):
    # Caller owns the payment transaction. Never commit independently here.
    db.execute("""INSERT INTO domestic_payment_recovery(user_id) VALUES (?)
        ON CONFLICT(user_id) DO UPDATE SET generation=generation+1,
        status='pending',attempts=0,next_attempt_at=0,last_error=NULL""", (user_id,))


def recover_pending_payments(app, limit=25):
    from app.database.db import get_db, close_test_connection
    from .payment_activation import _restore_domestic_entitlement

    db = get_db()
    result = {"restored": 0, "retry": 0, "blocked": 0, "discarded": 0}
    try:
        ensure_recovery_jobs(db)
        jobs = db.execute("""SELECT * FROM domestic_payment_recovery
            WHERE status='pending' AND next_attempt_at<=?
            ORDER BY next_attempt_at,user_id LIMIT ?""", (int(time.time()), limit)).fetchall()
        for job in jobs:
            try:
                _restore_domestic_entitlement(SimpleNamespace(app=app), db, job['user_id'])
                result['restored'] += 1
            except HTTPException as exc:
                if exc.status_code == 410:
                    db.execute("""DELETE FROM domestic_payment_recovery
                        WHERE user_id=? AND generation=?""", (job['user_id'], job['generation']))
                    db.commit()
                    result['discarded'] += 1
                    continue
                blocked = exc.status_code == 409
                status = 'blocked' if blocked else 'pending'
                delay = min(3600, 60 * 2 ** min(job['attempts'], 6))
                # Do not mark a newer payment's job failed after losing the lock.
                db.execute("""UPDATE domestic_payment_recovery SET status=?,
                    attempts=attempts+1,next_attempt_at=?,last_error=?
                    WHERE user_id=? AND generation=? AND status='pending'""",
                    (status, int(time.time()) + delay, str(exc.status_code),
                     job['user_id'], job['generation']))
                db.commit()
                result['blocked' if blocked else 'retry'] += 1
        if result['blocked'] or result['retry']:
            logger.warning('国内付款权益恢复待处理：重试 %s，需核对 %s',
                           result['retry'], result['blocked'])
        return result
    finally:
        close_test_connection(db)


async def payment_recovery_loop(app, stop):
    while not stop.is_set():
        try:
            app.state.payment_recovery_last_result = await run_in_threadpool(
                recover_pending_payments, app)
        except Exception:
            logger.exception('国内付款权益恢复任务失败，下轮重试')
        try:
            await asyncio.wait_for(stop.wait(), timeout=60)
        except asyncio.TimeoutError:
            pass
