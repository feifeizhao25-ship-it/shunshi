from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from datetime import datetime, timedelta, timezone
from sqlalchemy import select, func
from fastapi import HTTPException
from app.db import make_engine, make_session_factory
from app.simple_models import User, Entitlement, StorePurchase, StorePurchaseOwner
from app.services.store_restore import persist_restore

engine = make_engine('postgresql://store_ci@127.0.0.1:55439/postgres')
for model in (User, Entitlement, StorePurchaseOwner, StorePurchase):
    model.__table__.create(engine)
factory = make_session_factory(engine)
with factory() as s:
    s.add_all([User(id=u) for u in ['alice', 'bob', 'renew']]); s.commit()
expiry = datetime.now(timezone.utc) + timedelta(days=1)
def run(user, tx, chain, end, barrier):
    barrier.wait(timeout=10)
    try:
        with factory() as s:
            persist_restore(s, user_id=user, store='ios', transaction_id=tx,
                chain_id=chain, product_id='com.shunshi.yiyang.yearly', plan='yiyang',
                expires_at=end, auto_renew=False, receipt_hash=None)
        return 200
    except HTTPException as e:
        return e.status_code
barrier = Barrier(2)
with ThreadPoolExecutor(2) as pool:
    futures = [pool.submit(run, user, 'same-tx', 'same-chain', expiry, barrier) for user in ['alice', 'bob']]
    results = [f.result(timeout=15) for f in futures]
assert sorted(results) == [200, 409], results
with factory() as s:
    assert s.scalar(select(func.count()).select_from(StorePurchase)) == 1
    assert s.scalar(select(func.count()).select_from(Entitlement)) == 1
barrier = Barrier(2)
with ThreadPoolExecutor(2) as pool:
    futures = [pool.submit(run, 'renew', tx, 'renew-chain', end, barrier) for tx,end in [('short',expiry), ('long', expiry+timedelta(days=1))]]
    results = [f.result(timeout=15) for f in futures]
assert all(code in [200,409] for code in results)
with factory() as s:
    assert s.get(Entitlement,'renew').expires_at == int((expiry+timedelta(days=1)).timestamp())
print('PostgreSQL 17: concurrent cross-account claim has one winner; losing transaction rolled back; concurrent renewals preserve longer expiry; persisted rows verified in fresh sessions.')
engine.dispose()
