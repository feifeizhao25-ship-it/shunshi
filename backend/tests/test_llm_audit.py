"""
LLM 审计日志单元测试
Tests for app.llm.audit and app.llm.budget

运行: pytest test/test_llm_audit.py -v
"""

import os
import sys
import time
import tempfile
import sqlite3

import pytest

# 确保项目根目录在 path 中
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.llm.budget import TOKEN_BUDGET, MODEL_PRICING, calculate_cost
from app.llm.audit import (
    LLMAuditLogger,
    LLMCallAudit,
    create_audit,
    LLMAuditLogger as AuditLogger,
)


# ==================== Fixtures ====================

@pytest.fixture
def db_path():
    """创建临时数据库文件"""
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    yield path
    if os.path.exists(path):
        os.unlink(path)


@pytest.fixture
def audit_logger(db_path):
    """创建审计日志实例"""
    logger = LLMAuditLogger(db_path)
    yield logger
    logger.shutdown()


# ==================== budget.py 测试 ====================

class TestModelPricingCalculation:
    """成本计算测试"""

    def test_deepseek_cost(self):
        """DeepSeek-V3.2 成本计算"""
        cost = calculate_cost("deepseek-v3.2", tokens_in=1000, tokens_out=500)
        # (1000 * 0.27 + 500 * 1.10) / 1_000_000
        expected = (1000 * 0.27 + 500 * 1.10) / 1_000_000
        assert abs(cost - expected) < 1e-12

    def test_glm4_cost(self):
        """GLM-4.6 成本计算（对称定价）"""
        cost = calculate_cost("glm-4.6", tokens_in=1000, tokens_out=1000)
        expected = (1000 * 0.14 + 1000 * 0.14) / 1_000_000
        assert abs(cost - expected) < 1e-12

    def test_unknown_model_uses_default(self):
        """未知模型使用默认定价"""
        cost = calculate_cost("unknown-model", tokens_in=1000, tokens_out=1000)
        expected = (1000 * 1.0 + 1000 * 1.0) / 1_000_000
        assert abs(cost - expected) < 1e-12

    def test_zero_tokens(self):
        """零 token 成本应为 0"""
        cost = calculate_cost("deepseek-v3.2", tokens_in=0, tokens_out=0)
        assert cost == 0.0

    def test_kimi_cost(self):
        """Kimi K2 高成本验证"""
        cost = calculate_cost("kimi-k2-thinking", tokens_in=500000, tokens_out=100000)
        expected = (500000 * 1.0 + 100000 * 2.0) / 1_000_000
        assert abs(cost - expected) < 1e-12

    def test_all_models_have_pricing(self):
        """确保所有 budget 中的模型都有定价"""
        for tier_cfg in TOKEN_BUDGET.values():
            fb = tier_cfg["fallback_model"]
            assert fb in MODEL_PRICING, f"fallback model {fb} missing from MODEL_PRICING"


# ==================== audit.py 测试 ====================

class TestLogCall:
    """审计记录测试"""

    def test_log_call_success(self, audit_logger: LLMAuditLogger):
        """记录一次成功的 LLM 调用"""
        record = create_audit(
            user_id="user_test_001",
            provider="siliconflow",
            model="deepseek-v3.2",
            prompt="春天养生需要注意什么？",
            tokens_in=50,
            tokens_out=200,
            latency_ms=1200,
            route_decision="默认模型",
        )

        audit_logger.log_call(record)

        # 等待后台写入
        time.sleep(1.5)

        # 验证数据库中有记录
        conn = sqlite3.connect(audit_logger._db_path)
        row = conn.execute("SELECT * FROM ai_audit_logs WHERE id = ?", (record.call_id,)).fetchone()
        conn.close()

        assert row is not None
        assert row[1] == "user_test_001"  # user_id
        assert row[3] == "siliconflow"    # provider
        assert row[4] == "deepseek-v3.2"  # model
        assert row[8] == 50               # tokens_in
        assert row[9] == 200              # tokens_out
        assert row[10] == 1200            # latency_ms
        assert row[14] == "success"       # response_status (column 14)

    def test_log_call_no_raw_prompt_stored(self, audit_logger: LLMAuditLogger):
        """不存储原始 prompt，只存 hash"""
        record = create_audit(
            user_id="user_test_002",
            provider="siliconflow",
            model="glm-4.6",
            prompt="这是一段很敏感的用户信息：手机号13800138000，身份证号110101199001011234",
            tokens_in=100,
            tokens_out=300,
        )
        audit_logger.log_call(record)
        time.sleep(1.5)

        conn = sqlite3.connect(audit_logger._db_path)
        row = conn.execute("SELECT prompt_hash FROM ai_audit_logs WHERE id = ?", (record.call_id,)).fetchone()
        conn.close()

        # prompt_hash 不应包含原始信息
        assert row is not None
        prompt_hash = row[0]
        assert "13800138000" not in prompt_hash
        assert "110101199001011234" not in prompt_hash
        assert len(prompt_hash) == 32  # SHA256 前 32 位

    def test_log_call_error(self, audit_logger: LLMAuditLogger):
        """记录一次失败的 LLM 调用"""
        record = create_audit(
            user_id="user_test_003",
            provider="openrouter",
            model="kimi-k2-thinking",
            prompt="测试错误",
            latency_ms=5000,
            response_status="error",
            error_message="API 429: Rate limit exceeded",
        )
        audit_logger.log_call(record)
        time.sleep(1.5)

        conn = sqlite3.connect(audit_logger._db_path)
        row = conn.execute("SELECT response_status, error_message FROM ai_audit_logs WHERE id = ?", (record.call_id,)).fetchone()
        conn.close()

        assert row is not None
        assert row[0] == "error"
        assert "Rate limit" in row[1]

    def test_log_call_multiple(self, audit_logger: LLMAuditLogger):
        """批量写入多条审计记录"""
        records = []
        for i in range(10):
            record = create_audit(
                user_id="user_batch",
                provider="siliconflow",
                model="deepseek-v3.2",
                prompt=f"测试消息 {i}",
                tokens_in=10,
                tokens_out=50 + i * 10,
                latency_ms=100 * i,
            )
            records.append(record)
            audit_logger.log_call(record)

        time.sleep(2.0)

        conn = sqlite3.connect(audit_logger._db_path)
        count = conn.execute("SELECT COUNT(*) FROM ai_audit_logs WHERE user_id = 'user_batch'").fetchone()[0]
        conn.close()

        assert count == 10


