"""
Model Fallback Chain 单元测试

覆盖:
- 主模型成功 → 直接返回
- 主模型超时 → fallback 到备用 provider
- 主模型返回空 → fallback
- 两个 provider 都失败 → 模板兜底
- 预算超限 → 降级到 fallback_model
- safety block → 不 fallback，返回安全响应
- 超时 30 秒

运行: pytest test/test_model_fallback.py -v
"""

import asyncio
import os
import sys
import time

import pytest
from unittest.mock import AsyncMock, patch, MagicMock

# 确保项目根目录在 path 中
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.llm.fallback import (
    ModelFallbackChain,
    FallbackReason,
    FallbackResult,
    FALLBACK_TEMPLATES,
    _SafetyBlockError,
    _EmptyResponseError,
)
from app.llm.siliconflow import ChatMessage, MessageRole


# ==================== Fixtures ====================

@pytest.fixture
def chain():
    """创建 FallbackChain 实例"""
    return ModelFallbackChain()


@pytest.fixture
def sample_messages():
    """样本消息列表"""
    return [
        ChatMessage(role=MessageRole.SYSTEM, content="你是顺时。"),
        ChatMessage(role=MessageRole.USER, content="你好"),
    ]


def _mock_response(content="测试回复", tokens_in=10, tokens_out=20):
    """创建 mock 的 ChatCompletionResponse"""
    mock_resp = MagicMock()
    mock_resp.choices = [{"message": {"content": content}}]
    mock_resp.usage = MagicMock()
    mock_resp.usage.prompt_tokens = tokens_in
    mock_resp.usage.completion_tokens = tokens_out
    mock_resp.usage.total_tokens = tokens_in + tokens_out
    return mock_resp


# ==================== 1. 主模型成功 → 直接返回 ====================

@pytest.mark.asyncio
async def test_primary_success(chain, sample_messages):
    """主模型成功时直接返回，无 fallback"""
    mock_resp = _mock_response("你好！有什么养生问题吗？")

    with patch("app.llm.fallback._get_provider_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.chat_completion.return_value = mock_resp
        mock_get_client.return_value = mock_client

        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
        )

    assert result.success is True
    assert result.provider == "siliconflow"
    assert result.model == "deepseek-v3.2"
    assert result.response_text == "你好！有什么养生问题吗？"
    assert result.fallback_reason is None
    assert result.fallback_from is None
    assert result.tokens_in == 10
    assert result.tokens_out == 20


# ==================== 2. 主模型超时 → fallback 到备用 provider ====================

@pytest.mark.asyncio
async def test_primary_timeout_fallback(chain, sample_messages):
    """主模型超时，自动 fallback 到备用 provider"""
    mock_resp_openrouter = _mock_response("OpenRouter 回复")

    call_count = {"n": 0}

    def mock_get_client(provider_name):
        mock_client = AsyncMock()
        if provider_name == "siliconflow":
            mock_client.chat_completion.side_effect = asyncio.TimeoutError()
        elif provider_name == "openrouter":
            mock_client.chat_completion.return_value = mock_resp_openrouter
        return mock_client

    with patch("app.llm.fallback._get_provider_client", side_effect=mock_get_client):
        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
        )

    assert result.success is True
    assert result.provider == "openrouter"
    assert result.model == "deepseek-v3.2"
    assert result.fallback_reason == FallbackReason.TIMEOUT
    assert result.fallback_from == "siliconflow:deepseek-v3.2"
    assert "siliconflow:deepseek-v3.2" in result.tried_providers


# ==================== 3. 主模型返回空 → fallback ====================

@pytest.mark.asyncio
async def test_empty_response_fallback(chain, sample_messages):
    """主模型返回空内容，自动 fallback"""
    # 第一个 provider 返回空 choices（content 为空字符串）
    mock_empty_resp = MagicMock()
    mock_empty_resp.choices = [{"message": {"content": ""}}]
    mock_empty_resp.usage = MagicMock()
    mock_empty_resp.usage.prompt_tokens = 10
    mock_empty_resp.usage.completion_tokens = 0

    mock_good_resp = _mock_response("备用回复")

    call_count = {"n": 0}

    def mock_get_client(provider_name):
        mock_client = AsyncMock()
        if provider_name == "siliconflow":
            mock_client.chat_completion.return_value = mock_empty_resp
        elif provider_name == "openrouter":
            mock_client.chat_completion.return_value = mock_good_resp
        return mock_client

    with patch("app.llm.fallback._get_provider_client", side_effect=mock_get_client):
        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
        )

    assert result.success is True
    assert result.provider == "openrouter"
    assert result.fallback_reason == FallbackReason.EMPTY_RESPONSE
    assert result.fallback_from == "siliconflow:deepseek-v3.2"


# ==================== 4. 两个 provider 都失败 → 模板兜底 ====================

