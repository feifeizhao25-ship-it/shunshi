"""Skills 页的「日常练习」：英文请求得到英文，字段就是客户端解析的那几个。"""
import re

import pytest
from fastapi.testclient import TestClient
from tests.signed_in_client import SignedInClient

from app.main import app
from app.skills.skill_registry import skill_registry

client = TestClient(app)
signed_in = SignedInClient(app)
CJK = re.compile(r"[\u4e00-\u9fff]")
GLOBAL = {"X-App-Market": "global", "Accept-Language": "en-US"}


def test_global_practices_are_english_and_match_what_the_clients_parse():
    body = client.get("/api/v1/skills/practices", headers=GLOBAL).json()
    assert body["locale"] == "en"
    assert body["count"] == len(body["skills"]) >= 5
    for item in body["skills"]:
        assert set(item) >= {"id", "skill_id", "name", "description", "category", "is_premium"}
        assert not CJK.search(item["name"] + item["description"]), item
        assert skill_registry.get(item["skill_id"]) is not None
    # 客户端按这几个 id 配图标
    ids = {i["id"] for i in body["skills"]}
    assert {"sleep_optimization", "focus_improvement", "stress_relief",
            "nutrition_guidance", "mental_reset"} <= ids


def test_domestic_practices_keep_the_chinese_registry_names():
    body = client.get("/api/v1/skills/practices", headers={"X-App-Market": "cn"}).json()
    assert body["locale"] == "zh"
    assert all(CJK.search(i["name"]) for i in body["skills"])


def test_the_internal_catalogue_keeps_its_shape_for_the_domestic_apps_and_admin():
    data = client.get("/api/v1/skills?limit=3").json()
    assert isinstance(data, list) and {"skill_id", "name", "description"} <= set(data[0])


def test_practices_is_not_swallowed_by_the_skill_id_route():
    assert client.get("/api/v1/skills/practices", headers=GLOBAL).status_code == 200


class _FakeResult:
    class status:
        value = "success"
    final_response = "这份内容未通过安全检查"
    skills_executed: list = []
    total_tokens = 0
    total_latency_ms = 0
    safety_flag = "medical"
    follow_up = None


class _FakeOrchestrator:
    seen = None

    async def execute(self, user_message, **kwargs):
        _FakeOrchestrator.seen = user_message
        return _FakeResult()


pytestmark = pytest.mark.signed_in


@pytest.fixture()
def fake_execute(monkeypatch):
    from app.router import skills as skills_router
    from app.skill_access import SkillAccess, get_skill_access

    monkeypatch.setattr(skills_router, "get_orchestrator", lambda: _FakeOrchestrator())
    app.dependency_overrides[get_skill_access] = lambda: SkillAccess("user-001", True)
    yield
    app.dependency_overrides.pop(get_skill_access, None)


def test_english_execute_asks_for_english_and_never_returns_chinese(fake_execute):
    r = signed_in.post(
        "/api/v1/skills/execute",
        headers=GLOBAL,
        json={"user_id": "user-001", "message": "Help me wind down", "skill_ids": ["generate_emotion_mindful_pause"]},
    )
    assert r.status_code == 200, r.text
    assert "Please answer in English" in _FakeOrchestrator.seen
    assert not CJK.search(r.json()["final_response"])
    assert "safety check" in r.json()["final_response"]


def test_chinese_execute_is_untouched(fake_execute):
    r = signed_in.post(
        "/api/v1/skills/execute",
        headers={"X-App-Market": "cn"},
        json={"user_id": "user-001", "message": "请给我建议", "skill_ids": ["generate_emotion_mindful_pause"]},
    )
    assert r.json()["final_response"] == "这份内容未通过安全检查"
    assert "English" not in _FakeOrchestrator.seen
