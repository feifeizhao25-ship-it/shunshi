"""境内路由：跑量、边界、备选、超时参数、日帽、内容安全、密钥名。"""

import asyncio
import json

import httpx

from app.llm import cost_cap, domestic_gateway as gw
from app.llm import domestic_route
from app.llm.guardrail import sign
from app.safety.config import HEALTH_BOUNDARY_REPLY


def _mock(handler):
    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


def _ok(text, model="deepseek-flash"):
    return httpx.Response(
        200,
        json={
            "choices": [{"message": {"role": "assistant", "content": text}}],
            "model": model,
            "usage": {"prompt_tokens": 10, "completion_tokens": 4},
        },
    )


def test_product_keys_are_not_the_openclaw_names():
    names = {name for provider in gw.PROVIDERS for name in provider.key_vars}
    assert "SHUNSHI_DEEPSEEK_API_KEY" in names
    assert "SHUNSHI_DASHSCOPE_API_KEY" in names
    assert "SHUNSHI_ARK_API_KEY" in names
    assert "DEEPSEEK_API_KEY" not in names
    assert "DASHSCOPE_API_KEY" not in names
    assert "ARK_API_KEY" not in names
    assert {httpx.URL(provider.endpoint).host for provider in gw.PROVIDERS} <= gw.DOMESTIC_HOSTS


def test_bulk_question_uses_deepseek_flash_then_doubao_then_qwen():
    hosts = []

    def handler(request):
        hosts.append((request.url.host, json.loads(request.content)["model"]))
        if request.url.host == "api.deepseek.com":
            return httpx.Response(503)
        if request.url.host == "ark.cn-beijing.volces.com":
            return httpx.Response(500)
        return _ok("早点睡", "qwen-plus")

    env = {
        "SHUNSHI_DEEPSEEK_API_KEY": "dk",
        "SHUNSHI_ARK_API_KEY": "ak",
        "SHUNSHI_DASHSCOPE_API_KEY": "qk",
    }
    text = asyncio.run(
        gw.complete(
            [{"role": "user", "content": "今晚想几点睡"}],
            client=_mock(handler),
            env=env,
        )
    )
    assert text == "早点睡"
    assert hosts[0][0] == "api.deepseek.com" and hosts[0][1] == "deepseek-flash"
    assert hosts[1][0] == "ark.cn-beijing.volces.com"
    assert hosts[1][1] == "doubao-seed-2-0-lite-260428"
    assert hosts[2] == ("dashscope.aliyuncs.com", "qwen-plus")


def test_symptom_question_does_not_call_a_provider():
    def handler(request):
        raise AssertionError(request.url.host)

    text = asyncio.run(
        domestic_route.answer(
            [{"role": "user", "content": "我咳嗽怎么办"}],
            client=_mock(handler),
            env={"SHUNSHI_DEEPSEEK_API_KEY": "dk"},
        )
    )
    assert text == HEALTH_BOUNDARY_REPLY


def test_boundary_question_uses_qwen35_plus():
    seen = []

    def handler(request):
        body = json.loads(request.content)
        seen.append((request.url.host, body["model"], body.get("enable_thinking")))
        return _ok("孕期把午饭时间固定下来就好。", body["model"])

    text = asyncio.run(
        domestic_route.answer(
            [{"role": "user", "content": "孕期作息怎么安排"}],
            client=_mock(handler),
            env={"SHUNSHI_DASHSCOPE_API_KEY": "qk", "SHUNSHI_DEEPSEEK_API_KEY": "dk"},
        )
    )
    assert "午饭" in text
    assert seen[0][0] == "dashscope.aliyuncs.com"
    assert seen[0][1] == "qwen3.5-plus"
    assert seen[0][2] is False


