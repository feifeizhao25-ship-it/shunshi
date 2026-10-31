"""Skills（/api/v1/skills、/api/v1/core-skills）是对话之外的另一组 AI 出口，红线同样适用。

- 响应带「AI 生成」标识；
- 编排器自己那份简易安全检测只认 6 个危机词，改为复用安全守卫；输出也要过守卫（不给剂量/服法/配伍）；
- 未满 16 周岁不提供（和对话一致）。
"""

import time
from datetime import date

import pytest

from app.router import core_skills as core_router
from app.router import skills as skills_router
from app.skills.orchestrator import OrchestrationStatus, SkillExecutionResult, SkillOrchestrator, SkillResult
from app.skills.skill_registry import skill_registry


@pytest.fixture()
def authed(client):
    login = client.post("/api/v1/auth/guest-login")
    return {"Authorization": f"Bearer {login.json()['access_token']}"}


def _fake_result():
    return SkillExecutionResult(
        status=OrchestrationStatus.SUCCESS, skills_executed=[], final_response="今晚泡泡脚",
        total_tokens=1, total_latency_ms=1,
    )


def test_skills_execute_response_is_labelled(client, authed, monkeypatch):
    class Fake:
        async def execute(self, **kw):
            return _fake_result()

    monkeypatch.setattr(skills_router, "get_orchestrator", lambda: Fake())
    r = client.post("/api/v1/skills/execute", headers=authed, json={"message": "睡不好怎么办"})
    assert r.status_code == 200, r.text
    assert r.json()["ai_generated"] is True and r.json()["ai_label"] == "AI 生成"
    assert "不是真人" in r.json()["ai_notice"]


def test_core_skills_responses_are_labelled(client, authed, monkeypatch):
    class Out:
        def to_dict(self):
            return {"skill": "SleepWindDown", "text": "睡前泡脚", "success": True}

    async def fake_execute(skill, data):
        return Out()

    monkeypatch.setattr(core_router.core_skill_executor, "execute", fake_execute)
    r = client.post("/api/v1/core-skills/chat", headers=authed, json={"message": "睡不好"})
    assert r.status_code == 200, r.text
    assert r.json()["ai_generated"] is True and r.json()["ai_label"] == "AI 生成"
    r = client.post("/api/v1/core-skills/run", headers=authed, json={"skill": "SleepWindDown"})
    assert r.status_code == 200, r.text
    assert r.json()["ai_generated"] is True


def test_orchestrator_uses_the_shared_crisis_detection():
    blocked = SkillOrchestrator()._check_safety("活着好累，我想一了百了", {})
    assert blocked and blocked["flag"] == "crisis" and "12356" in blocked["response"]


@pytest.mark.asyncio
async def test_orchestrator_output_with_dosage_is_replaced():
    orchestrator = SkillOrchestrator()
    skill_id = skill_registry.all_skill_ids()[0]
    skill = skill_registry.get(skill_id)

    async def fake_single(skill_def, message, context):
        return SkillResult(
            skill_id=skill_id, skill_name=skill.name, category=skill.category, status="success",
            model="m", tokens_used=1, latency_ms=1, output={"text": "黄芪每次9克，煎服。"},
        )

    orchestrator._execute_single_skill = fake_single
    result = await orchestrator.execute("给我一份计划", {}, skill_ids=[skill_id], allow_premium=True)
    assert "煎服" not in result.final_response
    assert "咨询" in result.final_response


def test_under_16_cannot_use_skills(client, authed):
    today = date.today()
    born = today.replace(year=today.year - 10).isoformat()
    assert client.post("/api/v1/settings/age-profile", headers=authed, json={"birth_date": born}).status_code == 200
    r = client.post("/api/v1/skills/execute", headers=authed, json={"message": "睡不好怎么办"})
    assert r.status_code == 403
    assert "监护人" in r.json()["detail"]
