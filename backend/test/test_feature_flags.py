"""
顺时 AI - Feature Flag 系统测试
覆盖: 存储、灰度、白名单、变体选择、API

运行: pytest test/test_feature_flags.py -v
"""

import json
import time
import pytest
from unittest.mock import patch

from app.feature_flags.store import FlagStore, FlagValue, PRESET_FLAGS


# ==================== Fixtures ====================

@pytest.fixture
def store():
    """创建独立的 FlagStore 实例"""
    s = FlagStore()

    # Mock 数据库，使用内存模拟
    # 直接操作缓存来测试核心逻辑
    return s


@pytest.fixture
def store_with_flags(store):
    """预填充一些 flags 的 store"""
    # 直接操作缓存（绕过 SQLite）
    now = "2026-03-18T00:00:00"
    store._cache = {
        "test.bool_true": FlagValue(
            key="test.bool_true", value_type="boolean",
            value_default=True, rollout_pct=100.0,
            user_whitelist=[], description="测试flag", category="general",
            created_at=now, updated_at=now,
        ),
        "test.bool_false": FlagValue(
            key="test.bool_false", value_type="boolean",
            value_default=False, rollout_pct=100.0,
            user_whitelist=[], description="", category="general",
            created_at=now, updated_at=now,
        ),
        "test.rollout_50": FlagValue(
            key="test.rollout_50", value_type="boolean",
            value_default=True, rollout_pct=50.0,
            user_whitelist=[], description="50%灰度", category="prompt",
            created_at=now, updated_at=now,
        ),
        "test.rollout_20": FlagValue(
            key="test.rollout_20", value_type="boolean",
            value_default=True, rollout_pct=20.0,
            user_whitelist=[], description="20%灰度", category="prompt",
            created_at=now, updated_at=now,
        ),
        "test.whitelist": FlagValue(
            key="test.whitelist", value_type="boolean",
            value_default=False, rollout_pct=0.0,
            user_whitelist=["user_abc", "user_xyz"], description="白名单测试",
            category="payment", created_at=now, updated_at=now,
        ),
        "test.string_val": FlagValue(
            key="test.string_val", value_type="string",
            value_default="hello", rollout_pct=100.0,
            user_whitelist=[], description="", category="general",
            created_at=now, updated_at=now,
        ),
        "test.json_val": FlagValue(
            key="test.json_val", value_type="json",
            value_default={"key": "value"}, rollout_pct=100.0,
            user_whitelist=[], description="", category="general",
            created_at=now, updated_at=now,
        ),
    }
    return store


# ==================== 序列化/反序列化 ====================

class TestSerialization:
    def test_serialize_boolean_true(self, store):
        vtype, vstr = store._serialize_value(True)
        assert vtype == "boolean"
        assert vstr == "true"

    def test_serialize_boolean_false(self, store):
        vtype, vstr = store._serialize_value(False)
        assert vtype == "boolean"
        assert vstr == "false"

    def test_serialize_string(self, store):
        vtype, vstr = store._serialize_value("hello world")
        assert vtype == "string"
        assert vstr == "hello world"

    def test_serialize_dict(self, store):
        val = {"a": 1, "b": [2, 3]}
        vtype, vstr = store._serialize_value(val)
        assert vtype == "json"
        assert json.loads(vstr) == val

    def test_serialize_list(self, store):
        val = ["a", "b", "c"]
        vtype, vstr = store._serialize_value(val)
        assert vtype == "json"
        assert json.loads(vstr) == val

    def test_deserialize_boolean(self, store):
        assert store._deserialize_value("boolean", "true") is True
        assert store._deserialize_value("boolean", "false") is False

    def test_deserialize_json(self, store):
        result = store._deserialize_value("json", '{"a": 1}')
        assert result == {"a": 1}

    def test_deserialize_string(self, store):
        assert store._deserialize_value("string", "hello") == "hello"


# ==================== 用户 Hash ====================

