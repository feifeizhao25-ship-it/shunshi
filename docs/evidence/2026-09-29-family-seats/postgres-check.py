import os
os.environ["JWT_SECRET"] = "fixture-only-family-concurrency-secret-0929"
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
import time
from sqlalchemy import select, func
from fastapi import HTTPException
from app.db import make_engine, make_session_factory
from app.simple_models import User, Entitlement, FamilySeat
from app.services.family_seats import bind_seat, seats_info

engine=make_engine('postgresql://family_ci@127.0.0.1:55439/family_concurrency')
for model in (User,Entitlement,FamilySeat): model.__table__.create(engine)
factory=make_session_factory(engine)
with factory() as s:
    s.add(User(id='owner'))
    s.add(Entitlement(user_id='owner',product_id='jiahe_yearly',store='alipay',expires_at=int(time.time()+86400),original_transaction_id='family-fixture'))
    s.commit()
for i in range(3):
    with factory() as s: bind_seat(s,'owner',f'家人{i}',f'member-{i}')
barrier=Barrier(2)
def add(member):
    barrier.wait(timeout=10)
    try:
        with factory() as s: bind_seat(s,'owner',member,member)
        return 200
    except HTTPException as e: return e.status_code
with ThreadPoolExecutor(2) as pool:
    futures=[pool.submit(add, member) for member in ['fourth','fifth']]
    results=[f.result(timeout=15) for f in futures]
assert sorted(results)==[200,400],results
with factory() as s:
    assert s.scalar(select(func.count()).select_from(FamilySeat))==4
    assert seats_info(s,'owner')['available']==0
print('PostgreSQL 17: two concurrent requests for the last family seat yield one success and one rejection; fresh-session count stays at four.')
engine.dispose()
