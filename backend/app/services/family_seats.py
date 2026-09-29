"""Durable seat records; recording a member does not grant account access."""
import time
from datetime import datetime, timezone
from fastapi import HTTPException
from sqlalchemy import select, update
from app.simple_models import User, Entitlement, FamilySeat
from app.entitlements import tier_for_product


def _rows(session, user_id):
    return session.scalars(select(FamilySeat).where(FamilySeat.user_id == user_id).order_by(FamilySeat.bound_at, FamilySeat.id)).all()


def _capacity(session, user_id):
    current = session.get(Entitlement, user_id, populate_existing=True)
    if not current or current.expires_at <= time.time() or tier_for_product(current.product_id) != 'family':
        return 0
    from app.router.subscription import SUBSCRIPTION_PLANS
    return SUBSCRIPTION_PLANS['jiahe']['family_seats']


def seats_info(session, user_id):
    capacity = _capacity(session, user_id)
    rows = _rows(session, user_id)
    return {'family_seats': capacity, 'used_seats': len(rows),
            'available': max(0, capacity-len(rows)), 'active': capacity > 0,
            'members': [{'seat_id': row.id, 'name': row.member_name, 'user_id': row.member_user_id,
                         'bound_at': datetime.fromtimestamp(row.bound_at, timezone.utc).isoformat(),
                         'access_granted': False} for row in rows]}


def _lock_owner(session, user_id):
    if session.execute(update(User).where(User.id == user_id).values(nickname=User.nickname)).rowcount != 1:
        raise HTTPException(401, '账号已不存在，请重新登录')
    # Serialize against writers of the entitlement as well as other seat changes.
    session.scalar(select(Entitlement).where(Entitlement.user_id == user_id).with_for_update().execution_options(populate_existing=True))


def bind_seat(session, user_id, name, member_user_id):
    try:
        _lock_owner(session, user_id)
        capacity = _capacity(session, user_id)
        if not capacity:
            raise HTTPException(400, '当前会员没有可用家庭席位')
        rows = _rows(session, user_id)
        if member_user_id and any(row.member_user_id == member_user_id for row in rows):
            raise HTTPException(409, '该成员已占用一个席位')
        if len(rows) >= capacity:
            raise HTTPException(400, '家庭席位已满，无法添加新成员')
        session.add(FamilySeat(user_id=user_id, member_name=name.strip(), member_user_id=member_user_id))
        session.commit()
    except Exception:
        session.rollback()
        raise
    return seats_info(session, user_id)


def unbind_seat(session, user_id, member_user_id=None, member_index=None, seat_id=None):
    if sum(value is not None for value in (member_user_id, member_index, seat_id)) != 1:
        raise HTTPException(400, '请指定一个要移除的席位')
    try:
        _lock_owner(session, user_id)
        rows = _rows(session, user_id)
        target = next((row for row in rows if (seat_id is not None and row.id == seat_id) or
                       (member_user_id is not None and row.member_user_id == member_user_id)), None)
        if member_index is not None and 0 <= member_index < len(rows):
            target = rows[member_index]
        if target is None:
            raise HTTPException(404, '家庭席位不存在')
        session.delete(target)
        session.commit()
    except Exception:
        session.rollback()
        raise
    return seats_info(session, user_id)