@pytest.mark.asyncio
async def test_all_providers_fail_template_fallback(chain, sample_messages):
    """所有 provider 都失败，使用模板兜底回复"""
    def mock_get_client(provider_name):
        mock_client = AsyncMock()
        mock_client.chat_completion.side_effect = Exception("API 错误: 500")
        return mock_client

    with patch("app.llm.fallback._get_provider_client", side_effect=mock_get_client):
        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
        )

    assert result.success is True
    assert result.provider == "template"
    assert result.model == "template"
    assert result.response_text == FALLBACK_TEMPLATES["cn"]["default"]
    assert len(result.tried_providers) >= 2


# ==================== 5. 预算超限 → 降级到 fallback_model ====================

@pytest.mark.asyncio
async def test_budget_exceeded_downgrade(chain, sample_messages):
    """预算超限时，fallback_model 被添加到候选列表"""
    mock_resp = _mock_response("降级模型回复")

    # mock budget check to return should_downgrade=True
    with patch("app.llm.fallback._get_provider_client") as mock_get_client, \
         patch("app.llm.audit.get_llm_audit_logger") as mock_audit:
        mock_client = AsyncMock()
        mock_client.chat_completion.return_value = mock_resp
        mock_get_client.return_value = mock_client

        mock_budget = {
            "within_budget": False,
            "should_downgrade": True,
            "fallback_model": "glm-4.6",
        }
        mock_audit_instance = MagicMock()
        mock_audit_instance.check_budget.return_value = mock_budget
        mock_audit.return_value = mock_audit_instance

        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
            user_tier="free",
        )

    # Primary model succeeds first (even though budget exceeded, primary is tried first)
    assert result.success is True
    assert result.model == "deepseek-v3.2"

    # Now test: primary fails → fallback_model (glm-4.6) succeeds
    call_log = []

    def mock_get_client_v2(provider_name):
        mock_c = AsyncMock()
        if provider_name == "siliconflow":
            def sf_side_effect(model, **kwargs):
                call_log.append(f"sf:{model}")
                if model == "deepseek-v3.2":
                    raise Exception("API 错误")
                elif model == "glm-4.6":
                    return _mock_response("降级模型回复")
            mock_c.chat_completion.side_effect = sf_side_effect
        elif provider_name == "openrouter":
            # Should not be reached
            mock_c.chat_completion.side_effect = Exception("should not reach")
        return mock_c

    with patch("app.llm.fallback._get_provider_client", side_effect=mock_get_client_v2), \
         patch("app.llm.audit.get_llm_audit_logger") as mock_audit2:
        mock_audit_instance2 = MagicMock()
        mock_audit_instance2.check_budget.return_value = {
            "within_budget": False,
            "should_downgrade": True,
            "fallback_model": "glm-4.6",
        }
        mock_audit2.return_value = mock_audit_instance2

        result2 = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
            user_tier="free",
        )

    assert result2.success is True
    assert result2.model == "glm-4.6"
    assert result2.provider == "siliconflow"
    assert "siliconflow:deepseek-v3.2" in result2.tried_providers
    assert "siliconflow:glm-4.6" in result2.tried_providers


# ==================== 6. Safety block → 不 fallback ====================

@pytest.mark.asyncio
async def test_safety_block_no_fallback(chain, sample_messages):
    """Safety block 时不 fallback，直接返回安全响应"""
    with patch("app.llm.fallback._get_provider_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.chat_completion.side_effect = _SafetyBlockError(
            "内容被安全策略阻断",
            "这个话题涉及到医疗建议，建议您咨询专业医生。",
        )
        mock_get_client.return_value = mock_client

        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
        )

    assert result.success is True
    assert result.provider == "siliconflow"
    assert result.response_text == "这个话题涉及到医疗建议，建议您咨询专业医生。"
    assert result.fallback_reason == FallbackReason.SAFETY_BLOCK
    # Only tried one provider
    assert len(result.tried_providers) == 1


# ==================== 7. 超时 30 秒 ====================

@pytest.mark.asyncio
async def test_timeout_30_seconds(chain, sample_messages):
    """验证每个 provider 调用超时为 30 秒"""
    mock_resp = _mock_response("回复")

    with patch("app.llm.fallback._get_provider_client") as mock_get_client, \
         patch("app.llm.fallback.asyncio.wait_for") as mock_wait_for:
        # wait_for should be called with timeout=30
        async def fake_wait_for(coro, timeout=None):
            assert timeout == 30, f"Expected timeout=30, got {timeout}"
            return await coro

        mock_client = AsyncMock()
        mock_client.chat_completion.return_value = mock_resp
        mock_get_client.return_value = mock_client
        mock_wait_for.side_effect = fake_wait_for

        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
        )

    assert result.success is True


# ==================== 8. 模板选择 ====================

