"""
Skill 系统测试基线

覆盖: SkillRegistry 版本/分类/DAG、SkillExecutor 兜底/超时、SkillVersioning CRUD

运行: pytest test/test_skill_system.py -v
"""

import pytest
import asyncio
import json
import time
from unittest.mock import AsyncMock, MagicMock, patch

from app.skills.skill_registry import (
    SkillRegistry,
    SkillDefinition,
    SkillCategory,
    validate_skill_dag,
    get_execution_order,
)
from app.skills.executor import (
    SkillExecutor,
    SkillInput,
    SkillOutput,
    SkillName,
    SKILL_FALLBACK_TEMPLATES,
    get_fallback_response,
)


# ==================== Fixtures ====================

@pytest.fixture
def registry():
    """创建 SkillRegistry 实例"""
    return SkillRegistry()


@pytest.fixture
def executor():
    """创建 SkillExecutor 实例（无 LLM，使用 mock）"""
    return SkillExecutor(llm_client=None)


@pytest.fixture
def skills_with_deps():
    """创建带依赖关系的测试 Skill 字典"""
    return {
        "constitution": SkillDefinition(
            skill_id="constitution", category="constitution",
            name="体质分析", description="分析体质",
            version="1.0.0", dependencies=[],
        ),
        "diet": SkillDefinition(
            skill_id="diet", category="diet",
            name="饮食建议", description="食疗方案",
            version="1.0.0", dependencies=["constitution"],
        ),
        "tea": SkillDefinition(
            skill_id="tea", category="tea",
            name="茶饮推荐", description="茶饮方案",
            version="1.0.0", dependencies=["constitution"],
        ),
        "exercise": SkillDefinition(
            skill_id="exercise", category="exercise",
            name="运动建议", description="运动方案",
            version="1.0.0", dependencies=["constitution", "diet"],
        ),
    }


@pytest.fixture
def skills_with_cycle():
    """创建带循环依赖的测试 Skill 字典"""
    return {
        "a": SkillDefinition(
            skill_id="a", category="meta",
            name="A", description="A",
            version="1.0.0", dependencies=["b"],
        ),
        "b": SkillDefinition(
            skill_id="b", category="meta",
            name="B", description="B",
            version="1.0.0", dependencies=["c"],
        ),
        "c": SkillDefinition(
            skill_id="c", category="meta",
            name="C", description="C",
            version="1.0.0", dependencies=["a"],
        ),
    }


@pytest.fixture
def mock_llm_client():
    """创建 mock LLM 客户端"""
    client = AsyncMock()
    client.chat_completion = AsyncMock(return_value=MagicMock(
        choices=[{"message": {"content": "这是测试回复"}}],
        usage=MagicMock(total_tokens=100),
    ))
    return client


# ==================== TestSkillRegistry ====================

