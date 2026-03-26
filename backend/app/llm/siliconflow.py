"""
顺时 AI LLM 客户端 - 硅基流动 (SiliconFlow)
SiliconFlow API Client

支持的模型:
- Qwen/Qwen3-235B-A22B-Thinking-2507
- Kimi K2 Thinking
- MiniMax M2
- GLM-4.6
- DeepSeek-V3.2

作者: Claw 🦅
日期: 2026-03-09
"""

import os
import json
import logging
from typing import Optional, List, Dict, Any, AsyncIterator
from enum import Enum
from dataclasses import dataclass
import aiohttp
import asyncio
import time

logger = logging.getLogger(__name__)


# ==================== 审计集成 ====================

def _get_audit_logger():
    """延迟获取审计日志实例，避免循环导入"""
    try:
        from app.llm.audit import get_llm_audit_logger
        return get_llm_audit_logger()
    except Exception:
        return None


# ==================== 配置 ====================

# 硅基流动 API 配置
SILICONFLOW_API_KEY = os.getenv("SILICONFLOW_API_KEY", "")
SILICONFLOW_BASE_URL = "https://api.siliconflow.cn/v1"

# 模型映射 (配置名 → SiliconFlow 模型名)
MODEL_NAME_MAP = {
    "deepseek-v3.2": "deepseek-ai/DeepSeek-V3.2",
    "glm-4.6": "zai-org/GLM-4.6",
    "qwen3-235b": "Qwen/Qwen3-235B-A22B-Thinking-2507",
    "kimi-k2-thinking": "moonshotai/Kimi-K2-Thinking",
    "minimax-m2": "Pro/MiniMaxAI/MiniMax-M2.5",
}

# 反向映射
SILICONFLOW_MODEL_TO_CONFIG = {v: k for k, v in MODEL_NAME_MAP.items()}


# ==================== 数据模型 ====================

class MessageRole(str, Enum):
    """消息角色"""
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"


@dataclass
class ChatMessage:
    """聊天消息"""
    role: MessageRole
    content: str


@dataclass
class UsageInfo:
    """Token 使用量"""
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


@dataclass
class ChatCompletionResponse:
    """聊天完成响应"""
    id: str
    model: str
    choices: List[Dict[str, Any]]
    usage: UsageInfo
    finish_reason: str
    raw_response: Dict[str, Any]


# ==================== SiliconFlow 客户端 ====================