class TestUserDailyUsage:
    """每日用量统计测试"""

    def test_user_daily_usage_empty(self, audit_logger: LLMAuditLogger):
        """无数据时日用量为 0"""
        usage = audit_logger.get_user_daily_usage("user_new", "2099-01-01")
        assert usage["total_tokens"] == 0
        assert usage["calls"] == 0

    def test_user_daily_usage_from_cache(self, audit_logger: LLMAuditLogger):
        """从缓存读取日用量"""
        # 写入 3 条记录
        for i in range(3):
            record = create_audit(
                user_id="user_cache",
                provider="siliconflow",
                model="deepseek-v3.2",
                prompt=f"缓存测试 {i}",
                tokens_in=20 + i * 10,
                tokens_out=100 + i * 20,
            )
            audit_logger.log_call(record)

        usage = audit_logger.get_user_daily_usage("user_cache")
        assert usage["tokens_in"] == 20 + 30 + 40   # 90
        assert usage["tokens_out"] == 100 + 120 + 140  # 360
        assert usage["total_tokens"] == 90 + 360
        assert usage["calls"] == 3
        assert usage["source"] == "cache"

    def test_user_daily_usage_from_database(self, audit_logger: LLMAuditLogger):
        """从数据库读取日用量（历史日期不在缓存中）"""
        # 手动插入一条历史记录
        conn = sqlite3.connect(audit_logger._db_path)
        conn.execute("""
            INSERT INTO ai_audit_logs
            (id, user_id, request_id, provider, model, prompt_hash, tokens_in, tokens_out,
             latency_ms, cost_usd, response_status, created_at)
            VALUES ('hist-001', 'user_hist', 'req-001', 'siliconflow', 'deepseek-v3.2',
                    'abc123', 500, 1000, 800, 0.001, 'success', '2025-12-01T10:00:00')
        """)
        conn.commit()
        conn.close()

        usage = audit_logger.get_user_daily_usage("user_hist", "2025-12-01")
        assert usage["tokens_in"] == 500
        assert usage["tokens_out"] == 1000
        assert usage["total_tokens"] == 1500
        assert usage["calls"] == 1
        assert usage["source"] == "database"


