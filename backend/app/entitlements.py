"""会员权益注册表：内建 JSON（entitlements_registry.json），启动时加载并校验 schema。

注册表是唯一权益事实来源：/api/v1/entitlements 直接返回注册表，
subscription/status 的 tier 也由「entitlements 表的 product_id → 注册表 product_tier_map」推导。
"""

import json
from functools import lru_cache
from pathlib import Path
from typing import Any

REGISTRY_PATH = Path(__file__).with_name("entitlements_registry.json")

REQUIRED_TIERS = ("free", "pro", "family", "enterprise")
REQUIRED_DIMENSIONS = (
    "quotas",
    "knowledge",
    "personalization",
    "export",
    "collaboration",
    "service",
)


class RegistryError(RuntimeError):
    """注册表缺失或 schema 不合法。"""


def validate_registry(data: Any) -> dict:
    if not isinstance(data, dict):
        raise RegistryError("注册表必须是 JSON 对象")
    if data.get("product") != "shunshi":
        raise RegistryError('注册表 product 必须为 "shunshi"')
    if not isinstance(data.get("version"), str) or not data["version"]:
        raise RegistryError("注册表缺少 version")
    tiers = data.get("tiers")
    if not isinstance(tiers, dict):
        raise RegistryError("注册表缺少 tiers")
    for tier in REQUIRED_TIERS:
        if tier not in tiers:
            raise RegistryError(f"注册表缺少 tier: {tier}")
        dims = tiers[tier]
        if not isinstance(dims, dict):
            raise RegistryError(f"tier {tier} 必须是对象")
        for dim in REQUIRED_DIMENSIONS:
            if dim not in dims:
                raise RegistryError(f"tier {tier} 缺少维度: {dim}")
    product_tier_map = data.get("product_tier_map", {})
    if not isinstance(product_tier_map, dict):
        raise RegistryError("product_tier_map 必须是对象")
    for product_id, tier in product_tier_map.items():
        if tier not in tiers:
            raise RegistryError(f"product_tier_map[{product_id}] 指向不存在的 tier: {tier}")
    return data


@lru_cache(maxsize=1)
def get_registry() -> dict:
    try:
        data = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RegistryError(f"权益注册表不可读: {exc}") from exc
    return validate_registry(data)


def tier_for_product(product_id: str) -> str:
    """商品 id → tier；未登记的商品按 free 处理，绝不拔高权益。"""
    return str(get_registry().get("product_tier_map", {}).get(product_id, "free"))
