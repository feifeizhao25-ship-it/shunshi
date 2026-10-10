"""Recover the core identity for authenticated record-store accounts.

Record credentials remain authoritative. This is an idempotent projection, not
an atomic transaction spanning both stores. A failed projection can be retried
by logging in with the already persisted credentials.
"""
from fastapi import HTTPException
from app.simple_models import AccountErasureJob, User


def ensure_core_identity(request, user_id):
    from app.database.db import get_db, close_test_connection
    db = get_db()
    try:
        # Match erasure's lock order. Hold the writer lock until the core commit
        # so deletion cannot slip between the tombstone check and insertion.
        db.execute('BEGIN IMMEDIATE')
        row = db.execute('SELECT id, name, status FROM users WHERE id=?', (user_id,)).fetchone()
        if row is None or row['status'] == 'deleted':
            raise HTTPException(401, '账号不存在或已注销')
        with request.app.state.session_factory() as session:
            if session.get(AccountErasureJob, user_id) is not None:
                raise HTTPException(401, '账号已注销')
            if session.get(User, user_id) is None:
                # Never merge by an unverified email/phone, copy incompatible
                # password hashes, or grant membership from legacy premium flags.
                session.add(User(id=user_id, nickname=(row['name'] or '顺时用户')[:64], is_guest=False))
                session.commit()
        db.commit()
    except HTTPException:
        db.rollback()
        raise
    except Exception as exc:
        db.rollback()
        raise HTTPException(503, '账号同步暂未完成，请稍后使用原账号密码登录重试') from exc
    finally:
        close_test_connection(db)
