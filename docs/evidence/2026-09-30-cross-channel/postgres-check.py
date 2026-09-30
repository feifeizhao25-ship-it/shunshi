"""Run the production DB concurrency regression against a disposable local PG DB.

From backend: PYTHONPATH=. python ../docs/evidence/2026-09-30-cross-channel/postgres-check.py
Create the empty cross_channel database and cross_channel_ci role first.
Only payment provider order creation is stubbed; DB sessions/locks are real.
"""
from tests import conftest
from pytest import MonkeyPatch
from fastapi.testclient import TestClient
from app.config import Settings
from app.main import create_app
from tests.test_domestic_payment_recovery import test_domestic_projection_serializes_with_store_restore

settings = Settings(env='test',
    database_url='postgresql://cross_channel_ci@127.0.0.1:55439/cross_channel',
    redis_url='', jwt_secret='fixture-only-cross-channel-secret-with-48-characters',
    model_router_url='', sms_provider_url='', sms_provider_token='', payment_callback_secret='')
with MonkeyPatch.context() as patch:
    conftest.stub_external_alipay_order_creation.__wrapped__(patch)
    with TestClient(create_app(settings)) as client:
        for existing in (False, True):
            headers = conftest.auth_headers.__wrapped__(client)
            test_domestic_projection_serializes_with_store_restore(client, headers, existing)
            print(f'PASS PostgreSQL 17 cross-channel lock; existing entitlement = {existing}')
