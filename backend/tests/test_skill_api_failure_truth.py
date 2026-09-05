import pytest
from unittest.mock import AsyncMock
from fastapi import FastAPI
from fastapi.testclient import TestClient
from app.router import skills


def client():
    app = FastAPI()
    app.include_router(skills.router)
    return TestClient(app)


def test_unknown_plan_never_falls_back(monkeypatch):
    orchestrator = AsyncMock()
    monkeypatch.setattr(skills, 'get_orchestrator', lambda: orchestrator)
    response = client().post('/api/v1/skills/daily-plan', json={'user_id': 'u', 'plan_type': 'typo'})
    assert response.status_code == 400
    assert response.json()['detail'] == '不支持的计划类型，请重新选择'
    orchestrator.execute.assert_not_called()


def test_execute_failure_does_not_expose_internal_error(monkeypatch):
    orchestrator = AsyncMock()
    orchestrator.execute.side_effect = RuntimeError('internal token secret')
    monkeypatch.setattr(skills, 'get_orchestrator', lambda: orchestrator)
    response = client().post('/api/v1/skills/execute', json={'user_id': 'u', 'message': '如何改善睡眠'})
    assert response.status_code == 503
    assert response.json()['detail'] == '建议生成服务暂时不可用，请稍后重试'


def test_missing_registered_plan_is_unavailable(monkeypatch):
    monkeypatch.setattr(skills.skill_registry, 'get', lambda _: None)
    response = client().post('/api/v1/skills/daily-plan', json={'user_id': 'u', 'plan_type': 'sleep'})
    assert response.status_code == 503
    assert response.json()['detail'] == '所选计划暂时不可用，请稍后重试'


def test_explicit_invalid_skill_is_rejected(monkeypatch):
    orchestrator = AsyncMock()
    monkeypatch.setattr(skills, 'get_orchestrator', lambda: orchestrator)
    response = client().post('/api/v1/skills/execute', json={'user_id': 'u', 'message': '睡眠', 'skill_ids': ['missing-skill']})
    assert response.status_code == 400
    orchestrator.execute.assert_not_called()


@pytest.mark.asyncio
async def test_explicit_skill_is_executed_instead_of_classifier_choice():
    from unittest.mock import MagicMock
    from app.skills.orchestrator import SkillOrchestrator
    from app.skills.skill_registry import SkillDefinition
    orchestrator = SkillOrchestrator()
    selected = SkillDefinition(skill_id='selected', category='planning', name='计划', description='测试')
    orchestrator._registry = MagicMock()
    orchestrator._registry.get.return_value = selected
    orchestrator._match_skills = MagicMock(side_effect=AssertionError('不得重新猜测指定能力'))
    orchestrator._execute_single_skill = AsyncMock(return_value=MagicMock(status='failed'))
    orchestrator._assemble_result = MagicMock(return_value='result')
    result = await orchestrator.execute('日常计划', {}, skill_ids=['selected'])
    assert result == 'result'
    assert orchestrator._execute_single_skill.call_args.args[0] is selected


def test_crisis_has_priority_over_medical_and_registry_availability():
    from unittest.mock import MagicMock
    from app.skills.orchestrator import SkillOrchestrator
    orchestrator = SkillOrchestrator()
    orchestrator._registry = MagicMock()
    orchestrator._registry.search.return_value = []
    crisis = orchestrator._check_safety('治疗没有用，我不想活', {})
    assert crisis['flag'] == 'crisis'
    assert '12356' in crisis['response']
    assert '400-161' not in crisis['response']
    assert orchestrator._check_safety('请给我开药', {})['flag'] == 'medical'
