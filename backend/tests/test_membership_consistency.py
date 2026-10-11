"""Login, profile and subscription status must agree on core paid access."""
import time
from datetime import datetime
import uuid
import pytest
from app.simple_models import Entitlement
from app.database.db import get_db, close_test_connection
from app.entitlements import get_registry
from app.services.membership_status import _PRODUCT_PLANS

@pytest.fixture(params=['sqlite','postgres'])
def settings(request,settings):
    if request.param == 'postgres':
        return settings.model_copy(update={'database_url':request.getfixturevalue('postgres_database_url')})
    return settings

@pytest.fixture
def account(client):
    body={'email':f'member-{uuid.uuid4().hex}@example.com','password':'Fixture-pass-938','name':'会员测试'}
    r=client.post('/api/v1/auth/register',json=body)
    assert r.status_code == 200,r.text
    return body,r.json()['data']['user']['id'],{'Authorization':'Bearer '+r.json()['access_token']}

def seed(client,uid,sku,expires):
    with client.app.state.session_factory() as s:
        row=s.get(Entitlement,uid)
        if row is None:
            row=Entitlement(user_id=uid,original_transaction_id=uuid.uuid4().hex)
            s.add(row)
        row.product_id=sku
        row.expires_at=expires
        row.store='alipay'
        s.commit()

def assert_views(client,account,plan):
    body,uid,headers=account
    login=client.post('/api/v1/auth/login',json=body)
    me=client.get('/api/v1/auth/me',headers=headers)
    status=client.get('/api/v1/subscription/status',headers=headers)
    assert login.status_code == me.status_code == status.status_code == 200
    paid=plan!='free'
    for profile in (login.json()['data']['user'],me.json()['data']):
        assert profile['id']==uid
        assert profile['subscription_plan']==plan
        assert profile['is_premium'] is paid
        assert profile['subscription_type']==plan
        expiry=profile['subscription_expires_at']
        assert (datetime.fromisoformat(expiry).timestamp() if expiry else None)==status.json()['expires_at']
    assert status.json()['active'] is paid
    assert status.json()['data']['is_active'] is paid
    assert status.json()['data']['plan']==plan
    return status.json()

@pytest.mark.parametrize('sku,offset,plan',[
    (None,0,'free'),('jiahe_yearly',-1,'free'),
    ('unregistered_family_yearly',86400,'free'),('SHUNSHI_FAMILY_YEARLY',86400,'free'),
    ('yangxin_monthly',86400,'yangxin'),('shunshi_yiyang_yearly',86400,'yiyang'),
    ('jiahe_yearly',86400,'jiahe')])
def test_conflicting_legacy_flags_cannot_override_core(client,account,sku,offset,plan):
    _,uid,_=account
    db=get_db()
    try:
        db.execute('UPDATE users SET is_premium=?,subscription_plan=? WHERE id=?',
                   (int(plan=='free'),'jiahe' if plan=='free' else 'free',uid))
        db.commit()
    finally:
        close_test_connection(db)
    if sku:
        seed(client,uid,sku,int(time.time())+offset)
    state=assert_views(client,account,plan)
    if plan=='free':
        assert 'family' not in state['data']['features']
        assert state['tier']=='free'

def test_expiry_and_renewal_visible_without_restarting(client,account):
    _,uid,_=account
    for offset,plan in [(86400,'jiahe'),(-1,'free'),(172800,'jiahe')]:
        seed(client,uid,'jiahe_yearly',int(time.time())+offset)
        assert_views(client,account,plan)

def test_other_owners_entitlement_is_not_visible(client,account):
    seed(client,'another-owner','jiahe_yearly',int(time.time())+86400)
    assert_views(client,account,'free')

def test_core_failure_does_not_report_free_membership(client,account,monkeypatch):
    from app.services import membership_status
    def fail(*args):
        raise RuntimeError('private-database-details')
    monkeypatch.setattr(membership_status,'membership_status',fail)
    for r in (client.post('/api/v1/auth/login',json=account[0]),
              client.get('/api/v1/auth/me',headers=account[2])):
        assert r.status_code==503
        assert 'private-database' not in r.text
        assert 'is_premium' not in r.text

def test_every_registered_product_has_exact_domestic_plan():
    assert set(get_registry()['product_tier_map']) == set(_PRODUCT_PLANS)
