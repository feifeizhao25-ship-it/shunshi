from unittest.mock import AsyncMock, Mock

import pytest
from app.services import apple_receipt


async def verify(monkeypatch, transactions, requested=None):
    response = Mock()
    response.json.return_value = {'status': 0, 'receipt': {'bundle_id': apple_receipt.BUNDLE_ID}, 'latest_receipt_info': transactions}
    http = AsyncMock()
    http.__aenter__.return_value = http
    http.post.return_value = response
    monkeypatch.setattr(apple_receipt.httpx, 'AsyncClient', lambda **kwargs: http)
    return await apple_receipt._verify_with_apple('https://apple.test', 'receipt', requested)


def txn(identifier, expiry, **extra):
    return {'transaction_id': identifier, 'original_transaction_id': 'original', 'expires_date_ms': str(expiry), 'product_id': 'com.shunshi.yiyang.yearly', **extra}


@pytest.mark.asyncio
async def test_unordered_transactions_choose_latest_and_platform_identifier(monkeypatch):
    result = await verify(monkeypatch, [txn('old', 100), txn('new', 200)])
    assert result['valid'] is True and result['transaction_id'] == 'new'
    assert result['expires_at_ms'] == 200


@pytest.mark.asyncio
async def test_arbitrary_client_identifier_is_rejected(monkeypatch):
    result = await verify(monkeypatch, [txn('actual', 200)], 'forged')
    assert result['valid'] is False


@pytest.mark.asyncio
async def test_original_identifier_selects_latest_platform_transaction(monkeypatch):
    result = await verify(monkeypatch, [txn('old', 100), txn('new', 200)], 'original')
    assert result['valid'] is True and result['transaction_id'] == 'new'


@pytest.mark.asyncio
@pytest.mark.parametrize('records', [[], [txn('new', 200, cancellation_date_ms='150')], [txn('new', 200, expires_date_ms=None)]])
async def test_missing_or_revoked_receipt_is_not_valid(monkeypatch, records):
    assert (await verify(monkeypatch, records))['valid'] is False