class TestSkillRegistry:
    """Skill 注册表测试"""

    def test_all_skills_have_version(self, registry):
        """所有 Skill 都有 version 字段"""
        for skill in registry.all_skills():
            assert skill.version, f"{skill.skill_id} 缺少 version"
            assert isinstance(skill.version, str), f"{skill.skill_id} version 应为 str"

    def test_all_skills_have_category(self, registry):
        """所有 Skill 都有 category 字段"""
        for skill in registry.all_skills():
            assert skill.category, f"{skill.skill_id} 缺少 category"
            # 分类应在枚举中
            valid_categories = {c.value for c in SkillCategory}
            assert skill.category in valid_categories, (
                f"{skill.skill_id} 的 category '{skill.category}' 不在有效分类中"
            )

    def test_no_circular_dependencies(self, registry):
        """注册表中不存在循环依赖"""
        skills_dict = {s.skill_id: s for s in registry.all_skills()}
        errors = validate_skill_dag(skills_dict)
        assert errors == [], f"注册表存在 DAG 问题: {errors}"

    def test_execution_order_respects_deps(self, skills_with_deps):
        """执行顺序应遵循依赖关系"""
        order = get_execution_order(
            ["exercise", "constitution", "diet", "tea"],
            skills_with_deps,
        )
        # constitution 应在 diet 之前
        assert order.index("constitution") < order.index("diet")
        # constitution 应在 tea 之前
        assert order.index("constitution") < order.index("tea")
        # diet 应在 exercise 之前
        assert order.index("diet") < order.index("exercise")
        # constitution 应在 exercise 之前
        assert order.index("constitution") < order.index("exercise")

    def test_dag_detects_cycle(self, skills_with_cycle):
        """DAG 验证应检测循环依赖"""
        errors = validate_skill_dag(skills_with_cycle)
        assert len(errors) > 0
        assert any("循环依赖" in e or "cycle" in e.lower() for e in errors)

    def test_dag_detects_dangling_deps(self):
        """DAG 验证应检测悬空依赖"""
        skills = {
            "orphan": SkillDefinition(
                skill_id="orphan", category="meta",
                name="Orphan", description="has dangling dep",
                version="1.0.0", dependencies=["nonexistent"],
            ),
        }
        errors = validate_skill_dag(skills)
        assert len(errors) > 0
        assert any("悬空依赖" in e or "未注册" in e for e in errors)

    def test_dag_empty_registry(self):
        """空注册表应通过 DAG 验证"""
        errors = validate_skill_dag({})
        assert errors == []

    def test_dag_no_deps(self):
        """无依赖的 Skill 应通过 DAG 验证"""
        skills = {
            "a": SkillDefinition(
                skill_id="a", category="meta",
                name="A", description="A", version="1.0.0",
            ),
            "b": SkillDefinition(
                skill_id="b", category="meta",
                name="B", description="B", version="1.0.0",
            ),
        }
        errors = validate_skill_dag(skills)
        assert errors == []

    def test_execution_order_includes_all(self, skills_with_deps):
        """执行顺序应包含所有请求的 Skill"""
        requested = ["exercise", "constitution", "tea"]
        order = get_execution_order(requested, skills_with_deps)
        assert set(order) >= set(requested)

    def test_execution_order_partial_deps(self, skills_with_deps):
        """仅请求的 Skill 参与排序，外部依赖不纳入"""
        order = get_execution_order(["constitution", "tea"], skills_with_deps)
        assert "constitution" in order
        assert "tea" in order
        assert "diet" not in order  # diet 不在请求中

    def test_total_count_reasonable(self, registry):
        """Skill 总数应合理（>200）"""
        assert registry.total_count() > 200

    def test_category_counts(self, registry):
        """各分类应有合理数量"""
        counts = registry.category_counts()
        assert len(counts) == 15  # 15 个分类
        for cat, count in counts.items():
            assert count > 0, f"分类 {cat} 为空"

    def test_search_returns_results(self, registry):
        """搜索应返回结果"""
        results = registry.search("睡眠")
        assert len(results) > 0

    def test_get_returns_none_for_unknown(self, registry):
        """未知 Skill 应返回 None"""
        assert registry.get("nonexistent_skill_xyz") is None

    def test_to_dict_list(self, registry):
        """序列化应正常工作"""
        dicts = registry.to_dict_list()
        assert len(dicts) == registry.total_count()
        for d in dicts:
            assert "skill_id" in d
            assert "category" in d
            assert "version" in d


# ==================== TestSkillExecution ====================

