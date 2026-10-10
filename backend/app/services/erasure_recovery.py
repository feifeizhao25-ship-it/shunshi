"""Restart-safe, idempotent cleanup after the core account has been deleted."""
import asyncio
import logging
import time

from fastapi import HTTPException
from sqlalchemy import select, update
from starlette.concurrency import run_in_threadpool
from app.simple_models import AccountErasureJob, User

logger = logging.getLogger(__name__)


def reject_erased_account(request, user_id):
    factory = getattr(request.app.state, 'session_factory', None)
    if factory is not None:
        with factory() as session:
            if session.get(AccountErasureJob, user_id) is not None:
                raise HTTPException(401, '账号已注销')


def cleanup_account(app, user_id):
    from app.database.db import get_db, close_test_connection
    from . import account_erasure
    result = dict(deleted_record_rows={}, deleted_product_rows={},
                  retained_billing_records={}, erasure_incomplete_tables=[], attempted=False)
    db = None
    previous_attempts = None
    try:
        db = get_db()
        # Same lock order as payment projection and account deletion.
        db.execute('BEGIN IMMEDIATE')
        with app.state.session_factory() as session:
            changed = session.execute(update(AccountErasureJob).where(
                AccountErasureJob.user_id == user_id, AccountErasureJob.status == 'pending',
                AccountErasureJob.next_attempt_at <= int(time.time())
            ).values(attempts=AccountErasureJob.attempts + 1)).rowcount
            if changed != 1:
                job = session.get(AccountErasureJob, user_id)
                if job is None:
                    result['erasure_incomplete_tables'] = ['cleanup_job_missing']
                elif job.status != 'done':
                    result['erasure_incomplete_tables'] = ['cleanup_pending']
                db.rollback()
                return result
            job = session.get(AccountErasureJob, user_id)
            previous_attempts = job.attempts - 1
            result['attempted'] = True
            if session.get(User, user_id) is not None:
                raise RuntimeError('core_account_still_exists')
            if db.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name='domestic_payment_recovery'").fetchone():
                # This is an operational job, not a financial receipt to retain.
                db.execute('DELETE FROM domestic_payment_recovery WHERE user_id=?', (user_id,))
            deleted, retained = account_erasure.erase_record_store(db, user_id)
            db.commit()
            result['deleted_record_rows'] = deleted
            result['retained_billing_records'].update(retained)
            deleted, retained, remaining = account_erasure.erase_product_store(user_id)
            result['deleted_product_rows'] = deleted
            result['retained_billing_records'].update(retained)
            result['erasure_incomplete_tables'] = remaining
            job.last_error = 'incomplete_tables' if remaining else None
            job.next_attempt_at = int(time.time()) + min(3600, 60 * 2 ** min(job.attempts - 1, 6)) if remaining else 0
            if not remaining:
                job.status = 'done'
                job.completed_at = int(time.time())
            session.commit()
        return result
    except Exception:
        if db is not None:
            db.rollback()
        # No raw exception text, SQL parameters, or profile data in the job.
        # A competing worker may have finished after this attempt failed.
        with app.state.session_factory() as session:
            conditions = [AccountErasureJob.user_id == user_id, AccountErasureJob.status == 'pending',
                          AccountErasureJob.next_attempt_at <= int(time.time())]
            if previous_attempts is not None:
                conditions.append(AccountErasureJob.attempts == previous_attempts)
            changed = session.execute(update(AccountErasureJob).where(*conditions
            ).values(attempts=AccountErasureJob.attempts + 1,
                     next_attempt_at=int(time.time()) + min(3600, 60 * 2 ** min(previous_attempts or 0, 6)),
                     last_error='cleanup_failed')).rowcount
            session.commit()
            result['attempted'] = bool(changed)
        result['erasure_incomplete_tables'] = ['record_store', 'product_store']
        logger.warning('账号数据清理未完成，已保留恢复任务')
        return result
    finally:
        if db is not None:
            close_test_connection(db)


def recover_pending_erasures(app, limit=25):
    with app.state.session_factory() as session:
        ids = session.scalars(select(AccountErasureJob.user_id).where(
            AccountErasureJob.status == 'pending', AccountErasureJob.next_attempt_at <= int(time.time())
        ).order_by(AccountErasureJob.next_attempt_at, AccountErasureJob.user_id).limit(limit)).all()
    result = {'completed': 0, 'retry': 0}
    for user_id in ids:
        status = cleanup_account(app, user_id)
        if not status['attempted']:
            continue
        result['retry' if status['erasure_incomplete_tables'] else 'completed'] += 1
    return result


async def erasure_recovery_loop(app, stop):
    while not stop.is_set():
        try:
            app.state.erasure_recovery_last_result = await run_in_threadpool(recover_pending_erasures, app)
        except Exception:
            logger.warning('账号数据清理恢复任务暂不可用，下轮重试')
        try:
            await asyncio.wait_for(stop.wait(), timeout=60)
        except asyncio.TimeoutError:
            pass
