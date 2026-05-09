#!/usr/bin/env python3
"""顺时 ShunShi — SQLite → PostgreSQL 迁移脚本"""
import os
import sqlite3
import sys
from pathlib import Path

SQLITE_PATH = os.getenv("SQLITE_DB_PATH", "backend/data/shunshi.db")
PG_URL = os.getenv("DATABASE_URL", "")

if not PG_URL:
    print("[Error] 请设置 DATABASE_URL 环境变量")
    sys.exit(1)


def main():
    print("=" * 60)
    print("顺时 ShunShi — SQLite → PostgreSQL 迁移")
    print("=" * 60)

    if not Path(SQLITE_PATH).exists():
        print(f"[Error] SQLite 数据库不存在: {SQLITE_PATH}")
        sys.exit(1)

    sqlite_conn = sqlite3.connect(SQLITE_PATH)
    sqlite_conn.row_factory = sqlite3.Row

    try:
        import psycopg2
        pg_conn = psycopg2.connect(PG_URL.replace("postgresql+psycopg2://", "postgresql://"))
        pg_conn.autocommit = False
    except ImportError:
        print("[Error] 请安装 psycopg2: pip install psycopg2-binary")
        sys.exit(1)

    cursor = sqlite_conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    )
    tables = [row[0] for row in cursor.fetchall()]
    print(f"发现 {len(tables)} 个表: {', '.join(tables)}\n")

    all_ok = True
    for table in tables:
        print(f"迁移表: {table}")
        cols = sqlite_conn.execute(f"PRAGMA table_info({table})").fetchall()
        col_names = [c[1] for c in cols]

        # 创建表
        col_defs = []
        for c in cols:
            cid, name, ctype, notnull, dflt, pk = c
            pg_type = "TEXT"
            if "INT" in ctype.upper(): pg_type = "BIGINT"
            elif "REAL" in ctype.upper() or "FLOAT" in ctype.upper(): pg_type = "DOUBLE PRECISION"
            elif "BLOB" in ctype.upper(): pg_type = "BYTEA"
            col_defs.append(f'"{name}" {pg_type}')

        create_sql = f'CREATE TABLE IF NOT EXISTS "{table}" ({ ", ".join(col_defs) });'
        pg_conn.execute(create_sql)
        pg_conn.execute("COMMIT")

        # 迁移数据
        rows = sqlite_conn.execute(f'SELECT * FROM "{table}"').fetchall()
        if rows:
            placeholders = ", ".join(["%s"] * len(col_names))
            col_quoted = ', '.join(f'"{c}"' for c in col_names)
            insert_sql = f'INSERT INTO "{table}" ({col_quoted}) VALUES ({placeholders})'
            pg_conn.executemany(insert_sql, rows)
            pg_conn.execute("COMMIT")

        # 验证
        sqlite_count = sqlite_conn.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
        pg_count = pg_conn.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
        ok = sqlite_count == pg_count
        if not ok: all_ok = False
        print(f"  SQLite: {sqlite_count}, PostgreSQL: {pg_count} {'✓' if ok else '✗'}\n")

    sqlite_conn.close()
    pg_conn.close()

    print("=" * 60)
    if all_ok:
        print("迁移完成! 所有表数据一致 ✓")
    else:
        print("迁移完成，部分表数据不一致 ✗")
        sys.exit(1)


if __name__ == "__main__":
    main()
