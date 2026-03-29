"""
顺时 - 测试配置和公共 fixtures
使用独立的临时数据库，不污染生产数据。
"""

import os
import sys
import tempfile
import sqlite3
import pytest
import asyncio
from pathlib import Path
from unittest.mock import patch, MagicMock

# 确保项目根目录在 Python path 中
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from fastapi.testclient import TestClient


# ==================== 测试数据库 ====================

@pytest.fixture(scope="session")
def test_db_path():
    """创建临时数据库文件（session 级别，所有测试共享）"""
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        db_path = f.name
    yield db_path
    # 清理
    if os.path.exists(db_path):
        os.unlink(db_path)


@pytest.fixture(scope="session")
def init_test_db(test_db_path):
    """初始化测试数据库（建表 + 种子数据）"""
    conn = sqlite3.connect(test_db_path, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")

    # 建表
    from app.database.db import SCHEMA_SQL
    conn.executescript(SCHEMA_SQL)
    conn.commit()

    # 种子数据
    from app.database.db import SEED_CONTENTS, SEED_SOLAR_TERMS
    for row in SEED_CONTENTS:
        n = len(row)
        if n == 18:
            conn.execute("""
                INSERT OR IGNORE INTO contents
                (id, title, description, type, category, tags,
                 difficulty, time, duration, ingredients, steps,
                 location, method, effect, benefits, best_time, season_tag, locale)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, row)
        elif n == 17:
            conn.execute("""
                INSERT OR IGNORE INTO contents
                (id, title, description, type, category, tags,
                 difficulty, time, duration, ingredients, steps,
                 location, method, effect, benefits, best_time, season_tag)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, row)
        else:
            conn.execute("""
                INSERT OR IGNORE INTO contents
                (id, title, description, type, category, tags,
                 difficulty, time, duration, ingredients, steps,
                 location, method, effect, benefits, best_time)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, row)
    for row in SEED_SOLAR_TERMS:
        conn.execute("""
            INSERT OR IGNORE INTO contents (id, title, description, type, category, tags)
            VALUES (?, ?, ?, ?, ?, ?)
        """, row)

    # 测试用户（含密码哈希）
    from app.router.auth import hash_password
    pw_hash = hash_password("test123456")
    test_users = [
        ("test-user-001", "测试用户", "test@example.com", pw_hash, "exploration"),
        ("due-test-user", "到期测试用户", "due@example.com", pw_hash, "exploration"),
        ("complete-test-user", "完成测试用户", "complete@example.com", pw_hash, "exploration"),
        ("cancel-test-user", "取消测试用户", "cancel@example.com", pw_hash, "exploration"),
        ("delete-test-user", "删除测试用户", "delete@example.com", pw_hash, "exploration"),
        ("context-test-user", "上下文测试用户", "context@example.com", pw_hash, "exploration"),
        ("test-user-preference", "偏好测试用户", "pref@example.com", pw_hash, "exploration"),
        ("test-user-habit", "习惯测试用户", "habit@example.com", pw_hash, "exploration"),
        ("test-user-emotional_trend", "情绪测试用户", "emotion@example.com", pw_hash, "exploration"),
        ("test-user-reflection_theme", "反思测试用户", "reflect@example.com", pw_hash, "exploration"),
        # 额外测试用户（family/tests 使用）
        ("alert-test-user", "告警测试用户", "alert@example.com", pw_hash, "exploration"),
        ("care-test-user", "关怀测试用户", "care@example.com", pw_hash, "exploration"),
        ("invite-expiry-user", "邀请过期测试", "invite-exp@example.com", pw_hash, "exploration"),
        ("invite-reuse-user", "邀请复用测试", "invite-reuse@example.com", pw_hash, "exploration"),
        ("join-test-user-001", "加入测试用户1", "join1@example.com", pw_hash, "exploration"),
        ("join-test-user-002", "加入测试用户2", "join2@example.com", pw_hash, "exploration"),
        ("join-used-test-001", "已用邀请测试1", "joinused1@example.com", pw_hash, "exploration"),
        ("join-used-test-002", "已用邀请测试2", "joinused2@example.com", pw_hash, "exploration"),
        ("join-used-test-003", "已用邀请测试3", "joinused3@example.com", pw_hash, "exploration"),
        ("limit-test-user", "上限测试用户", "limit@example.com", pw_hash, "exploration"),
        # 演示用户（auth 路由 fallback 使用）
        ("user-001", "演示用户", "demo@shunshi.com", pw_hash, "exploration"),
    ]
    for u in test_users:
        conn.execute(
            "INSERT OR IGNORE INTO users (id, name, email, password_hash, life_stage) VALUES (?, ?, ?, ?, ?)",
            u,
        )
    conn.commit()

    return conn


@pytest.fixture
def db_connection(init_test_db):
    """每个测试获得独立的数据库连接"""
    conn = init_test_db
    yield conn


# ==================== FastAPI TestClient ====================

@pytest.fixture
def client(test_db_path, init_test_db):
    """创建 FastAPI TestClient，注入测试数据库"""
    # 模拟 app.database.db 中的数据库路径和连接
    mock_conn = init_test_db

    with patch("app.database.db._get_connection", return_value=mock_conn):
        with patch("app.database.db.get_db", return_value=mock_conn):
            with patch("app.database.db.DB_PATH", Path(test_db_path)):
                with patch("app.database.db.DB_DIR", Path(test_db_path).parent):
                    # 创建应用时跳过 lifespan 初始化（数据库已初始化）
                    from app.main import app

                    # 覆盖 init_db 防止重复初始化
                    with patch("app.main.init_db"):
                        with patch("app.database.db.init_db"):
                            with TestClient(app) as c:
                                yield c

    # 测试结束后清理测试产生的数据（保留种子用户）
    preserve_users = (
        "'user-001', 'test-user-001', 'due-test-user', 'complete-test-user', "
        "'cancel-test-user', 'delete-test-user', 'context-test-user', "
        "'test-user-preference', 'test-user-habit', 'test-user-emotional_trend', "
        "'test-user-reflection_theme', 'alert-test-user', 'care-test-user', "
        "'invite-expiry-user', 'invite-reuse-user', 'join-test-user-001', "
        "'join-test-user-002', 'join-used-test-001', 'join-used-test-002', "
        "'join-used-test-003', 'limit-test-user'"
    )
    try:
        mock_conn.execute(f"DELETE FROM family_relations WHERE user_id NOT IN ({preserve_users})")
    except Exception:
        pass
    try:
        mock_conn.execute(f"DELETE FROM user_memory WHERE user_id NOT IN ({preserve_users})")
    except Exception:
        pass
    try:
        mock_conn.execute(f"DELETE FROM user_settings WHERE user_id NOT IN ({preserve_users})")
    except Exception:
        pass
    try:
        mock_conn.execute(f"DELETE FROM family_invites")
    except Exception:
        pass
    try:
        mock_conn.execute(f"DELETE FROM notifications WHERE user_id NOT IN ({preserve_users})")
    except Exception:
        pass
    mock_conn.commit()


# ==================== 测试用户 fixtures ====================

@pytest.fixture
def test_user():
    """测试用户数据"""
    return {
        "id": "test-user-001",
        "email": "test@example.com",
        "name": "测试用户",
        "password": "test123456",
        "life_stage": "exploration",
    }


@pytest.fixture
def test_user_token(client, test_user):
    """获取测试用户的 JWT token"""
    response = client.post("/api/v1/auth/login", json={
        "email": test_user["email"],
        "password": test_user["password"],
    })
    data = response.json()
    if response.status_code == 200 and data.get("success"):
        return data["data"]["token"]
    return None


@pytest.fixture
def auth_headers(test_user_token):
    """带认证的请求头"""
    token = test_user_token or "mock-token"
    return {"Authorization": f"Bearer {token}"}
