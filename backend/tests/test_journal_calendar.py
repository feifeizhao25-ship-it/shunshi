from datetime import date
import pytest
from app.router import journal
from app.security import verify_token


@pytest.fixture()
def logged(client, auth_headers, settings, monkeypatch):
    monkeypatch.setattr(journal, '_today', lambda: date(2026, 9, 27))
    client.headers.update(auth_headers)
    user = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    return client, user


def entry(client, day=None):
    body = {'mood': 3, 'energy': 3, 'sleep_quality': 3}
    if day is not None:
        body['date'] = day
    return client.post('/api/v1/journal/entry', json=body)


@pytest.mark.parametrize('day', ['2026-02-30', 'not-a-date', '20260927', '2026-09-28', ''])
def test_invalid_or_future_dates_do_not_create_entries(logged, day):
    client, user = logged
    assert entry(client, day).status_code == 422
    assert client.get(f'/api/v1/journal/entries/{user}').json()['data']['total'] == 0


def test_week_has_seven_days_and_one_entry_is_not_improvement(logged):
    client, user = logged
    assert entry(client, '2026-09-20').status_code == 200  # eighth calendar day
    assert entry(client, '2026-09-21').status_code == 200  # first included day
    result = client.get(f'/api/v1/journal/insights/{user}').json()['data']
    assert result['entries_count'] == 1
    assert result['trend'] == 'stable'
    assert '不足' in result['trend_message']
    assert entry(client).json()['data']['date'] == '2026-09-27'
    assert client.get(f'/api/v1/journal/insights/{user}').json()['data']['entries_count'] == 2


def test_multiple_entries_count_separately_without_inflating_streak(logged):
    client, user = logged
    assert entry(client).status_code == 200
    assert entry(client).status_code == 200
    data = client.get(f'/api/v1/journal/streak/{user}').json()['data']
    assert data['total_entries'] == 2
    assert data['current_streak'] == data['longest_streak'] == 1