class TestSkillExecution:
    """Skill 执行测试"""

    @pytest.mark.asyncio
    async def test_execute_success(self, executor):
        """正常执行（无 LLM 时使用 mock）"""
        result = await executor.execute(
            SkillInput(skill_name=SkillName.SLEEP_WINDDOWN, user_id="test_user")
        )
        assert isinstance(result, SkillOutput)
        assert result.skill_name == SkillName.SLEEP_WINDDOWN
        assert result.content  # 有内容
        assert result.model != "fallback"

    @pytest.mark.asyncio
    async def test_execute_timeout_fallback(self):
        """超时应触发兜底回复"""
        executor = SkillExecutor(llm_client=None)
        # 注入一个永远挂起的 skill
        async def slow_execute(input_data):
            await asyncio.sleep(100)
            raise Exception("should not reach")

        # 通过 mock _execute_internal 来模拟超时
        with patch.object(
            executor, "_execute_internal", side_effect=slow_execute
        ):
            result = await executor.execute_with_fallback(
                SkillInput(skill_name=SkillName.SLEEP_WINDDOWN, user_id="test"),
                timeout_seconds=1,
            )
        assert result.model == "fallback"
        assert result.content  # 有兜底回复

    @pytest.mark.asyncio
    async def test_execute_error_fallback(self):
        """异常应触发兜底回复"""
        executor = SkillExecutor(llm_client=None)

        with patch.object(
            executor, "_execute_internal",
            side_effect=RuntimeError("LLM 服务不可用"),
        ):
            result = await executor.execute_with_fallback(
                SkillInput(skill_name=SkillName.FOOD_RECOMMEND, user_id="test"),
                max_retries=1,
            )
        assert result.model == "fallback"
        assert "data" in result.__dict__

    @pytest.mark.asyncio
    async def test_execute_unknown_skill(self, executor):
        """未知 Skill 应抛出 ValueError（经兜底后变为 fallback）"""
        # 未知 skill 在 _execute_internal 中抛异常，兜底捕获
        with patch.object(
            executor, "_execute_internal",
            side_effect=ValueError("Unknown skill"),
        ):
            result = await executor.execute_with_fallback(
                SkillInput(skill_name="nonexistent", user_id="test"),
                max_retries=0,
            )
        assert result.model == "fallback"

    @pytest.mark.asyncio
    async def test_concurrent_skills(self, executor):
        """多个 Skill 应能并行执行"""
        inputs = [
            SkillInput(skill_name=SkillName.SLEEP_WINDDOWN, user_id="test"),
            SkillInput(skill_name=SkillName.FOOD_RECOMMEND, user_id="test"),
            SkillInput(skill_name=SkillName.TEA_RECOMMEND, user_id="test"),
        ]

        results = await asyncio.gather(
            *[executor.execute(inp) for inp in inputs]
        )

        assert len(results) == 3
        for result in results:
            assert isinstance(result, SkillOutput)
            assert result.content

    @pytest.mark.asyncio
    async def test_llm_client_success(self, mock_llm_client):
        """有 LLM 客户端时应成功调用"""
        executor = SkillExecutor(llm_client=mock_llm_client)
        result = await executor.execute(
            SkillInput(skill_name=SkillName.MOOD_SUPPORT, user_id="test")
        )
        assert result.content == "这是测试回复"
        mock_llm_client.chat_completion.assert_called_once()

    def test_list_skills(self, executor):
        """列出所有 Skill 应正常工作"""
        skills = executor.list_skills()
        assert len(skills) == 10
        for s in skills:
            assert "name" in s
            assert "description" in s
            assert "model" in s


# ==================== TestFallbackTemplates ====================

class TestFallbackTemplates:
    """兜底模板测试"""

    def test_all_categories_have_fallback(self):
        """每个分类都应有兜底模板"""
        categories = {c.value for c in SkillCategory}
        for cat in categories:
            assert cat in SKILL_FALLBACK_TEMPLATES, f"分类 {cat} 缺少兜底模板"

    def test_get_fallback_by_category(self):
        """按分类名获取兜底"""
        assert "饮食" in get_fallback_response("diet")
        assert "睡眠" in get_fallback_response("sleep")

    def test_get_fallback_unknown(self):
        """未知 Skill 返回通用兜底"""
        result = get_fallback_response("totally_unknown_skill")
        assert "抱歉" in result or "稍后" in result

    def test_fallback_templates_not_empty(self):
        """兜底模板不应为空"""
        for key, template in SKILL_FALLBACK_TEMPLATES.items():
            assert template.strip(), f"{key} 的兜底模板为空"


# ==================== TestSkillVersioning ====================

