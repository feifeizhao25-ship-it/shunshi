from unittest.mock import AsyncMock, MagicMock
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from app.config import Settings
from app.deps import get_settings
from app.skill_access import SkillAccess, get_skill_access
from app.router import skills, core_skills


def client(access=None):
    app = FastAPI()
    app.include_router(skills.router)
    app.include_router(core_skills.router)
    app.dependency_overrides[get_settings] = lambda: Settings(env='test', jwt_secret='test-secret-at-least-thirty-two-characters')
    if access is not None:
        app.dependency_overrides[get_skill_access] = lambda: access
    return TestClient(app)


@pytest.mark.parametrize('path,body', [
    ('/skills/execute', {'user_id': 'u', 'message': '睡眠'}),
    ('/skills/daily-plan', {'user_id': 'u', 'plan_type': 'light'}),
    ('/core-skills/run', {'user_id': 'u', 'skill': 'DailyRhythmPlan'}),
    ('/core-skills/chat', {'user_id': 'u', 'message': '睡不着'}),
    ('/core-skills/batch', [{'user_id': 'u', 'skill': 'DailyRhythmPlan'}]),
])
def test_execution_requires_login(path, body):
    assert client().post('/api/v1' + path, json=body).status_code == 401


def test_cannot_impersonate_another_account(monkeypatch):
    executor = AsyncMock()
    monkeypatch.setattr(core_skills.core_skill_executor, 'execute', executor)
    response = client(SkillAccess('u', True)).post('/api/v1/core-skills/run', json={'user_id': 'victim', 'skill': 'DailyRhythmPlan'})
    assert response.status_code == 403
    executor.assert_not_called()


def test_claimed_premium_in_context_does_not_grant_access(monkeypatch):
    executor = AsyncMock()
    monkeypatch.setattr(core_skills.core_skill_executor, 'execute', executor)
    response = client(SkillAccess('u', False)).post('/api/v1/core-skills/run', json={'user_id': 'u', 'skill': 'BodyConstitutionLite', 'user_context': {'is_premium': True}})
    assert response.status_code == 403
    executor.assert_not_called()


def test_batch_is_validated_before_any_paid_operation(monkeypatch):
    executor = AsyncMock()
    monkeypatch.setattr(core_skills.core_skill_executor, 'execute', executor)
    response = client(SkillAccess('u', False)).post('/api/v1/core-skills/batch', json=[{'user_id': 'u', 'skill': 'DailyRhythmPlan'}, {'user_id': 'u', 'skill': 'FamilyCareDigest'}])
    assert response.status_code == 403
    executor.assert_not_called()


def test_domestic_skill_forces_chinese_locale(monkeypatch):
    executor = AsyncMock(return_value=MagicMock(to_dict=lambda: {'text': '测试'}))
    monkeypatch.setattr(core_skills.core_skill_executor, 'execute', executor)
    response = client(SkillAccess('u', True)).post('/api/v1/core-skills/run', json={'user_id': 'u', 'skill': 'DailyRhythmPlan', 'locale': 'en-US'})
    assert response.status_code == 200
    assert executor.call_args.args[1].locale == 'zh-CN'


@pytest.mark.parametrize('message,expected', [('睡不着', 'SleepWindDown'), ('节气', 'SolarTermGuide'), ('压力大', 'MoodFirstAid')])
def test_single_keyword_routes_to_the_requested_topic(message, expected):
    assert core_skills._classify_intent(message)[0] == expected
