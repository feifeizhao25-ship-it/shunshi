"""Commit verified store ownership and entitlement together; never store receipts."""
import hashlib
import time
from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError

from app.simple_models import Entitlement, StorePurchase, StorePurchaseOwner, User


def _key(store, identifier):
    return hashlib.sha256(f'{store}:{identifier}'.encode()).hexdigest()


def persist_restore(session, *, user_id, store, transaction_id, chain_id,
                    product_id, plan, expires_at, auto_renew, receipt_hash):
    transaction_key = _key(store, transaction_id)
    chain_key = _key(store, chain_id)
    expiry = int(expires_at.timestamp())
    try:
        # A no-op row update serializes restores in both SQLite and PostgreSQL.
        locked = session.execute(update(User).where(User.id == user_id).values(nickname=User.nickname)).rowcount
        if locked != 1:
            raise HTTPException(410, '账号已不存在，不能恢复会员')
        owner = session.get(StorePurchaseOwner, chain_key)
        if owner and owner.user_id != user_id:
            raise HTTPException(409, '此购买凭证已关联其他账号')
        purchase = session.get(StorePurchase, transaction_key)
        if purchase and (purchase.user_id != user_id or purchase.chain_key != chain_key or purchase.product_id != product_id):
            raise HTTPException(409, '平台交易归属或商品冲突')
        current = session.get(Entitlement, user_id)
        period = 'monthly' if product_id.endswith(('.monthly', '_monthly')) else 'yearly'
        canonical = f'{"family" if plan == "jiahe" else plan}_{period}'
        if current and current.store not in {store} and current.expires_at > time.time():
            raise HTTPException(409, '当前存在其他渠道会员，请先核对权益')
        if current and current.store == store and (current.expires_at > expiry or
                (current.expires_at == expiry and current.product_id != canonical)):
            raise HTTPException(409, '此凭证早于当前会员期限，不覆盖已有权益')
        already = bool(purchase and purchase.expires_at == expiry and current and
                       current.original_transaction_id == transaction_key and current.expires_at == expiry)
        if owner is None:
            session.add(StorePurchaseOwner(chain_key=chain_key, user_id=user_id, store=store))
        if purchase is None:
            purchase = StorePurchase(transaction_key=transaction_key, chain_key=chain_key,
                user_id=user_id, store=store, product_id=product_id, plan=plan)
            session.add(purchase)
        purchase.expires_at = expiry
        purchase.auto_renew = auto_renew
        purchase.receipt_hash = receipt_hash
        purchase.verified_at = int(time.time())
        values = dict(product_id=canonical, store=store, expires_at=expiry,
                      original_transaction_id=transaction_key, updated_at=int(time.time()))
        if current:
            for key, value in values.items():
                setattr(current, key, value)
        else:
            session.add(Entitlement(user_id=user_id, **values))
        session.commit()
        return already
    except IntegrityError:
        session.rollback()
        raise HTTPException(409, '交易正在恢复或已关联其他账号，请重新核对') from None
    except Exception:
        session.rollback()
        raise


def hydrate_restore(session, user_id):
    """Read the authoritative entitlement, not a process-local success flag."""
    from app.router import subscription as sub
    current = session.get(Entitlement, user_id)
    if current is None or current.store not in {'ios', 'android'}:
        # Remove only stale IAP cache entries, leaving other channels' cache alone.
        if sub.subscriptions.get(user_id, {}).get('platform') in {'ios', 'android'}:
            sub.subscriptions.pop(user_id, None)
        return
    purchase = session.get(StorePurchase, current.original_transaction_id)
    if purchase is None or purchase.user_id != user_id:
        sub.subscriptions.pop(user_id, None)
        raise HTTPException(409, '会员交易记录不完整，请核对')
    active = current.expires_at > time.time()
    plan = purchase.plan if active else 'free'
    sub.subscriptions[user_id] = dict(plan=plan, status='active' if active else 'expired',
        expires_at=datetime.fromtimestamp(current.expires_at, timezone.utc).isoformat(),
        auto_renew=purchase.auto_renew, platform=current.store, restored=True,
        transaction_id=purchase.transaction_key, features=sub.SUBSCRIPTION_PLANS[plan]['features'])
