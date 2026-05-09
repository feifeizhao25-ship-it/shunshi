"""
顺时 AI - Prompt 版本管理测试
覆盖: 创建、更新、版本管理、回滚、删除、灰度、预览

运行: pytest test/test_prompt_versioning.py -v
"""

import pytest
import sqlite3
import threading
import os
import tempfile
from pathlib import Path

from app.prompts.store import PromptStore, PromptVersion, PromptInfo, PRESET_PROMPTS


# ==================== Fixtures ====================

@pytest.fixture
def db_path():
    """创建临时数据库"""
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    yield path
    os.unlink(path)


@pytest.fixture
def store(db_path, monkeypatch):
    """创建使用临时数据库的 PromptStore"""
    monkeypatch.setattr("app.database.db.DB_DIR", Path(db_path).parent)
    monkeypatch.setattr("app.database.db.DB_PATH", Path(db_path))

    # 替换 _local 为新连接
    import app.database.db as db_mod
    conn = sqlite3.connect(db_path, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")

    # 强制重置线程局部存储
    if hasattr(db_mod._local, "connection"):
        db_mod._local.connection = conn
    else:
        db_mod._local.connection = conn

    s = PromptStore()
    s.init_tables()
    s.init_presets()
    yield s

    conn.close()


# ==================== 基础 CRUD ====================

class TestCreatePrompt:
    def test_create_prompt_success(self, store):
        """创建 prompt 成功"""
        pv = store.create_prompt(
            key="test.new_prompt",
            content="这是一个测试 prompt",
            description="测试用",
            category="test",
        )
        assert pv.prompt_key == "test.new_prompt"
        assert pv.version == 1
        assert pv.content == "这是一个测试 prompt"
        assert pv.is_active is True
        assert pv.category == "test"

    def test_create_prompt_duplicate_raises(self, store):
        """重复创建应抛出异常"""
        store.create_prompt(key="test.dup", content="v1")
        with pytest.raises(ValueError, match="已存在"):
            store.create_prompt(key="test.dup", content="v2")

    def test_create_prompt_version_always_1(self, store):
        """新创建的 prompt 版本号总是 1"""
        for i in range(3):
            pv = store.create_prompt(
                key=f"test.v1_{i}", content=f"content {i}"
            )
            assert pv.version == 1


class TestUpdatePrompt:
    def test_update_creates_new_version(self, store):
        """更新 prompt 自动创建新版本"""
        store.create_prompt(key="test.update", content="version 1")
        pv = store.update_prompt(key="test.update", content="version 2", changelog="升级")
        assert pv.version == 2
        assert pv.content == "version 2"
        assert pv.is_active is True

    def test_update_version_increments(self, store):
        """版本号自增"""
        store.create_prompt(key="test.inc", content="v1")
        store.update_prompt(key="test.inc", content="v2")
        store.update_prompt(key="test.inc", content="v3")
        store.update_prompt(key="test.inc", content="v4")

        versions = store.list_versions("test.inc")
        assert len(versions) == 4
        versions_nums = [v.version for v in versions]
        assert versions_nums == [1, 2, 3, 4]

    def test_update_nonexistent_raises(self, store):
        """更新不存在的 prompt 应抛出异常"""
        with pytest.raises(ValueError, match="不存在"):
            store.update_prompt(key="test.nonexistent", content="xxx")

    def test_only_one_active_after_update(self, store):
        """更新后只有一个活跃版本"""
        store.create_prompt(key="test.active", content="v1")
        store.update_prompt(key="test.active", content="v2")
        store.update_prompt(key="test.active", content="v3")

        versions = store.list_versions("test.active")
        active_count = sum(1 for v in versions if v.is_active)
        assert active_count == 1

        # 最新版本应该活跃
        latest = versions[-1]
        assert latest.is_active is True
        assert latest.version == 3


class TestGetPrompt:
    def test_get_prompt_returns_latest(self, store):
        """get_prompt 返回当前活跃版本"""
        store.create_prompt(key="test.get", content="v1")
        store.update_prompt(key="test.get", content="v2")

        content = store.get_prompt("test.get")
        assert content == "v2"

    def test_get_prompt_nonexistent_empty(self, store):
        """获取不存在的 prompt 返回空字符串"""
        content = store.get_prompt("test.nonexistent")
        assert content == ""

    def test_get_prompt_with_user_id(self, store):
        """带 user_id 获取（灰度场景）"""
        store.create_prompt(key="test.gray", content="stable version")
        content = store.get_prompt("test.gray", user_id="user-123")
        assert content == "stable version"

    def test_get_prompt_presets(self, store):
        """预设 prompt 可用"""
        content = store.get_prompt("chat.system")
        assert "顺时" in content
        assert len(content) > 50

    def test_get_prompt_preserves_registry_fallback(self, store):
        """删除 prompt 后 get_prompt 返回空字符串（不影响 chat）"""
        store.create_prompt(key="test.fallback", content="v1")
        content = store.get_prompt("test.fallback")
        assert content == "v1"

        store.delete_prompt("test.fallback")
        content = store.get_prompt("test.fallback")
        assert content == ""


class TestGetPromptVersion:
    def test_get_specific_version(self, store):
        """获取特定版本"""
        store.create_prompt(key="test.specific", content="v1")
        store.update_prompt(key="test.specific", content="v2")
        store.update_prompt(key="test.specific", content="v3")

        pv = store.get_prompt_version("test.specific", 2)
        assert pv is not None
        assert pv.content == "v2"
        assert pv.version == 2

    def test_get_nonexistent_version(self, store):
        """获取不存在的版本返回 None"""
        store.create_prompt(key="test.no_v", content="v1")
        pv = store.get_prompt_version("test.no_v", 99)
        assert pv is None


class TestRollback:
    def test_rollback_to_previous(self, store):
        """回滚到前一个版本"""
        store.create_prompt(key="test.rollback", content="v1")
        store.update_prompt(key="test.rollback", content="v2")
        store.update_prompt(key="test.rollback", content="v3")

        pv = store.rollback("test.rollback", 1)
        assert pv.version == 1
        assert pv.content == "v1"
        assert pv.is_active is True

        # 验证 get_prompt 返回回滚后的版本
        content = store.get_prompt("test.rollback")
        assert content == "v1"

    def test_rollback_keeps_all_versions(self, store):
        """回滚不删除版本"""
        store.create_prompt(key="test.keep", content="v1")
        store.update_prompt(key="test.keep", content="v2")

        store.rollback("test.keep", 1)
        versions = store.list_versions("test.keep")
        assert len(versions) == 2

    def test_rollback_nonexistent_raises(self, store):
        """回滚不存在的版本应抛出异常"""
        store.create_prompt(key="test.rb", content="v1")
        with pytest.raises(ValueError, match="不存在"):
            store.rollback("test.rb", 99)

    def test_rollback_multiple_times(self, store):
        """多次回滚"""
        store.create_prompt(key="test.multi_rb", content="v1")
        store.update_prompt(key="test.multi_rb", content="v2")
        store.update_prompt(key="test.multi_rb", content="v3")

        store.rollback("test.multi_rb", 1)
        assert store.get_prompt("test.multi_rb") == "v1"

        store.rollback("test.multi_rb", 3)
        assert store.get_prompt("test.multi_rb") == "v3"

        store.rollback("test.multi_rb", 2)
        assert store.get_prompt("test.multi_rb") == "v2"


class TestListVersions:
    def test_list_versions_ordered(self, store):
        """版本列表按版本号排序"""
        store.create_prompt(key="test.list", content="v1")
        store.update_prompt(key="test.list", content="v2")
        store.update_prompt(key="test.list", content="v3")

        versions = store.list_versions("test.list")
        assert len(versions) == 3
        assert [v.version for v in versions] == [1, 2, 3]

    def test_list_versions_empty(self, store):
        """不存在的 prompt 返回空列表"""
        versions = store.list_versions("test.empty_list")
        assert versions == []


class TestListPrompts:
    def test_list_prompts_all(self, store):
        """列出所有 prompts"""
        store.create_prompt(key="test.list_a", content="a", category="cat_a")
        store.create_prompt(key="test.list_b", content="b", category="cat_b")

        prompts = store.list_prompts()
        # 包含预设 prompts + 新创建的
        assert len(prompts) >= 2
        keys = [p.key for p in prompts]
        assert "test.list_a" in keys
        assert "test.list_b" in keys

    def test_list_prompts_by_category(self, store):
        """按分类过滤"""
        store.create_prompt(key="test.cat_x", content="x", category="x")
        store.create_prompt(key="test.cat_y", content="y", category="y")

        x_prompts = store.list_prompts(category="x")
        x_keys = [p.key for p in x_prompts]
        assert "test.cat_x" in x_keys
        assert "test.cat_y" not in x_keys


class TestDeletePrompt:
    def test_delete_cascades(self, store):
        """删除 prompt 同时删除所有版本"""
        store.create_prompt(key="test.del", content="v1")
        store.update_prompt(key="test.del", content="v2")
        store.update_prompt(key="test.del", content="v3")

        deleted = store.delete_prompt("test.del")
        assert deleted is True

        # 验证所有版本已删除
        versions = store.list_versions("test.del")
        assert len(versions) == 0

        content = store.get_prompt("test.del")
        assert content == ""

    def test_delete_nonexistent(self, store):
        """删除不存在的 prompt 返回 False"""
        deleted = store.delete_prompt("test.no_del")
        assert deleted is False


class TestFeatureFlagIntegration:
    def test_get_prompt_without_flag_falls_back(self, store):
        """没有灰度 flag 时直接返回活跃版本"""
        store.create_prompt(key="test.no_flag", content="stable")
        content = store.get_prompt("test.no_flag", user_id="user-xyz")
        assert content == "stable"

    def test_get_prompt_with_invalid_user_id(self, store):
        """无效 user_id 时正常返回活跃版本"""
        store.create_prompt(key="test.bad_user", content="default")
        content = store.get_prompt("test.bad_user", user_id="")
        assert content == "default"


class TestPreview:
    def test_preview_replaces_variables(self, store):
        """预览替换变量"""
        store.create_prompt(
            key="test.preview",
            content="你好{emotion}的用户{name}，{emotion}是很正常的感受。",
        )
        result = store.preview("test.preview", {
            "emotion": "焦虑",
            "name": "小明",
        })
        assert "焦虑的用户小明" in result
        assert "{emotion}" not in result
        assert "{name}" not in result

    def test_preview_no_variables(self, store):
        """没有变量时原样返回"""
        store.create_prompt(key="test.no_var", content="纯文本 prompt")
        result = store.preview("test.no_var")
        assert result == "纯文本 prompt"

    def test_preview_nonexistent(self, store):
        """不存在的 prompt 预览返回空字符串"""
        result = store.preview("test.no_preview", {"key": "val"})
        assert result == ""


class TestPresets:
    def test_presets_loaded(self, store):
        """预设 prompts 已加载"""
        prompts = store.list_prompts()
        keys = [p.key for p in prompts]
        for key in PRESET_PROMPTS:
            assert key in keys, f"预设 prompt '{key}' 未加载"

    def test_preset_content_readable(self, store):
        """预设 prompt 内容可读"""
        for key in PRESET_PROMPTS:
            content = store.get_prompt(key)
            assert content, f"预设 prompt '{key}' 内容为空"

    def test_init_presets_idempotent(self, store):
        """多次初始化不报错"""
        store.init_presets()
        store.init_presets()
        prompts = store.list_prompts()
        # 不会产生重复
        chat_system = [p for p in prompts if p.key == "chat.system"]
        assert len(chat_system) == 1


# ==================== 并发测试 ====================

class TestConcurrency:
    def test_concurrent_get_prompt(self, store):
        """并发获取 prompt 不崩溃"""
        store.create_prompt(key="test.concurrent", content="safe content")
        errors = []
        results = []

        def get_prompt(n):
            try:
                for _ in range(50):
                    results.append(
                        store.get_prompt("test.concurrent", f"user_{n}")
                    )
            except Exception as e:
                errors.append(e)

        threads = [threading.Thread(target=get_prompt, args=(i,)) for i in range(5)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        assert len(errors) == 0
        assert all(r == "safe content" for r in results)

    def test_concurrent_create_different_keys(self, store):
        """并发创建不同 key 不冲突"""
        errors = []

        def create_prompt(i):
            try:
                store.create_prompt(
                    key=f"test.concurrent_{i}",
                    content=f"content_{i}",
                )
            except Exception as e:
                errors.append(e)

        threads = [threading.Thread(target=create_prompt, args=(i,)) for i in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        assert len(errors) == 0
