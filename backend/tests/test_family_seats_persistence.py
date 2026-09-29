import time
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, func
from app.main import create_app
from app.security import verify_token
from app.simple_models import Entitlement, FamilySeat


@pytest.fixture
def family(client, auth_headers, settings):
    actor = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    with client.app.state.session_factory() as session:
        session.add(Entitlement(user_id=actor, product_id='jiahe_yearly', store='alipay', expires_at=int(time.time()+86400), original_transaction_id='family-test-order'))
        session.commit()
    return actor, auth_headers


def bind(client, headers, name='家人', member='member-1'):
    return client.post('/api/v1/subscription/family-seats/bind', headers=headers, params={'member_name': name, 'member_user_id': member})


def test_seats_survive_restart_and_are_exported(client, family, settings):
    actor, headers = family
    assert bind(client, headers).status_code == 200
    with TestClient(create_app(settings)) as restarted:
        info = restarted.get('/api/v1/subscription/family-seats', headers=headers).json()['data']
        assert info['used_seats'] == 1 and info['available'] == 3
        assert info['members'][0]['access_granted'] is False
        exported = restarted.get('/api/v1/auth/data/export', headers=headers).json()
        assert len(exported['family_seats']) == 1
        removed = restarted.post('/api/v1/subscription/family-seats/unbind', headers=headers, params={'seat_id': info['members'][0]['seat_id']})
        assert removed.status_code == 200 and removed.json()['data']['used_seats'] == 0


def test_duplicate_and_fifth_member_are_rejected(client, family):
    _, headers = family
    assert bind(client, headers).status_code == 200
    assert bind(client, headers).status_code == 409
    for i in range(2,5):
        assert bind(client, headers, member=f'member-{i}').status_code == 200
    assert bind(client, headers, member='fifth').status_code == 400
    assert client.get('/api/v1/subscription/family-seats', headers=headers).json()['data']['used_seats'] == 4


@pytest.mark.parametrize('change', ['expired', 'downgraded', 'removed'])
def test_no_stale_entitlements_after_change(client, family, change):
    actor, headers = family
    assert bind(client, headers).status_code == 200
    with client.app.state.session_factory() as session:
        row = session.get(Entitlement, actor)
        if change == 'expired': row.expires_at = int(time.time()-1)
        elif change == 'downgraded': row.product_id = 'yiyang_yearly'
        else: session.delete(row)
        session.commit()
    response = client.get('/api/v1/subscription/family-seats', headers=headers).json()['data']
    assert response['active'] is False and response['available'] == 0
    assert bind(client, headers, member='new-member').status_code == 400
    assert client.post('/api/v1/subscription/family-seats/unbind', headers=headers, params={'member_user_id':'member-1'}).status_code == 200


def test_anonymous_and_cross_account_access_rejected(client, family):
    actor, headers = family
    assert client.get('/api/v1/subscription/family-seats').status_code == 401
    token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    other = {'Authorization': f'Bearer {token}'}
    assert client.get('/api/v1/subscription/family-seats', headers=other, params={'user_id':actor}).status_code == 403
    assert bind(client, other).status_code == 400


def test_invalid_name_and_ambiguous_unbind_are_rejected(client, family):
    _, headers = family
    assert bind(client, headers, name='   ').status_code == 422
    assert bind(client, headers).status_code == 200
    assert client.post('/api/v1/subscription/family-seats/unbind', headers=headers, params={'member_user_id':'member-1','member_index':0}).status_code == 400


def test_deletion_erases_own_seats(client, family):
    _, headers = family
    assert bind(client, headers).status_code == 200
    response = client.delete('/api/v1/auth/account', headers=headers)
    assert response.status_code == 200
    assert response.json()['deleted_rows']['family_seats'] == 1
    with client.app.state.session_factory() as session:
        assert session.scalar(select(func.count()).select_from(FamilySeat)) == 0


def test_registered_family_size_matches_owner_plus_guest_seats():
    from app.entitlements import get_registry, tier_for_product
    from app.router.subscription import SUBSCRIPTION_PLANS
    assert get_registry()['tiers']['family']['collaboration']['family_members'] == SUBSCRIPTION_PLANS['jiahe']['family_seats'] + 1
    assert tier_for_product('jiahe_yearly') == tier_for_product('jiahe_monthly') == 'family'