def test_template_selection_by_skill(chain):
    """根据 skill_chain 选择对应模板"""
    # Diet skill
    text = chain._get_template(["diet"])
    assert text == FALLBACK_TEMPLATES["cn"]["diet"]

    # Sleep skill
    text = chain._get_template(["sleep"])
    assert text == FALLBACK_TEMPLATES["cn"]["sleep"]

    # Unknown skill → default
    text = chain._get_template(["unknown_skill"])
    assert text == FALLBACK_TEMPLATES["cn"]["default"]

    # Empty skill_chain → default
    text = chain._get_template(None)
    assert text == FALLBACK_TEMPLATES["cn"]["default"]

    text = chain._get_template([])
    assert text == FALLBACK_TEMPLATES["cn"]["default"]


# ==================== 9. Fallback chain 配置 ====================

def test_fallback_chain_config(chain):
    """验证 fallback chain 配置正确"""
    assert chain.fallback_chain == {
        "siliconflow": ["openrouter"],
        "openrouter": ["siliconflow"],
    }
    assert chain.timeout_seconds == 30
    assert chain.max_retries == 2


# ==================== 10. rate limit 错误 → 正确标记 ====================

@pytest.mark.asyncio
async def test_rate_limit_fallback(chain, sample_messages):
    """429 rate limit 错误标记为 RATE_LIMIT"""
    mock_good_resp = _mock_response("OpenRouter 回复")

    def mock_get_client(provider_name):
        mock_client = AsyncMock()
        if provider_name == "siliconflow":
            mock_client.chat_completion.side_effect = Exception("API 错误: 429")
        elif provider_name == "openrouter":
            mock_client.chat_completion.return_value = mock_good_resp
        return mock_client

    with patch("app.llm.fallback._get_provider_client", side_effect=mock_get_client):
        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
        )

    assert result.success is True
    assert result.provider == "openrouter"
    assert result.fallback_reason == FallbackReason.RATE_LIMIT


# ==================== 11. 审计记录 ====================

@pytest.mark.asyncio
async def test_fallback_audit_recorded(chain, sample_messages):
    """Fallback 事件应记录到审计日志"""
    mock_good_resp = _mock_response("OpenRouter 回复")

    def mock_get_client(provider_name):
        mock_client = AsyncMock()
        if provider_name == "siliconflow":
            mock_client.chat_completion.side_effect = asyncio.TimeoutError()
        elif provider_name == "openrouter":
            mock_client.chat_completion.return_value = mock_good_resp
        return mock_client

    with patch("app.llm.fallback._get_provider_client", side_effect=mock_get_client), \
         patch("app.llm.audit.get_llm_audit_logger") as mock_get_audit, \
         patch("app.llm.audit.create_audit") as mock_create_audit:
        mock_audit_logger = MagicMock()
        mock_get_audit.return_value = mock_audit_logger

        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
            skill_chain=["diet"],
        )

    # create_audit should have been called (inside _record_fallback_audit)
    assert result.success is True
    assert result.fallback_reason == FallbackReason.TIMEOUT
    mock_create_audit.assert_called()


# ==================== 12. FallbackResult 数据结构 ====================

def test_fallback_result_dataclass():
    """验证 FallbackResult 数据类"""
    result = FallbackResult(
        success=True,
        provider="siliconflow",
        model="deepseek-v3.2",
        response_text="测试",
        tokens_in=10,
        tokens_out=20,
        latency_ms=100.0,
        tried_providers=["siliconflow:deepseek-v3.2"],
    )

    assert result.success is True
    assert result.fallback_reason is None
    assert result.fallback_from is None

    result2 = FallbackResult(
        success=True,
        provider="openrouter",
        model="glm-4.6",
        response_text="兜底回复",
        tokens_in=0,
        tokens_out=0,
        latency_ms=5000.0,
        tried_providers=["siliconflow:deepseek-v3.2", "openrouter:deepseek-v3.2"],
        fallback_reason=FallbackReason.TIMEOUT,
        fallback_from="siliconflow:deepseek-v3.2",
    )

    assert result2.fallback_reason == FallbackReason.TIMEOUT
    assert result2.fallback_from == "siliconflow:deepseek-v3.2"


# ==================== 13. 空消息列表 (空字符串内容) ====================

@pytest.mark.asyncio
async def test_whitespace_only_response_fallback(chain, sample_messages):
    """只有空白的响应也应该触发 fallback"""
    mock_blank_resp = MagicMock()
    mock_blank_resp.choices = [{"message": {"content": "   "}}]
    mock_blank_resp.usage = MagicMock()
    mock_blank_resp.usage.prompt_tokens = 10
    mock_blank_resp.usage.completion_tokens = 3

    mock_good_resp = _mock_response("正常回复")

    def mock_get_client(provider_name):
        mock_client = AsyncMock()
        if provider_name == "siliconflow":
            mock_client.chat_completion.return_value = mock_blank_resp
        elif provider_name == "openrouter":
            mock_client.chat_completion.return_value = mock_good_resp
        return mock_client

    with patch("app.llm.fallback._get_provider_client", side_effect=mock_get_client):
        result = await chain.chat(
            user_id="test-user",
            messages=sample_messages,
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
        )

    assert result.success is True
    assert result.provider == "openrouter"
    assert result.fallback_reason == FallbackReason.EMPTY_RESPONSE