class SiliconFlowClient:
    """
    硅基流动 API 客户端
    
    功能：
    - 同步/异步调用
    - 流式输出
    - 自动重试
    - 错误处理
    """
    
    def __init__(
        self,
        api_key: str = None,
        base_url: str = None,
        timeout: int = 60,
        max_retries: int = 3,
    ):
        self.api_key = api_key or SILICONFLOW_API_KEY
        self.base_url = base_url or SILICONFLOW_BASE_URL
        self.timeout = timeout
        self.max_retries = max_retries
        
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
    
    def _get_model_name(self, config_name: str) -> str:
        """获取 SiliconFlow 模型名"""
        return MODEL_NAME_MAP.get(config_name, config_name)
    
    async def chat_completion(
        self,
        model: str,
        messages: List[ChatMessage],
        temperature: float = 0.7,
        max_tokens: int = 8192,
        stream: bool = False,
        user_id: str = "",
        skill_chain: List[str] = None,
        route_decision: str = "",
        prompt_version: str = "",
        **kwargs,
    ) -> ChatCompletionResponse:
        """
        调用聊天完成 API
        
        Args:
            model: 配置中的模型名 (如 deepseek-v3.2)
            messages: 消息列表
            temperature: 温度参数
            max_tokens: 最大 token 数
            stream: 是否流式输出
            user_id: 用户 ID（用于审计）
            skill_chain: 使用的 Skill 列表（审计用）
            route_decision: 路由决策理由（审计用）
            prompt_version: Prompt 版本号（审计用）
            
        Returns:
            ChatCompletionResponse
        """
        sf_model = self._get_model_name(model)
        
        # 审计准备
        audit_logger = _get_audit_logger()
        start_time_ms = 0
        request_id = ""
        if audit_logger:
            import uuid
            start_time_ms = time.time() * 1000
            request_id = str(uuid.uuid4())
        
        payload = {
            "model": sf_model,
            "messages": [
                {"role": m.role.value, "content": m.content}
                for m in messages
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream,
            **kwargs,
        }
        
        url = f"{self.base_url}/chat/completions"
        
        # 拼接 prompt 用于 hash（审计用）
        prompt_text = " ".join(m.content for m in messages)
        
        for attempt in range(self.max_retries):
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        url,
                        headers=self.headers,
                        json=payload,
                        timeout=aiohttp.ClientTimeout(total=self.timeout),
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            result = self._parse_response(model, data)
                            
                            # 审计记录
                            if audit_logger and user_id:
                                try:
                                    from app.llm.audit import create_audit
                                    audit_record = create_audit(
                                        user_id=user_id,
                                        provider="siliconflow",
                                        model=model,
                                        prompt=prompt_text,
                                        tokens_in=result.usage.prompt_tokens,
                                        tokens_out=result.usage.completion_tokens,
                                        latency_ms=int(time.time() * 1000 - start_time_ms),
                                        request_id=request_id,
                                        skill_chain=skill_chain,
                                        prompt_version=prompt_version,
                                        route_decision=route_decision,
                                    )
                                    audit_logger.log_call(audit_record)
                                except Exception as audit_err:
                                    logger.warning(f"[SiliconFlow] 审计记录失败: {audit_err}")
                            
                            return result
                        elif response.status == 429:
                            # 限流，等待后重试
                            logger.warning(f"[SiliconFlow] 限流，等待重试...")
                            await asyncio.sleep(2 ** attempt)
                            continue
                        else:
                            error_text = await response.text()
                            logger.error(f"[SiliconFlow] API 错误: {response.status} - {error_text}")
                            
                            # 审计记录错误
                            if audit_logger and user_id:
                                try:
                                    from app.llm.audit import create_audit
                                    audit_record = create_audit(
                                        user_id=user_id,
                                        provider="siliconflow",
                                        model=model,
                                        prompt=prompt_text,
                                        latency_ms=int(time.time() * 1000 - start_time_ms),
                                        response_status="error",
                                        error_message=f"API {response.status}: {error_text[:200]}",
                                        request_id=request_id,
                                        skill_chain=skill_chain,
                                        route_decision=route_decision,
                                    )
                                    audit_logger.log_call(audit_record)
                                except Exception:
                                    pass
                            
                            raise Exception(f"API 错误: {response.status}")
                            
            except asyncio.TimeoutError:
                logger.warning(f"[SiliconFlow] 请求超时 (尝试 {attempt + 1}/{self.max_retries})")
                
                # 审计记录超时
                if audit_logger and user_id and attempt == self.max_retries - 1:
                    try:
                        from app.llm.audit import create_audit
                        audit_record = create_audit(
                            user_id=user_id,
                            provider="siliconflow",
                            model=model,
                            prompt=prompt_text,
                            latency_ms=int(self.timeout * 1000),
                            response_status="timeout",
                            error_message=f"超时 ({self.timeout}s, {self.max_retries} 次重试)",
                            request_id=request_id,
                            skill_chain=skill_chain,
                            route_decision=route_decision,
                        )
                        audit_logger.log_call(audit_record)
                    except Exception:
                        pass
                
                if attempt == self.max_retries - 1:
                    raise
                await asyncio.sleep(1)
                
            except Exception as e:
                if "API 错误" in str(e):
                    raise
                logger.error(f"[SiliconFlow] 请求异常: {e}")
                if attempt == self.max_retries - 1:
                    raise
                await asyncio.sleep(1)
        
        raise Exception("达到最大重试次数")
    
    def _parse_response(self, original_model: str, data: Dict) -> ChatCompletionResponse:
        """解析响应"""
        usage = data.get("usage", {})
        
        return ChatCompletionResponse(
            id=data.get("id", ""),
            model=original_model,  # 使用配置名而非 SF 模型名
            choices=data.get("choices", []),
            usage=UsageInfo(
                prompt_tokens=usage.get("prompt_tokens", 0),
                completion_tokens=usage.get("completion_tokens", 0),
                total_tokens=usage.get("total_tokens", 0),
            ),
            finish_reason=data.get("choices", [{}])[0].get("finish_reason", "stop"),
            raw_response=data,
        )
    
    async def chat_completion_stream(
        self,
        model: str,
        messages: List[ChatMessage],
        temperature: float = 0.7,
        max_tokens: int = 8192,
    ) -> AsyncIterator[str]:
        """流式调用"""
        sf_model = self._get_model_name(model)
        
        payload = {
            "model": sf_model,
            "messages": [
                {"role": m.role.value, "content": m.content}
                for m in messages
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": True,
        }
        
        url = f"{self.base_url}/chat/completions"
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                url,
                headers=self.headers,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=self.timeout),
            ) as response:
                async for line in response.content:
                    if line:
                        line = line.decode("utf-8")
                        if line.startswith("data: "):
                            data = line[6:]
                            if data == "[DONE]":
                                break
                            try:
                                chunk = json.loads(data)
                                content = chunk.get("choices", [{}])[0].get("delta", {}).get("content", "")
                                if content:
                                    yield content
                            except:
                                pass


# ==================== 便捷函数 ====================

# 全局客户端实例
_default_client: Optional[SiliconFlowClient] = None


def get_client() -> SiliconFlowClient:
    """获取默认客户端"""
    global _default_client
    if _default_client is None:
        _default_client = SiliconFlowClient()
    return _default_client


async def chat(
    model: str,
    prompt: str,
    system_prompt: str = None,
    temperature: float = 0.7,
    max_tokens: int = 4096,
) -> ChatCompletionResponse:
    """
    便捷函数：单轮对话
    
    Args:
        model: 模型名 (deepseek-v3.2, glm-4.6, etc.)
        prompt: 用户消息
        system_prompt: 系统提示词
        temperature: 温度
        max_tokens: 最大 token
        
    Returns:
        ChatCompletionResponse
    """
    client = get_client()
    
    messages = []
    if system_prompt:
        messages.append(ChatMessage(role=MessageRole.SYSTEM, content=system_prompt))
    messages.append(ChatMessage(role=MessageRole.USER, content=prompt))
    
    return await client.chat_completion(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
    )


# ==================== 使用示例 ====================

async def demo():
    """演示"""
    client = SiliconFlowClient()
    
    print("=" * 60)
    print("顺时 AI - 硅基流动调用演示")
    print("=" * 60)
    
    # 测试各个模型
    models = [
        "deepseek-v3.2",
        "glm-4.6",
        "qwen3-235b",
        "kimi-k2-thinking",
        "minimax-m2",
    ]
    
    system_prompt = "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。"
    test_prompt = "春天养生需要注意什么？"
    
    for model in models:
        print(f"\n[测试模型: {model}]")
        try:
            response = await chat(
                model=model,
                prompt=test_prompt,
                system_prompt=system_prompt,
                temperature=0.7,
                max_tokens=500,
            )
            
            # 提取回复
            content = response.choices[0].get("message", {}).get("content", "")
            print(f"回复: {content[:200]}...")
            print(f"Token: {response.usage.total_tokens}")
            
        except Exception as e:
            print(f"错误: {e}")


if __name__ == "__main__":
    asyncio.run(demo())