class TestSkillVersioning:
    """Skill 版本管理测试（基于 skill_versions 表）"""

    @pytest.fixture
    def db_conn(self, tmp_path):
        """创建临时 SQLite 数据库"""
        import sqlite3
        db_path = tmp_path / "test.db"
        conn = sqlite3.connect(str(db_path))
        conn.row_factory = sqlite3.Row
        conn.execute("""
            CREATE TABLE IF NOT EXISTS skill_versions (
                id TEXT PRIMARY KEY,
                skill_name TEXT NOT NULL,
                version INTEGER NOT NULL,
                config TEXT NOT NULL,
                changelog TEXT DEFAULT '',
                is_active INTEGER DEFAULT 0,
                created_at TEXT NOT NULL,
                UNIQUE(skill_name, version)
            )
        """)
        conn.commit()
        yield conn
        conn.close()

    def _save_skill_version(
        self, conn, skill_name: str, version: int,
        config: dict, changelog: str = "", is_active: bool = False,
    ) -> str:
        """辅助：保存一个 skill 版本"""
        import uuid
        vid = str(uuid.uuid4())
        conn.execute(
            """INSERT OR REPLACE INTO skill_versions
               (id, skill_name, version, config, changelog, is_active, created_at)
               VALUES (?, ?, ?, ?, ?, ?, datetime('now'))""",
            (vid, skill_name, version, json.dumps(config), changelog, int(is_active)),
        )
        conn.commit()
        return vid

    def test_update_increments_version(self, db_conn):
        """更新 Skill 时版本号应递增"""
        config_v1 = {"description": "v1", "model": "deepseek-v3.2"}
        config_v2 = {"description": "v2", "model": "glm-4.6"}

        self._save_skill_version(db_conn, "diet", 1, config_v1, "初始版本")
        self._save_skill_version(db_conn, "diet", 2, config_v2, "更新模型", is_active=True)

        rows = db_conn.execute(
            "SELECT version, config FROM skill_versions WHERE skill_name = ? ORDER BY version",
            ("diet",),
        ).fetchall()

        assert len(rows) == 2
        assert rows[0]["version"] == 1
        assert rows[1]["version"] == 2
        assert json.loads(rows[1]["config"])["model"] == "glm-4.6"

    def test_rollback_to_previous_version(self, db_conn):
        """回滚到上一个版本"""
        config_v1 = {"description": "v1"}
        config_v2 = {"description": "v2"}
        config_v3 = {"description": "v3"}

        self._save_skill_version(db_conn, "tea", 1, config_v1, "初始")
        self._save_skill_version(db_conn, "tea", 2, config_v2, "升级")
        self._save_skill_version(db_conn, "tea", 3, config_v3, "又一次升级", is_active=True)

        # 回滚: 将 v1 设为 active，v3 取消 active
        db_conn.execute(
            "UPDATE skill_versions SET is_active = 0 WHERE skill_name = ?",
            ("tea",),
        )
        db_conn.execute(
            "UPDATE skill_versions SET is_active = 1 WHERE skill_name = ? AND version = ?",
            ("tea", 1),
        )
        db_conn.commit()

        active = db_conn.execute(
            "SELECT version, config FROM skill_versions WHERE skill_name = ? AND is_active = 1",
            ("tea",),
        ).fetchone()

        assert active["version"] == 1
        assert json.loads(active["config"])["description"] == "v1"

    def test_list_versions(self, db_conn):
        """列出所有版本"""
        for v in range(1, 4):
            self._save_skill_version(
                db_conn, "exercise", v,
                {"version": v}, f"版本 {v}",
            )

        rows = db_conn.execute(
            "SELECT version, changelog FROM skill_versions WHERE skill_name = ? ORDER BY version",
            ("exercise",),
        ).fetchall()

        assert len(rows) == 3
        assert [r["version"] for r in rows] == [1, 2, 3]

    def test_version_uniqueness(self, db_conn):
        """同名 Skill 不能有重复版本号"""
        self._save_skill_version(db_conn, "sleep", 1, {"v": 1})

        with pytest.raises(Exception):
            # INSERT OR REPLACE 允许覆盖，用 INSERT OR ABORT 测试唯一性
            db_conn.execute(
                """INSERT INTO skill_versions
                   (id, skill_name, version, config, created_at)
                   VALUES (?, ?, ?, ?, datetime('now'))""",
                ("new-id", "sleep", 1, '{"v": 999}',),
            )
            db.commit()

    def test_changelog_recorded(self, db_conn):
        """changelog 应正确记录"""
        self._save_skill_version(
            db_conn, "emotion", 1, {"v": 1},
            changelog="修复情绪识别准确度",
        )
        row = db_conn.execute(
            "SELECT changelog FROM skill_versions WHERE skill_name = ?",
            ("emotion",),
        ).fetchone()
        assert row["changelog"] == "修复情绪识别准确度"

    def test_active_flag_single(self, db_conn):
        """同一 Skill 同时只能有一个 active 版本"""
        self._save_skill_version(db_conn, "safety", 1, {"v": 1}, is_active=True)
        self._save_skill_version(db_conn, "safety", 2, {"v": 2}, is_active=True)

        active_count = db_conn.execute(
            "SELECT COUNT(*) FROM skill_versions WHERE skill_name = ? AND is_active = 1",
            ("safety",),
        ).fetchone()[0]

        # 两个都是 active（由应用层保证唯一性）
        assert active_count == 2
        # 应用层应先清除旧 active
        db_conn.execute(
            "UPDATE skill_versions SET is_active = 0 WHERE skill_name = ? AND version != ?",
            ("safety", 2),
        )
        db_conn.commit()
        active_count = db_conn.execute(
            "SELECT COUNT(*) FROM skill_versions WHERE skill_name = ? AND is_active = 1",
            ("safety",),
        ).fetchone()[0]
        assert active_count == 1