class TestBudgetCheck:
    """预算检查测试"""

    def test_budget_check_free_initial(self, audit_logger: LLMAuditLogger):
        """免费用户初始预算检查"""
        budget = audit_logger.check_budget("user_free", "free")
        assert budget["within_budget"] is True
        assert budget["should_downgrade"] is False
        assert budget["daily_limit"] == 4000
        assert budget["used_tokens"] == 0
        assert budget["remaining_tokens"] == 4000
        assert budget["fallback_model"] == "deepseek-v3.2"

    def test_budget_check_free_within(self, audit_logger: LLMAuditLogger):
        """免费用户在预算内"""
        # 使用 1000 token
        record = create_audit(
            user_id="user_free_2", provider="siliconflow", model="deepseek-v3.2",
            prompt="test", tokens_in=300, tokens_out=700,
        )
        audit_logger.log_call(record)

        budget = audit_logger.check_budget("user_free_2", "free")
        assert budget["within_budget"] is True
        assert budget["used_tokens"] == 1000
        assert budget["remaining_tokens"] == 3000

    def test_budget_check_free_over(self, audit_logger: LLMAuditLogger):
        """免费用户超出预算"""
        # 使用 3600 token，剩余 400，max_per_request=500，400+500>4000 会触发降级
        record = create_audit(
            user_id="user_free_3", provider="siliconflow", model="deepseek-v3.2",
            prompt="test", tokens_in=1000, tokens_out=2600,
        )
        audit_logger.log_call(record)

        budget = audit_logger.check_budget("user_free_3", "free")
        assert budget["used_tokens"] == 3600
        # 3600 + 500 (max_per_request) = 4100 > daily_limit(4000), should_downgrade
        assert budget["should_downgrade"] is True

    def test_budget_check_premium_yiyang(self, audit_logger: LLMAuditLogger):
        """颐养版用户预算检查"""
        budget = audit_logger.check_budget("user_yiyang", "yiyang")
        assert budget["daily_limit"] == 50000
        assert budget["max_per_request"] == 4000
        assert budget["fallback_model"] == "glm-4.6"

    def test_budget_check_premium_jiahe(self, audit_logger: LLMAuditLogger):
        """家和版用户预算检查"""
        budget = audit_logger.check_budget("user_jiahe", "jiahe")
        assert budget["daily_limit"] == 200000
        assert budget["fallback_model"] == "glm-4.6"

    def test_budget_check_unknown_tier(self, audit_logger: LLMAuditLogger):
        """未知等级回退到 free"""
        budget = audit_logger.check_budget("user_unknown", "unknown_tier")
        assert budget["daily_limit"] == 4000  # free 的预算


class TestModelUsageStats:
    """模型使用统计测试"""

    def test_model_stats_empty(self, audit_logger: LLMAuditLogger):
        """无数据时返回空列表"""
        stats = audit_logger.get_model_usage_stats(days=7)
        assert stats == []

    def test_model_stats_with_data(self, audit_logger: LLMAuditLogger):
        """写入数据后查看统计"""
        # 写入不同模型的记录
        for model in ["deepseek-v3.2", "glm-4.6", "deepseek-v3.2"]:
            record = create_audit(
                user_id="user_stats", provider="siliconflow", model=model,
                prompt="stats test", tokens_in=100, tokens_out=200,
            )
            audit_logger.log_call(record)

        time.sleep(1.5)

        stats = audit_logger.get_model_usage_stats(days=7)
        assert len(stats) >= 2  # 至少 2 个模型

        # deepseek-v3.2 应有 2 次调用
        ds_stats = [s for s in stats if s["model"] == "deepseek-v3.2"]
        assert len(ds_stats) == 1
        assert ds_stats[0]["calls"] == 2
        assert ds_stats[0]["tokens_in"] == 200
        assert ds_stats[0]["tokens_out"] == 400


class TestHashPrompt:
    """Prompt hash 测试"""

    def test_hash_consistency(self):
        """相同 prompt 产生相同 hash"""
        h1 = LLMAuditLogger.hash_prompt("春天养生")
        h2 = LLMAuditLogger.hash_prompt("春天养生")
        assert h1 == h2

    def test_hash_different_prompts(self):
        """不同 prompt 产生不同 hash"""
        h1 = LLMAuditLogger.hash_prompt("春天养生")
        h2 = LLMAuditLogger.hash_prompt("夏天养生")
        assert h1 != h2

    def test_hash_length(self):
        """hash 长度固定为 32"""
        h = LLMAuditLogger.hash_prompt("任意 prompt")
        assert len(h) == 32

    def test_hash_empty_string(self):
        """空字符串 hash 不报错"""
        h = LLMAuditLogger.hash_prompt("")
        assert len(h) == 32


class TestCreateAudit:
    """create_audit 便捷函数测试"""

    def test_auto_generated_fields(self):
        """自动生成 call_id, request_id, prompt_hash"""
        record = create_audit(
            user_id="u1", provider="siliconflow", model="deepseek-v3.2",
            prompt="hello",
        )
        assert record.call_id is not None
        assert len(record.call_id) > 0
        assert record.request_id is not None
        assert len(record.request_id) > 0
        assert record.prompt_hash == LLMAuditLogger.hash_prompt("hello")

    def test_cost_auto_calculated(self):
        """cost_usd 自动计算"""
        record = create_audit(
            user_id="u1", provider="siliconflow", model="deepseek-v3.2",
            prompt="test", tokens_in=1000000, tokens_out=500000,
        )
        expected = calculate_cost("deepseek-v3.2", 1000000, 500000)
        assert abs(record.cost_usd - expected) < 1e-12

    def test_defaults(self):
        """默认值检查"""
        record = create_audit(
            user_id="u1", provider="sf", model="m1", prompt="p1",
        )
        assert record.response_status == "success"
        assert record.safety_flag == "none"
        assert record.skill_chain == []
        assert record.error_message is None
        assert record.created_at is not None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