class TestUserHash:
    def test_deterministic(self, store):
        """同一个 key+user 必须产生相同的 hash"""
        h1 = store._hash_user("test.key", "user123")
        h2 = store._hash_user("test.key", "user123")
        assert h1 == h2

    def test_different_keys_different_hash(self, store):
        """不同的 key 对同一个用户产生不同 hash"""
        h1 = store._hash_user("flag_a", "user123")
        h2 = store._hash_user("flag_b", "user123")
        assert h1 != h2

    def test_different_users_different_hash(self, store):
        """不同用户对同一个 flag 产生不同 hash"""
        h1 = store._hash_user("flag_a", "user1")
        h2 = store._hash_user("flag_a", "user2")
        assert h1 != h2

    def test_range_0_99(self, store):
        """hash 值必须在 0-99 范围内"""
        for i in range(100):
            h = store._hash_user("test", f"user_{i}")
            assert 0 <= h < 100


# ==================== is_enabled ====================

class TestIsEnabled:
    def test_bool_true_full_rollout(self, store_with_flags):
        assert store_with_flags.is_enabled("test.bool_true") is True

    def test_bool_false_full_rollout(self, store_with_flags):
        assert store_with_flags.is_enabled("test.bool_false") is False

    def test_nonexistent_flag(self, store_with_flags):
        assert store_with_flags.is_enabled("nonexistent") is False

    def test_rollout_100_with_user(self, store_with_flags):
        """100% 灰度，任何用户都应该启用"""
        assert store_with_flags.is_enabled("test.bool_true", "any_user") is True

    def test_whitelist_override(self, store_with_flags):
        """白名单用户即使默认值为 False 也应该启用"""
        assert store_with_flags.is_enabled("test.whitelist", "user_abc") is True
        assert store_with_flags.is_enabled("test.whitelist", "user_xyz") is True

    def test_non_whitelist_blocked(self, store_with_flags):
        """非白名单用户，默认 False 且 rollout=0%"""
        assert store_with_flags.is_enabled("test.whitelist", "user_other") is False

    def test_rollout_distribution(self, store_with_flags):
        """50% 灰度应该大致 50/50 分布"""
        enabled = 0
        total = 1000
        for i in range(total):
            if store_with_flags.is_enabled("test.rollout_50", f"dist_user_{i}"):
                enabled += 1
        # 允许 40%-60% 的浮动范围
        ratio = enabled / total
        assert 0.40 <= ratio <= 0.60

    def test_rollout_20_distribution(self, store_with_flags):
        """20% 灰度"""
        enabled = 0
        total = 1000
        for i in range(total):
            if store_with_flags.is_enabled("test.rollout_20", f"low_user_{i}"):
                enabled += 1
        ratio = enabled / total
        assert 0.10 <= ratio <= 0.30

    def test_no_user_uses_default(self, store_with_flags):
        """不传 user_id 时，使用默认值"""
        assert store_with_flags.is_enabled("test.bool_true") is True
        assert store_with_flags.is_enabled("test.bool_false") is False

    def test_string_nonempty_enabled(self, store_with_flags):
        """非空字符串视为启用"""
        assert store_with_flags.is_enabled("test.string_val") is True

    def test_json_nonempty_enabled(self, store_with_flags):
        """非空 JSON 视为启用"""
        assert store_with_flags.is_enabled("test.json_val") is True


# ==================== get_variant ====================

class TestGetVariant:
    def test_no_user_returns_first(self, store_with_flags):
        variant = store_with_flags.get_variant("test.variant_test")
        assert variant == "control"

    def test_deterministic_assignment(self, store_with_flags):
        v1 = store_with_flags.get_variant("test.variant_test", "user1",
                                           variants=["a", "b", "c"])
        v2 = store_with_flags.get_variant("test.variant_test", "user1",
                                           variants=["a", "b", "c"])
        assert v1 == v2

    def test_custom_variants(self, store_with_flags):
        variants = ["control", "v2_button_red", "v3_button_blue"]
        v = store_with_flags.get_variant("test.ui_test", "user42", variants=variants)
        assert v in variants

    def test_distribution_across_variants(self, store_with_flags):
        """4 个变体的分布应该大致均匀"""
        variants = ["a", "b", "c", "d"]
        counts = {v: 0 for v in variants}
        total = 4000
        for i in range(total):
            v = store_with_flags.get_variant("test.bool_true", f"dist_u{i}", variants=variants)
            counts[v] += 1
        # 每个变体应该大约 25%
        for v, c in counts.items():
            ratio = c / total
            assert 0.20 <= ratio <= 0.30


# ==================== get_flag ====================

class TestGetFlag:
    def test_existing_flag(self, store_with_flags):
        flag = store_with_flags.get_flag("test.bool_true")
        assert flag is not None
        assert flag.key == "test.bool_true"
        assert flag.value_type == "boolean"

    def test_nonexistent_flag(self, store_with_flags):
        assert store_with_flags.get_flag("no_such_flag") is None


