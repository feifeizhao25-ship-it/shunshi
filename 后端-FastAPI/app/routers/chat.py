"""对话模块：代理到模型网关（SHUNSHI_MODEL_ROUTER_URL），未配置 fail-closed 503。

客户端契约：
- ApiService.chat → POST /api/v1/chat/send，body {"user_id", "message"}
- ShunShiRouter  → POST /api/v1/ai/chat，body {"user_input", "intent", "context", "prompt", "model_tier"}
- 响应解包：body["content"] ?? body["message"] ?? body["data"]，故响应必须含 content/message。

网关契约（svc-model-router）：
- POST {SHUNSHI_MODEL_ROUTER_URL}/v1/scene/complete，body {"scene": "chat", "market": "cn",
  "messages", "user_id"}；model_tier 经 X-Membership-Tier 请求头传给网关做会员分级降级。
- 网关 429/503 原样透传状态码，其余错误归并为 502，绝不退化成无信息的 500。
"""

from typing import Any

import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..config import Settings
from ..deps import current_user, get_session, get_settings
from ..models import Message

router = APIRouter(prefix="/api/v1", tags=["chat"])

SYSTEM_PROMPT = (
    "你是顺时健康陪伴助手。只用简明中文，不诊断、不替代医生；"
    "涉及危险症状应建议立即就医。回答要可执行、易懂。"
)


class ChatBody(BaseModel):
    message: str | None = Field(default=None, min_length=1, max_length=4000)
    user_input: str | None = Field(default=None, min_length=1, max_length=4000)
    user_id: str | None = None
    intent: str | None = None
    context: dict[str, Any] | None = None
    prompt: str | None = None
    model_tier: str | None = None

    def text(self) -> str:
        value = self.message or self.user_input
        if not value:
            raise HTTPException(status_code=422, detail="消息内容不能为空")
        return value


async def request_gateway(
    model_router_url: str,
    payload: dict[str, Any],
    tier: str | None = None,
) -> str:
    """调用模型网关 ``POST /v1/scene/complete`` 并解包文本。独立成函数便于测试替换。

    契约以网关实现为准（svc-model-router/src/router.py ``scene_complete``）：
    - body: {"scene", "market", "messages", "user_id", ...}，业务方只传 scene
    - 会员分级降级经 ``X-Membership-Tier`` 请求头传递，body 里没有 tier 字段
    - 响应文本在 ``text`` 字段；这里保留 content/message/text 多键兼容
    """
    headers = {"X-Membership-Tier": tier} if tier else None
    try:
        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(
                f"{model_router_url.rstrip('/')}/v1/scene/complete",
                json=payload,
                headers=headers,
            )
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=502,
            detail={"detail": f"模型网关不可达：{type(exc).__name__}", "gateway": "unreachable"},
        ) from exc
    if response.status_code != 200:
        # 透传网关的业务错误码（429 预算超限 / 503 provider 未配置），其余归并为 502，
        # 不让网关错误退化成客户端无法区分的 500。
        try:
            gateway_detail: Any = response.json()
        except ValueError:
            gateway_detail = response.text[:200]
        raise HTTPException(
            status_code=response.status_code if response.status_code in (429, 503) else 502,
            detail={
                "detail": "模型网关调用失败",
                "gateway_status": response.status_code,
                "gateway_detail": gateway_detail,
            },
        )
    data = response.json()
    if isinstance(data, str):
        return data
    if isinstance(data, dict):
        content = data.get("content") or data.get("message") or data.get("text")
        if content is None:
            choices = data.get("choices") or []
            content = (choices[0].get("message") or {}).get("content") if choices else None
        if isinstance(content, str) and content.strip():
            return content.strip()
    raise HTTPException(status_code=502, detail="模型网关未返回有效内容")


@router.post("/chat/send")
@router.post("/ai/chat")
async def chat(
    body: ChatBody,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    if not settings.model_router_url:
        # fail-closed：不返回兜底文案冒充 AI 回复
        raise HTTPException(
            status_code=503,
            detail={"detail": "模型网关未配置（缺少 SHUNSHI_MODEL_ROUTER_URL）", "configured": False},
        )
    message = body.text()
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    # /api/v1/ai/chat（ShunShiRouter）会把组装好的完整 prompt 一并传来，
    # 此时以客户端 prompt 为准，不再叠加骨架 system prompt，避免双份系统提示。
    if body.prompt:
        messages = [{"role": "system", "content": body.prompt}]
    messages.append({"role": "user", "content": message})
    answer = await request_gateway(
        settings.model_router_url,
        {
            "scene": "chat",
            "market": "cn",
            "messages": messages,
            "user_id": user_id,
        },
        tier=body.model_tier or "free",
    )
    session.add(Message(user_id=user_id, role="user", content=message))
    session.add(Message(user_id=user_id, role="assistant", content=answer))
    return {
        "content": answer,
        "message": answer,
        "text": answer,
        "tone": "gentle",
        "care_status": "stable",
        "safety_flag": "none",
    }
