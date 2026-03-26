"""
顺时 AI 模型 Fallback 链
ShunShi AI Model Fallback Chain

当主模型失败时自动切换到备用模型，确保用户始终能得到回复。

Fallback 顺序:
1. primary_provider + primary_model (预算检查)
2. 如果超预算，使用 fallback_model（同 provider）
3. 如果 provider 失败，切换到备用 provider 的同款模型
4. 如果备用 provider 也失败，使用模板兜底回复

作者: Claw 🦅
日期: 2026-03-18
"""

import asyncio
import logging
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, List, Dict, Any

logger = logging.getLogger(__name__)


# ==================== 数据模型 ====================

class FallbackReason(str, Enum):
    """Fallback 原因"""
    TIMEOUT = "timeout"
    RATE_LIMIT = "rate_limit"
    SERVER_ERROR = "server_error"
    EMPTY_RESPONSE = "empty_response"
    SAFETY_BLOCK = "safety_block"
    BUDGET_EXCEEDED = "budget_exceeded"


@dataclass
class FallbackResult:
    """Fallback 调用结果"""
    success: bool
    provider: str
    model: str
    response_text: str
    tokens_in: int
    tokens_out: int
    latency_ms: float
    tried_providers: List[str] = field(default_factory=list)
    fallback_reason: Optional[FallbackReason] = None
    fallback_from: Optional[str] = None  # "provider:model" 格式


# ==================== 兜底模板 ====================

FALLBACK_TEMPLATES = {
    "cn": {
        "default": "抱歉，我暂时有点走神了。请稍后再试试，我会在这里等你。",
        "diet": "关于饮食调养，建议你注意荤素搭配、定时定量，具体情况我可以之后为你详细分析。",
        "emotion": "我感受到你现在可能有些情绪波动。深呼吸几次，给自己一点时间，我在这里陪着你。",
        "sleep": "改善睡眠可以从规律作息开始，每天尽量在固定时间上床。如果持续困扰，建议咨询专业医生。",
        "acupoint": "穴位调理需要专业指导。建议先从简单的穴位按摩开始，如合谷、太冲，每次按压2-3分钟。",
        "tea": "喝茶养生讲究时令。春季宜花茶，夏季宜绿茶，秋季宜青茶，冬季宜红茶。",
        "exercise": "适当运动是最好的养生。建议每天30分钟中等强度活动，如散步、八段锦、太极。",
    },
    "en": {
        "default": "I'm having a moment. Please try again in a bit — I'll be right here.",
    },
}


# ==================== Provider 获取 ====================

def _get_provider_client(provider_name: str):
    """
    根据 provider 名称获取对应的客户端实例。

    不直接 import 在模块顶层，避免循环依赖。
    """
    if provider_name == "siliconflow":
        from app.llm.siliconflow import get_client
        return get_client()
    elif provider_name == "openrouter":
        from app.llm.openrouter import get_openrouter_client
        return get_openrouter_client()
    else:
        raise ValueError(f"未知的 provider: {provider_name}")


# ==================== 审计辅助 ====================

def _record_fallback_audit(
    user_id: str,
    fallback_from_provider: str,
    fallback_from_model: str,
    fallback_to_provider: str,
    fallback_to_model: str,
    fallback_reason: str,
    all_tried_providers: List[str],
    final_status: str,
    latency_ms: float = 0,
    skill_chain: Optional[List[str]] = None,
):
    """记录 fallback 事件到审计日志"""
    try:
        from app.llm.audit import get_llm_audit_logger, create_audit
        audit_logger = get_llm_audit_logger()

        prompt_text = f"[fallback] {fallback_from_provider} → {fallback_to_provider} reason={fallback_reason}"
        audit_record = create_audit(
            user_id=user_id,
            provider=fallback_to_provider,
            model=fallback_to_model,
            prompt=prompt_text,
            latency_ms=int(latency_ms),
            response_status=final_status,
            error_message=f"fallback: {fallback_from_provider}/{fallback_from_model} → {fallback_to_provider}/{fallback_to_model}",
            route_decision=f"fallback_reason={fallback_reason}",
            skill_chain=skill_chain,
        )
        audit_logger.log_call(audit_record)
    except Exception as e:
        logger.warning(f"[FallbackChain] 记录 fallback 审计失败: {e}")


# ==================== Fallback 链核心 ====================