def test_bad_output_is_rewritten_once_then_kept_if_clean():
    calls = {"n": 0}

    def handler(request):
        calls["n"] += 1
        body = json.loads(request.content)
        if body["model"] == "deepseek-flash":
            return _ok("六味地黄丸每次 9 克，可长期服用。")
        return _ok("早点睡，晚饭清淡一点。")

    text = asyncio.run(
        domestic_route.answer(
            [{"role": "user", "content": "晚上吃完饭怎么安排"}],
            client=_mock(handler),
            env={"SHUNSHI_DEEPSEEK_API_KEY": "dk", "SHUNSHI_DASHSCOPE_API_KEY": "qk"},
        )
    )
    assert "9 克" not in text
    assert "可长期服用" not in text
    assert "早点睡" in text
    assert calls["n"] == 2


def test_second_violation_becomes_the_fixed_reply():
    def handler(request):
        return _ok("这个丸每次 9 克，可长期服用，有疗效。")

    text = asyncio.run(
        domestic_route.answer(
            [{"role": "user", "content": "晚上吃完饭怎么安排"}],
            client=_mock(handler),
            env={"SHUNSHI_DEEPSEEK_API_KEY": "dk", "SHUNSHI_DASHSCOPE_API_KEY": "qk"},
        )
    )
    assert text == HEALTH_BOUNDARY_REPLY


def test_daily_cap_stops_further_calls():
    cost_cap.reset()
    seen = []

    def handler(request):
        seen.append(request.url.host)
        return _ok("早点睡")

    # 帽设在「一次最坏估计」和「一次实际花费 + 下一次最坏估计」之间，第一问能问，第二问被拦住。
    env = {"SHUNSHI_DEEPSEEK_API_KEY": "dk", "SHUNSHI_USER_DAILY_CAP_CNY": "0.00136"}
    first = asyncio.run(
        domestic_route.answer(
            [{"role": "user", "content": "今晚想几点睡"}],
            user_id="cap-user",
            client=_mock(handler),
            env=env,
        )
    )
    second = asyncio.run(
        domestic_route.answer(
            [{"role": "user", "content": "明天呢"}],
            user_id="cap-user",
            client=_mock(handler),
            env=env,
        )
    )
    assert first == "早点睡"
    assert second == domestic_route.SAFE_UNAVAILABLE
    assert seen == ["api.deepseek.com"]
    cost_cap.reset()


def test_guardrail_hit_discards_the_draft():
    def handler(request):
        if request.url.host == "green-cip.cn-beijing.aliyuncs.com":
            return httpx.Response(200, json={"Code": 200, "Data": {"Labels": "ad", "Reason": "{\"riskLevel\":\"high\"}"}})
        return _ok("早点睡")

    env = {
        "SHUNSHI_DEEPSEEK_API_KEY": "dk",
        "SHUNSHI_DASHSCOPE_API_KEY": "qk",
        "SHUNSHI_GUARDRAIL_AK_ID": "akid",
        "SHUNSHI_GUARDRAIL_AK_SECRET": "secret",
    }
    text = asyncio.run(
        domestic_route.answer(
            [{"role": "user", "content": "今晚想几点睡"}],
            client=_mock(handler),
            env=env,
        )
    )
    # 输入已被护栏拦住，不应把模型草稿交出去。
    assert text == HEALTH_BOUNDARY_REPLY


def test_guardrail_signature_changes_when_the_secret_changes():
    params = {"Action": "TextModeration", "Format": "JSON"}
    assert sign(params, "one") != sign(params, "two")


def test_timeout_setting_is_bounded():
    assert gw.llm_timeout({"SHUNSHI_LLM_TIMEOUT_SECONDS": "8"}) == 8
    assert gw.llm_timeout({"SHUNSHI_LLM_TIMEOUT_SECONDS": "999"}) == 60
    assert gw.llm_timeout({}) == 20


def test_offshore_host_is_not_allowed():
    assert gw.host_allowed("api.deepseek.com")
    assert gw.host_allowed("ws.cn-beijing.maas.aliyuncs.com")
    assert not gw.host_allowed("api.openai.com")
    assert not gw.host_allowed("openrouter.ai")
