"""
顺时 AI LLM 客户端
提供多供应商AI模型调用支持

供应商:
- SiliconFlow (国内版主力)
- OpenRouter (国内+国际版双通道)

环境变量:
- SILICONFLOW_API_KEY
- SILICONFLOW_BASE_URL
- OPENROUTER_API_KEY
- OPENROUTER_BASE_URL
"""

from app.llm.siliconflow import (
    SiliconFlowClient,
    get_client,
    chat,
    ChatMessage,
    ChatCompletionResponse,
    UsageInfo,
    MessageRole,
)

from app.llm.openrouter import (
    OpenRouterClient,
    get_openrouter_client,
    chat_openrouter,
)

from app.llm.audit import (
    LLMAuditLogger,
    LLMCallAudit,
    create_audit,
    get_llm_audit_logger,
    init_llm_audit,
)

from app.llm.budget import (
    TOKEN_BUDGET,
    MODEL_PRICING,
    calculate_cost,
)

from app.llm.fallback import (
    ModelFallbackChain,
    get_fallback_chain,
    FallbackResult,
    FallbackReason,
    FALLBACK_TEMPLATES,
)
