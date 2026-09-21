# -*- coding: utf-8 -*-
"""钉住"免费档也有个性化"这条产品口径（2026-09-21 定）。

## 背景

改之前 `entitlements_registry.json` 的 free 档是：

    "personalization": {
        "onboarding_profile": true,
        "adaptive_suggestions": false,
        "ai_memory": false
    }

也就是说**免费用户看到的千篇一律的界面是设计如此**，不是 bug。
这一版把它改成 true。

注册表是唯一权益事实来源（`/api/v1/entitlements` 直接返回它），
客户端按它决定要不要显示个性化入口 / 付费墙，所以改这里就是改行为。

## 这一组钉两件事

1. **免费档确实有个性化**——四档全部开启，不再有"个性化＝付费功能"。
2. **升级仍然有理由**——付费差异必须落在**已经被服务端强制执行的**
   维度上，而不是又一个"注册表说有、代码不管"的字段。
   目前真正被执行的是 `quotas.ai_daily_messages`
   （`services/chat_quota.py` 用 Redis 原子扣减，失败 fail-closed）。

第 2 条比第 1 条重要：如果有人后来想靠"记忆条数"做差异，
必须先把执行逻辑写出来，否则这条用例会提醒他注册表里那个数字没人读。
"""
from __future__ import annotations

import json
import pathlib
import sys

import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

from app.entitlements import get_registry, tier_for_product, validate_registry  # noqa: E402

REGISTRY_PATH = BACKEND / "app" / "entitlements_registry.json"
ALL_TIERS = ("free", "pro", "family", "enterprise")


@pytest.fixture(scope="module")
def registry() -> dict:
    return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))


# ── 一、免费档有个性化 ────────────────────────────────────────

@pytest.mark.parametrize("flag", ["onboarding_profile", "adaptive_suggestions", "ai_memory"])
def test_free_tier_has_personalization(registry, flag):
    assert registry["tiers"]["free"]["personalization"][flag] is True, (
        f"免费档的 {flag} 是关的。口径是免费档也有个性化——"
        f"若要改回付费专属，请先和产品确认，而不是改这条用例。"
    )


@pytest.mark.parametrize("tier", ALL_TIERS)
def test_every_tier_has_personalization(registry, tier):
    """个性化不再是分档依据，四档一致。"""
    assert all(registry["tiers"][tier]["personalization"].values())


# ── 二、升级的理由必须落在被真正执行的维度上 ──────────────────

def test_paid_tiers_still_differ_from_free(registry):
    free = registry["tiers"]["free"]
    pro = registry["tiers"]["pro"]
    assert free != pro, "免费档和 pro 完全一样，付费就没有理由了"


def test_the_enforced_difference_is_the_daily_message_quota(registry):
    """`ai_daily_messages` 是**服务端真正强制执行**的那个差异。

    `services/chat_quota.py` 直接读 `get_registry()['tiers'][tier]
    ['quotas']['ai_daily_messages']`，用 Redis 原子扣减，
    Redis 不可用时 503 而不是放行。这条用例把注册表与执行点绑在一起：
    改了字段名或层级，chat_quota 会在运行时 KeyError，而这里会先红。
    """
    free_limit = registry["tiers"]["free"]["quotas"]["ai_daily_messages"]
    pro_limit = registry["tiers"]["pro"]["quotas"]["ai_daily_messages"]
    assert isinstance(free_limit, int) and not isinstance(free_limit, bool)
    assert isinstance(pro_limit, int) and not isinstance(pro_limit, bool)
    assert free_limit >= 0, "免费档应当有明确上限"
    assert pro_limit == -1 or pro_limit > free_limit, "付费档的对话额度必须更高"


def test_knowledge_depth_remains_a_paid_difference(registry):
    """深度内容仍然是付费差异：长期趋势与周深度报告。"""
    free = registry["tiers"]["free"]["knowledge"]
    pro = registry["tiers"]["pro"]["knowledge"]
    assert free["long_term_trends"] is False and pro["long_term_trends"] is True
    assert free["weekly_deep_report"] is False and pro["weekly_deep_report"] is True


def test_no_unenforced_memory_quota_sneaks_in(registry):
    """注册表里不应出现没人读的记忆额度字段。

    "免费档给多少条记忆" 是个合理的分档方式，但**必须先有执行点**
    （类似 chat_quota 的原子扣减）。在那之前，往 quotas 里加一个
    `ai_memory_entries` 只会变成又一个"配置说有、代码不管"的字段，
    和注册表作为唯一事实来源的定位冲突。

    真要加：先在 memory_system 里写好按 tier 的裁剪，再改这条用例。
    """
    for tier in ALL_TIERS:
        quotas = registry["tiers"][tier]["quotas"]
        assert "ai_memory_entries" not in quotas, (
            "加了记忆额度字段但没有执行点；先实现 memory_system 的按档裁剪"
        )


# ── 三、注册表本身仍然合法 ────────────────────────────────────

def test_registry_still_validates(registry):
    assert validate_registry(registry) is registry


def test_loaded_registry_matches_file(registry):
    assert get_registry()["tiers"]["free"]["personalization"] == \
        registry["tiers"]["free"]["personalization"]


def test_unknown_product_still_falls_back_to_free():
    """未登记的商品仍按 free 处理，绝不拔高权益。"""
    assert tier_for_product("no-such-product-id") == "free"
