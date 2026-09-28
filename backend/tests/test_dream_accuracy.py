from datetime import date, datetime
import uuid

import pytest

from app.db.database import Session as ProductSession
from app.models.wellness_tracking import DreamLog
from app.security import verify_token


@pytest.mark.parametrize('description', ['梦见火焰和烈火燃烧', '梦见洪水和溺水很可怕', '梦见战斗被追赶逃跑', '梦见在森林中看绿色植物', '梦见自己飞翔和鸟一起飞', '梦见宴席上吃很多食物', '梦见陌生城市和朋友'])
def test_dream_content_never_prescribes_or_diagnoses(client, auth_headers, description):
    response = client.post('/api/v1/ai-dream/log', headers=auth_headers, json={'dream_description': description})
    assert response.status_code == 200
    analysis = response.json()['data']['entry']['tcm_analysis']
    assert analysis['organ'] is None
    assert analysis['diagnostic'] is False
    assert analysis['remedies'] == [] and analysis['acupoints'] == []
    assert analysis['evidence_status'] == 'insufficient_for_diagnosis'
    assert 'organ_en' not in analysis


@pytest.mark.parametrize('path', ['meanings', 'quality-guide', 'sleep-tips'])
def test_reference_endpoints_do_not_reintroduce_diagnosis(client, auth_headers, path):
    response = client.get(f'/api/v1/ai-dream/{path}', headers=auth_headers)
    assert response.status_code == 200
    assert response.json()['data']['diagnostic'] is False
    for term in ['六味地黄丸', '酸枣仁', '温胆汤', '脏腑长期失调', '心火旺盛', '肾气不足']:
        assert term not in response.text


def test_history_does_not_republish_legacy_organ_claim(client, auth_headers, settings):
    actor = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    with ProductSession() as db:
        db.add(DreamLog(id=uuid.uuid4(), user_id=actor, description='旧梦境记录', date=date.today(), logged_at=datetime.now(), tcm_analysis={'organ': '肾', 'remedies': ['六味地黄丸']}))
        db.commit()
    data = client.get(f'/api/v1/ai-dream/history/{actor}', headers=auth_headers).json()['data']
    assert data['dreams'][0]['organ'] is None
    assert data['dreams'][0]['diagnostic'] is False


def test_dream_requires_login_and_rejects_foreign_owner(client, auth_headers):
    body = {'dream_description': '梦见一座陌生城市'}
    assert client.post('/api/v1/ai-dream/log', json=body).status_code == 401
    assert client.post('/api/v1/ai-dream/log', headers=auth_headers, json={**body, 'user_id': 'another-user'}).status_code == 403
    assert client.get('/api/v1/ai-dream/history/another-user', headers=auth_headers).status_code == 403


@pytest.mark.parametrize('invalid', [{'sleep_time': '26:70'}, {'wake_time': '明天'}, {'dream_quality': 'diagnosis'}, {'dream_description': '梦' * 10001}])
def test_invalid_dream_inputs_are_rejected(client, auth_headers, invalid):
    assert client.post('/api/v1/ai-dream/log', headers=auth_headers, json={'dream_description': '梦见在陌生城市行走', **invalid}).status_code == 422
