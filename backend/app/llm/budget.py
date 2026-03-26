"""
顺时 AI Token 预算 & 模型定价
ShunShi AI Token Budget & Model Pricing

定义用户等级对应的 token 预算和模型定价。
budget 检查在 LLM 调用前执行，超预算直接降级。

作者: Claw 🦅
日期: 2026-03-18
"""

from typing import Dict, Any

# ==================== 用户等级 Token 预算 ====================

TOKEN_BUDGET: Dict[str, Dict[str, Any]] = {
    "free": {
        "daily_tokens": 4000,
        "max_per_request": 500,
        "fallback_model": "deepseek-v3.2",
    },
    "yangxin": {
        "daily_tokens": 20000,
        "max_per_request": 2000,
        "fallback_model": "deepseek-v3.2",
    },
    "yiyang": {
        "daily_tokens": 50000,
        "max_per_request": 4000,
        "fallback_model": "glm-4.6",
    },
    "jiahe": {
        "daily_tokens": 200000,
        "max_per_request": 4000,
        "fallback_model": "glm-4.6",
    },
}

# ==================== 模型定价 (每 1M token USD) ====================

MODEL_PRICING: Dict[str, Dict[str, float]] = {
    "deepseek-v3.2": {"input": 0.27, "output": 1.10},
    "glm-4.6": {"input": 0.14, "output": 0.14},
    "qwen3-235b": {"input": 0.28, "output": 0.28},
    "kimi-k2-thinking": {"input": 1.0, "output": 2.0},
    "minimax-m2": {"input": 0.28, "output": 0.28},
    # 国际版
    "gpt-5.4": {"input": 2.50, "output": 10.0},
    "claude-sonnet-4.6": {"input": 3.0, "output": 15.0},
    "claude-opus-4.6": {"input": 15.0, "output": 75.0},
    "gemini-3-pro": {"input": 1.25, "output": 10.0},
    "gemini-3-flash": {"input": 0.075, "output": 0.30},
}


def calculate_cost(model: str, tokens_in: int, tokens_out: int) -> float:
    """
    计算单次调用成本 (USD)

    Args:
        model: 模型配置名
        tokens_in: 输入 token 数
        tokens_out: 输出 token 数

    Returns:
        成本 (USD)
    """
    pricing = MODEL_PRICING.get(model, {"input": 1.0, "output": 1.0})
    cost = (tokens_in * pricing["input"] + tokens_out * pricing["output"]) / 1_000_000
    return cost
