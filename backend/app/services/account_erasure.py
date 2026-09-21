"""注销账号时，把该用户在**所有**存储里的个人数据一并删除。

## 为什么要有这个文件

``DELETE /api/v1/auth/account`` 原来只删核心库（对话、设置、反思、反馈、收听进度、权益、
账号）。而约 120 个产品模块把数据写在另外两处：

- 产品库（``app/db/database.py``，生产在 Postgres 的 ``shunshi_product`` schema）：
  饮水、体重、睡眠、情绪、日记、习惯、随访……77 张表；
- 记录库（``app/database/db.py`` 的 SQLite）：家庭成员、记录、推送 token、记录库账号本身……

注销后这些都原样留着，接口却回「已删除」，隐私政策写的是「所有个人数据将在 30 天内删除」
（个人信息保护法第 47 条）。

做法：两处都按列名找出含用户标识的表（``user_id``，以及 ``*_user_id`` / ``user_id_*``
这类指向用户的列），删掉该用户的行；记录库的 ``users`` 行按 id 删。
付款与退款申请记录按原有口径保留（财务凭证，注销不代表退款完成），在返回里明确列出。
"""

from __future__ import annotations

import logging
import re

logger = logging.getLogger(__name__)

# 财务凭证：不随注销删除，但在返回中告知用户保留了什么。
RETAINED_TABLE = re.compile(r"(payment|order|refund|invoice|receipt)", re.IGNORECASE)
USER_COLUMN = re.compile(r"^(user_id|\w+_user_id|user_id_\w+)$", re.IGNORECASE)


def _is_retained(table: str) -> bool:
    return bool(RETAINED_TABLE.search(table))


def erase_record_store(db, user_id: str) -> tuple[dict[str, int], dict[str, int]]:
    """删记录库（SQLite）里的该用户数据。调用方负责事务与提交。"""
    deleted: dict[str, int] = {}
    retained: dict[str, int] = {}
    tables = [row[0] for row in db.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    ).fetchall()]
    for table in tables:
        columns = [row[1] for row in db.execute(f'PRAGMA table_info("{table}")').fetchall()]
        user_columns = [c for c in columns if USER_COLUMN.match(c)]
        if not user_columns:
            continue
        where = " OR ".join(f'"{c}" = ?' for c in user_columns)
        params = [user_id] * len(user_columns)
        if _is_retained(table):
            count = db.execute(f'SELECT count(*) FROM "{table}" WHERE {where}', params).fetchone()[0]
            if count:
                retained[table] = count
            continue
        cursor = db.execute(f'DELETE FROM "{table}" WHERE {where}', params)
        if cursor.rowcount:
            deleted[table] = cursor.rowcount
    if "users" in tables:
        cursor = db.execute("DELETE FROM users WHERE id = ?", (user_id,))
        if cursor.rowcount:
            deleted["users"] = deleted.get("users", 0) + cursor.rowcount
    return deleted, retained


def erase_product_store(user_id: str) -> tuple[dict[str, int], dict[str, int], list[str]]:
    """删产品库（SQLAlchemy，生产为 Postgres shunshi_product）里的该用户数据。

    返回 (已删, 保留, 删除失败的表)。外键顺序未知，所以每张表各自在保存点里删，
    失败的下一轮重试（子表删完后父表通常就能删了）。
    """
    from sqlalchemy import inspect, text

    from ..db.database import engine

    deleted: dict[str, int] = {}
    retained: dict[str, int] = {}
    inspector = inspect(engine)
    pending: list[tuple[str, str]] = []
    with engine.begin() as connection:
        for table in inspector.get_table_names():
            columns = {column["name"] for column in inspector.get_columns(table)}
            user_columns = [c for c in columns if USER_COLUMN.match(c)]
            where = " OR ".join(f'CAST("{c}" AS TEXT) = :uid' for c in user_columns)
            if table == "users" and "id" in columns:
                where = " OR ".join(filter(None, [where, 'CAST("id" AS TEXT) = :uid']))
            if not where:
                continue
            if _is_retained(table):
                count = connection.execute(
                    text(f'SELECT count(*) FROM "{table}" WHERE {where}'), {"uid": user_id}
                ).scalar()
                if count:
                    retained[table] = int(count)
                continue
            pending.append((table, where))
        # users 放最后
        pending.sort(key=lambda item: item[0] == "users")
        for _ in range(3):
            failed: list[tuple[str, str]] = []
            for table, where in pending:
                savepoint = connection.begin_nested()
                try:
                    result = connection.execute(text(f'DELETE FROM "{table}" WHERE {where}'), {"uid": user_id})
                    savepoint.commit()
                except Exception:
                    savepoint.rollback()
                    failed.append((table, where))
                    continue
                if result.rowcount:
                    deleted[table] = deleted.get(table, 0) + int(result.rowcount)
            if not failed or len(failed) == len(pending):
                pending = failed
                break
            pending = failed
    leftovers = [table for table, _ in pending]
    if leftovers:
        logger.error("account erasure left rows in product tables: %s", ", ".join(leftovers))
    return deleted, retained, leftovers
