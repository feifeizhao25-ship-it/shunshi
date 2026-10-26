"""按用户、按自然日（上海时区）累计模型费用，超限就不再调用。

价格缺省取文档 12 的基准列。文档标明待核实的条目可用环境变量覆盖，不写死成唯一真相。
金额单位是人民币元。日志里只有模型名和金额，没有密钥。
"""

from __future__ import annotations

import os
import threading
from datetime import datetime
from zoneinfo import ZoneInfo

_SHANGHAI = ZoneInfo("Asia/Shanghai")
_LOCK = threading.Lock()
# (scope, day) -> cny
_SPEND: dict[tuple[str, str], float] = {}

# 输入价 / 输出价，元 / 百万 tokens。基准列，待核实的用环境变量盖掉。
_DEFAULT_PRICES: dict[str, tuple[float, float]] = {
    "deepseek-flash": (1.5, 4.5),
    "deepseek-v4-pro": (4.5, 9.0),
    "qwen3.5-plus": (0.8, 4.8),
    "qwen-plus": (0.8, 2.0),
    "qwen-flash": (0.16, 1.55),
    "doubao-seed-2-0-lite-260428": (0.6, 3.6),
    "text-embedding-v4": (0.5, 0.0),
    "qwen3-rerank": (0.5, 0.0),
}
_GUARDRAIL_CNY = 0.0015


def _env(env: dict | None) -> dict:
    return os.environ if env is None else env


def _float_env(source: dict, name: str, default: float) -> float:
    raw = (source.get(name) or "").strip()
    if not raw:
        return default
    try:
        return float(raw)
    except ValueError:
        return default


def price_pair(model: str, env: dict | None = None) -> tuple[float, float]:
    source = _env(env)
    key = model.upper().replace("-", "_").replace(".", "_")
    default_in, default_out = _DEFAULT_PRICES.get(model, (1.5, 4.5))
    return (
        _float_env(source, f"SHUNSHI_PRICE_{key}_IN_CNY_PER_M", default_in),
        _float_env(source, f"SHUNSHI_PRICE_{key}_OUT_CNY_PER_M", default_out),
    )


def estimate_cost_cny(model: str, tokens_in: int, tokens_out: int, env: dict | None = None) -> float:
    price_in, price_out = price_pair(model, env)
    return (max(tokens_in, 0) * price_in + max(tokens_out, 0) * price_out) / 1_000_000


def guardrail_cost_cny(calls: int, env: dict | None = None) -> float:
    unit = _float_env(_env(env), "SHUNSHI_PRICE_GUARDRAIL_CNY", _GUARDRAIL_CNY)
    return max(calls, 0) * unit


def user_daily_cap_cny(env: dict | None = None) -> float:
    # 待核实：文档给的是产品月预算，没有逐用户日帽。缺省 1 元/人/日，可改。
    return _float_env(_env(env), "SHUNSHI_USER_DAILY_CAP_CNY", 1.0)


def product_daily_cap_cny(env: dict | None = None) -> float:
    # 文档 12：启动期顺时月上限 500 元。按 30 天摊到日帽，仍可用环境变量整段覆盖。
    monthly = _float_env(_env(env), "SHUNSHI_MONTHLY_BUDGET_CNY", 500.0)
    return _float_env(_env(env), "SHUNSHI_DAILY_BUDGET_CNY", round(monthly / 30, 4))


def _today() -> str:
    return datetime.now(_SHANGHAI).date().isoformat()


def spent(scope: str, env: dict | None = None) -> float:  # noqa: ARG001
    with _LOCK:
        return _SPEND.get((scope, _today()), 0.0)


def would_exceed(scope: str, amount: float, cap: float) -> bool:
    if cap <= 0:
        return True
    with _LOCK:
        return _SPEND.get((scope, _today()), 0.0) + amount > cap


def record(scope: str, amount: float) -> None:
    if amount <= 0:
        return
    with _LOCK:
        key = (scope, _today())
        _SPEND[key] = _SPEND.get(key, 0.0) + amount


def reset() -> None:
    with _LOCK:
        _SPEND.clear()