# ==================== list_flags ====================

class TestListFlags:
    def test_list_all(self, store_with_flags):
        flags = store_with_flags.list_flags()
        assert len(flags) == 7

    def test_filter_by_category(self, store_with_flags):
        prompt_flags = store_with_flags.list_flags(category="prompt")
        assert all(f.category == "prompt" for f in prompt_flags)
        assert len(prompt_flags) == 2  # rollout_50, rollout_20

    def test_filter_nonexistent_category(self, store_with_flags):
        flags = store_with_flags.list_flags(category="nonexistent")
        assert len(flags) == 0


# ==================== 预设 Flags ====================

class TestPresetFlags:
    def test_all_presets_defined(self):
        expected_keys = [
            "prompt.v2_enabled",
            "skill.parallel_execution",
            "payment.stripe_live",
            "content.premium_lock",
            "ai.model_deepseek_primary",
            "ai.kimi_emotion",
            "chat.long_memory",
        ]
        for key in expected_keys:
            assert key in PRESET_FLAGS, f"Missing preset flag: {key}"

    def test_preset_categories(self):
        assert PRESET_FLAGS["prompt.v2_enabled"]["category"] == "prompt"
        assert PRESET_FLAGS["skill.parallel_execution"]["category"] == "skill"
        assert PRESET_FLAGS["payment.stripe_live"]["category"] == "payment"
        assert PRESET_FLAGS["content.premium_lock"]["category"] == "content"

    def test_preset_rollout(self):
        # 默认 rollout 为 100%（未指定时）
        assert PRESET_FLAGS["prompt.v2_enabled"].get("rollout_pct", 100.0) == 100.0
        # 指定了 20% 灰度
        assert PRESET_FLAGS["ai.kimi_emotion"]["rollout_pct"] == 20.0
        assert PRESET_FLAGS["chat.long_memory"]["rollout_pct"] == 10.0


# ==================== 性能测试 ====================

class TestPerformance:
    def test_is_enabled_under_1ms(self, store_with_flags):
        """Flag 检查必须在 1ms 内完成"""
        iterations = 10000
        start = time.perf_counter()
        for i in range(iterations):
            store_with_flags.is_enabled("test.bool_true", f"perf_user_{i}")
        elapsed = (time.perf_counter() - start) / iterations
        assert elapsed < 0.001, f"Avg {elapsed*1000:.3f}ms per check, exceeds 1ms"

    def test_get_variant_under_1ms(self, store_with_flags):
        iterations = 10000
        start = time.perf_counter()
        for i in range(iterations):
            store_with_flags.get_variant("test.variant_perf", f"perf_user_{i}",
                                          variants=["a", "b", "c", "d"])
        elapsed = (time.perf_counter() - start) / iterations
        assert elapsed < 0.001, f"Avg {elapsed*1000:.3f}ms per check, exceeds 1ms"


# ==================== 线程安全 ====================

class TestThreadSafety:
    def test_concurrent_reads(self, store_with_flags):
        """并发读取不应崩溃"""
        import threading
        errors = []
        results = []

        def read_flag(n):
            try:
                for i in range(100):
                    results.append(
                        store_with_flags.is_enabled("test.bool_true", f"thread_{n}_user_{i}")
                    )
            except Exception as e:
                errors.append(e)

        threads = [threading.Thread(target=read_flag, args=(i,)) for i in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        assert len(errors) == 0, f"Errors in concurrent reads: {errors}"
        assert len(results) == 10 * 100


# ==================== FlagValue dataclass ====================

class TestFlagValue:
    def test_flag_value_attributes(self):
        flag = FlagValue(
            key="test", value_type="boolean",
            value_default=True, rollout_pct=50.0,
            user_whitelist=["u1"], description="desc",
            category="prompt", created_at="now", updated_at="now",
        )
        assert flag.key == "test"
        assert flag.value_default is True
        assert flag.rollout_pct == 50.0
        assert flag.user_whitelist == ["u1"]

    def test_flag_value_defaults(self):
        flag = FlagValue(key="test", value_type="string", value_default="val")
        assert flag.rollout_pct == 100.0
        assert flag.user_whitelist == []
        assert flag.description == ""
        assert flag.category == "general"
