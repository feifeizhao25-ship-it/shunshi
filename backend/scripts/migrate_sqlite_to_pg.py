#!/usr/bin/env python3
"""
顺时 ShunShi — SQLite → PostgreSQL 数据迁移脚本

用法:
    python scripts/migrate_sqlite_to_pg.py

功能:
    1. 读取 SQLite 数据库中的所有数据
    2. 通过 SQLAlchemy ORM 写入 PostgreSQL
    3. 验证迁移完整性

前提:
    - PostgreSQL 已安装并配置 (setup_postgres_redis.sh)
    - DATABASE_URL 环境变量已设置
"""

import os
import sys
import sqlite3
import logging

# 确保项目根目录在 path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import engine, Session, init_db

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# SQLite 源数据库
SQLITE_DB = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "shunshi.db")


def get_sqlite_tables(conn: sqlite3.Connection) -> list:
    """获取 SQLite 中的所有表名"""
    cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    return [row[0] for row in cursor.fetchall()]


def get_table_columns(conn: sqlite3.Connection, table: str) -> list:
    """获取表的列名"""
    cursor = conn.execute(f"PRAGMA table_info({table})")
    return [row[1] for row in cursor.fetchall()]


def get_table_count(conn: sqlite3.Connection, table: str) -> int:
    """获取表的行数"""
    cursor = conn.execute(f"SELECT COUNT(*) FROM {table}")
    return cursor.fetchone()[0]


def migrate_table(sqlite_conn: sqlite3.Connection, table: str, pg_session) -> int:
    """迁移单个表的数据"""
    from sqlalchemy import text

    columns = get_table_columns(sqlite_conn, table)
    count = get_table_count(sqlite_conn, table)

    if count == 0:
        logger.info("  ⏭️  %s: 空表，跳过", table)
        return 0

    # 读取所有数据
    cursor = sqlite_conn.execute(f"SELECT * FROM {table}")
    rows = cursor.fetchall()

    # 构建 INSERT 语句
    col_str = ", ".join(f'"{c}"' for c in columns)
    val_str = ", ".join(f":{c}" for c in columns)
    insert_sql = text(f'INSERT INTO "{table}" ({col_str}) VALUES ({val_str}) ON CONFLICT DO NOTHING')

    # 批量插入
    batch_size = 500
    inserted = 0
    for i in range(0, len(rows), batch_size):
        batch = rows[i:i + batch_size]
        batch_dicts = [dict(zip(columns, row)) for row in batch]
        try:
            pg_session.execute(insert_sql, batch_dicts)
            pg_session.commit()
            inserted += len(batch)
        except Exception as e:
            pg_session.rollback()
            logger.warning("  ⚠️  %s 批次 %d 失败: %s", table, i // batch_size, e)

    logger.info("  ✅ %s: %d/%d 行已迁移", table, inserted, count)
    return inserted


def verify_migration(sqlite_conn: sqlite3.Connection, tables: list, pg_session) -> bool:
    """验证迁移完整性"""
    from sqlalchemy import text

    all_ok = True
    logger.info("\n========== 迁移验证 ==========")
    for table in tables:
        sqlite_count = get_table_count(sqlite_conn, table)
        try:
            pg_result = pg_session.execute(text(f'SELECT COUNT(*) FROM "{table}"'))
            pg_count = pg_result.scalar()
        except Exception:
            pg_count = -1

        status = "✅" if pg_count >= sqlite_count else "❌"
        if pg_count < sqlite_count:
            all_ok = False
        logger.info("  %s %s: SQLite=%d  PostgreSQL=%d", status, table, sqlite_count, pg_count)

    return all_ok


def main():
    logger.info("==================== SQLite → PostgreSQL 迁移 ====================")

    # 检查 SQLite 数据库
    if not os.path.exists(SQLITE_DB):
        logger.warning("SQLite 数据库不存在: %s", SQLITE_DB)
        logger.info("将仅创建表结构（无数据迁移）")
        init_db()
        return

    logger.info("SQLite 源: %s", SQLITE_DB)
    logger.info("PostgreSQL 目标: %s", os.getenv("DATABASE_URL", "未设置"))

    # 连接 SQLite
    sqlite_conn = sqlite3.connect(SQLITE_DB)
    sqlite_conn.row_factory = sqlite3.Row

    # 确保 PostgreSQL 表已创建
    logger.info("\n[1/3] 创建 PostgreSQL 表结构...")
    init_db()

    # 获取 SQLite 表列表
    tables = get_sqlite_tables(sqlite_conn)
    logger.info("  发现 %d 个表", len(tables))

    # 迁移数据
    logger.info("\n[2/3] 迁移数据...")
    pg_session = Session()
    total_migrated = 0

    for table in tables:
        try:
            migrated = migrate_table(sqlite_conn, table, pg_session)
            total_migrated += migrated
        except Exception as e:
            logger.warning("  ❌ %s: 迁移失败 — %s", table, e)
            pg_session.rollback()

    # 验证
    logger.info("\n[3/3] 验证迁移...")
    success = verify_migration(sqlite_conn, tables, pg_session)

    pg_session.close()
    sqlite_conn.close()

    logger.info("\n==================== 迁移完成 ====================")
    logger.info("总计迁移: %d 行", total_migrated)
    if success:
        logger.info("🎉 所有表验证通过！")
    else:
        logger.warning("⚠️  部分表数据不完整，请检查日志")


if __name__ == "__main__":
    main()