class ModelFallbackChain:
    """
    LLM 调用包装器，支持多 provider 自动 fallback。

    用法:
        chain = ModelFallbackChain()
        result = await chain.chat(
            user_id="test",
            messages=[ChatMessage(role=MessageRole.USER, content="你好")],
            primary_provider="siliconflow",
            primary_model="deepseek-v3.2",
            skill_chain=["diet"],
        )
    """

    def __init__(self):
        self.timeout_seconds = 30
        self.max_retries = 2  # 每个 provider 重试次数
        self.fallback_chain = self._build_chain()

    def _build_chain(self) -> Dict[str, List[str]]:
        """定义 fallback 链: provider -> [备选 provider 列表]"""
        return {
            "siliconflow": ["openrouter"],
            "openrouter": ["siliconflow"],
        }

    async def chat(
        self,
        user_id: str,
        messages: list,
        primary_provider: str = "siliconflow",
        primary_model: str = None,
        skill_chain: list = None,
        route_decision: str = None,
        system_prompt: str = None,
        temperature: float = 0.7,
        max_tokens: int = 2048,
        user_tier: str = "free",
    ) -> FallbackResult:
        """
        尝试调用 LLM，失败则自动 fallback。

        Fallback 顺序:
        1. primary_provider + primary_model (预算检查)
        2. 如果超预算，使用 fallback_model（同 provider）
        3. 如果 provider 失败，切换到备用 provider 的同款模型
        4. 如果备用 provider 也失败，使用模板兜底回复
        """
        start_time = time.time()
        tried_providers: List[str] = []
        fallback_from: Optional[str] = None
        fallback_reason: Optional[FallbackReason] = None
        last_error: Optional[Exception] = None

        if primary_model is None:
            primary_model = "deepseek-v3.2"

        # 确定模型候选列表: 先用目标模型，超预算用 fallback_model
        model_candidates = [primary_model]

        # 预算检查
        fallback_model = self._check_budget_and_get_fallback(user_id, user_tier)
        if fallback_model and fallback_model != primary_model:
            model_candidates.append(fallback_model)
            logger.info(
                f"[FallbackChain] 预算检查: 超预算，fallback_model={fallback_model}"
            )

        # 构建 provider 尝试列表: primary -> fallback providers
        providers_to_try = [primary_provider]
        providers_to_try.extend(
            self.fallback_chain.get(primary_provider, [])
        )

        # 遍历 providers 和 models
        for provider_name in providers_to_try:
            if provider_name in tried_providers:
                continue  # 避免重复

            for model_name in model_candidates:
                try:
                    result = await self._call_provider(
                        provider_name=provider_name,
                        model=model_name,
                        messages=messages,
                        user_id=user_id,
                        skill_chain=skill_chain,
                        route_decision=route_decision,
                        temperature=temperature,
                        max_tokens=max_tokens,
                        timeout_seconds=self.timeout_seconds,
                    )

                    # 成功
                    latency = (time.time() - start_time) * 1000
                    tried_providers.append(f"{provider_name}:{model_name}")

                    if fallback_from:
                        # 记录 fallback 审计
                        _record_fallback_audit(
                            user_id=user_id,
                            fallback_from_provider=fallback_from.split(":")[0],
                            fallback_from_model=fallback_from.split(":")[1],
                            fallback_to_provider=provider_name,
                            fallback_to_model=model_name,
                            fallback_reason=fallback_reason.value if fallback_reason else "unknown",
                            all_tried_providers=tried_providers,
                            final_status="success",
                            latency_ms=latency,
                            skill_chain=skill_chain,
                        )

                    return FallbackResult(
                        success=True,
                        provider=provider_name,
                        model=model_name,
                        response_text=result["content"],
                        tokens_in=result["tokens_in"],
                        tokens_out=result["tokens_out"],
                        latency_ms=latency,
                        tried_providers=tried_providers,
                        fallback_reason=fallback_reason,
                        fallback_from=fallback_from,
                    )

                except asyncio.TimeoutError:
                    last_error = Exception(f"timeout: {provider_name}/{model_name}")
                    tried_providers.append(f"{provider_name}:{model_name}")
                    fallback_reason = FallbackReason.TIMEOUT
                    fallback_from = f"{provider_name}:{model_name}"
                    logger.warning(
                        f"[FallbackChain] {provider_name}/{model_name} 超时，尝试下一个..."
                    )

                except _SafetyBlockError as e:
                    # 安全阻断 → 不 fallback，返回安全响应
                    latency = (time.time() - start_time) * 1000
                    tried_providers.append(f"{provider_name}:{model_name}")
                    logger.warning(f"[FallbackChain] Safety block，直接返回安全响应")
                    return FallbackResult(
                        success=True,
                        provider=provider_name,
                        model=model_name,
                        response_text=e.safe_response,
                        tokens_in=0,
                        tokens_out=0,
                        latency_ms=latency,
                        tried_providers=tried_providers,
                        fallback_reason=FallbackReason.SAFETY_BLOCK,
                        fallback_from=fallback_from,
                    )

                except _EmptyResponseError:
                    last_error = Exception(f"empty_response: {provider_name}/{model_name}")
                    tried_providers.append(f"{provider_name}:{model_name}")
                    fallback_reason = FallbackReason.EMPTY_RESPONSE
                    fallback_from = f"{provider_name}:{model_name}"
                    logger.warning(
                        f"[FallbackChain] {provider_name}/{model_name} 返回空，尝试下一个..."
                    )

                except Exception as e:
                    error_str = str(e)
                    last_error = e
                    tried_providers.append(f"{provider_name}:{model_name}")

                    if "429" in error_str:
                        fallback_reason = FallbackReason.RATE_LIMIT
                    else:
                        fallback_reason = FallbackReason.SERVER_ERROR

                    fallback_from = f"{provider_name}:{model_name}"
                    logger.warning(
                        f"[FallbackChain] {provider_name}/{model_name} 失败: {e}，尝试下一个..."
                    )

        # 所有 provider 都失败 → 模板兜底
        latency = (time.time() - start_time) * 1000
        logger.error(
            f"[FallbackChain] 所有 provider 均失败，使用模板兜底。tried={tried_providers}"
        )

        # 记录最终失败审计
        _record_fallback_audit(
            user_id=user_id,
            fallback_from_provider=tried_providers[0].split(":")[0] if tried_providers else "none",
            fallback_from_model=tried_providers[0].split(":")[1] if tried_providers else "none",
            fallback_to_provider="template",
            fallback_to_model="template",
            fallback_reason=fallback_reason.value if fallback_reason else "all_failed",
            all_tried_providers=tried_providers,
            final_status="template_fallback",
            latency_ms=latency,
            skill_chain=skill_chain,
        )

        template_text = self._get_template(skill_chain)
        return FallbackResult(
            success=True,  # 模板兜底也视为成功，用户始终能得到回复
            provider="template",
            model="template",
            response_text=template_text,
            tokens_in=0,
            tokens_out=0,
            latency_ms=latency,
            tried_providers=tried_providers,
            fallback_reason=fallback_reason,
            fallback_from=fallback_from,
        )

    async def _call_provider(
        self,
        provider_name: str,
        model: str,
        messages: list,
        user_id: str,
        skill_chain: list = None,
        route_decision: str = None,
        temperature: float = 0.7,
        max_tokens: int = 2048,
        timeout_seconds: int = 30,
    ) -> Dict[str, Any]:
        """
        调用单个 provider。

        Returns:
            {"content": str, "tokens_in": int, "tokens_out": int}

        Raises:
            asyncio.TimeoutError: 超时
            _SafetyBlockError: 安全阻断
            _EmptyResponseError: 空响应
            Exception: 其他错误
        """
        client = _get_provider_client(provider_name)

        try:
            response = await asyncio.wait_for(
                client.chat_completion(
                    model=model,
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens,
                    user_id=user_id,
                    skill_chain=skill_chain,
                    route_decision=route_decision or "",
                ),
                timeout=timeout_seconds,
            )
        except asyncio.TimeoutError:
            raise

        # 解析响应
        ai_text = ""
        if response.choices and len(response.choices) > 0:
            ai_text = response.choices[0].get("message", {}).get("content", "")

        # 空响应检测
        if not ai_text or not ai_text.strip():
            raise _EmptyResponseError(f"{provider_name}/{model} returned empty content")

        return {
            "content": ai_text.strip(),
            "tokens_in": response.usage.prompt_tokens if response.usage else 0,
            "tokens_out": response.usage.completion_tokens if response.usage else 0,
        }

    def _check_budget_and_get_fallback(self, user_id: str, user_tier: str) -> Optional[str]:
        """
        检查用户预算，返回 fallback_model（如果超预算）。
        """
        try:
            from app.llm.audit import get_llm_audit_logger
            audit_logger = get_llm_audit_logger()
            budget_result = audit_logger.check_budget(user_id, user_tier)
            if budget_result["should_downgrade"]:
                return budget_result.get("fallback_model")
        except Exception as e:
            logger.warning(f"[FallbackChain] 预算检查失败，跳过: {e}")
        return None

    def _get_template(self, skill_chain: Optional[List[str]]) -> str:
        """根据 skill_chain 获取兜底模板"""
        lang = "cn"
        topic = "default"

        if skill_chain:
            for skill in skill_chain:
                if skill in FALLBACK_TEMPLATES.get(lang, {}):
                    topic = skill
                    break

        templates = FALLBACK_TEMPLATES.get(lang, FALLBACK_TEMPLATES["cn"])
        return templates.get(topic, templates["default"])


# ==================== 内部异常类 ====================

class _SafetyBlockError(Exception):
    """安全阻断异常（不触发 fallback）"""
    def __init__(self, message: str, safe_response: str):
        super().__init__(message)
        self.safe_response = safe_response


class _EmptyResponseError(Exception):
    """空响应异常"""
    pass


# ==================== 全局实例 ====================

_default_chain: Optional[ModelFallbackChain] = None


def get_fallback_chain() -> ModelFallbackChain:
    """获取全局 FallbackChain 实例"""
    global _default_chain
    if _default_chain is None:
        _default_chain = ModelFallbackChain()
    return _default_chain
