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

# 指向用户、但列名不叫 user_id 的列（逐表登记）。
# 只按 user_id 找会漏掉：家庭成员（owner_id / member_id，含成员昵称）、家庭关系
# （inviter_id / invitee_id）、家庭邀请（created_by）。
EXTRA_USER_COLUMNS: dict[str, tuple[str, ...]] = {
    "family_members": ("owner_id", "member_id"),
    "sa_family_relations": ("inviter_id", "invitee_id"),
    "family_invites": ("created_by",),
}

# 列名看起来像「某个人」、但**不是**用户的：必须写明理由。
# test_account_erasure_columns 会扫描三处存储里所有表的列，凡是列名像用户引用、
# 又既不被上面两条覆盖、也没在这里登记的，就失败——新增表的人必须回答「注销时怎么找到这行」。
NOT_USER_LINKED: dict[tuple[str, str], str] = {
    ("sa_articles", "author"): "编辑署名，内容库",
    ("sa_articles", "author_id"): "编辑署名，内容库",
    ("sa_recipes", "author_id"): "编辑署名，内容库",
    ("cms_content", "author_id"): "编辑署名，内容库",
    ("sms_codes", "phone"): "核心库验证码表以手机号为键，routers/user.delete_account 按注销前的手机号清理",
    ("sms_send_log", "phone_digest"): "短信发送日志，只存手机号摘要，作为网络安全日志保留",
    ("sa_prompt_versions", "created_by"): "运营人员，提示词版本",
    ("sa_gift_orders", "recipient_id"): "付款记录（依法保留）",
    ("sa_feature_flags", "target_users"): "灰度配置，不含个人资料",
    ("sa_exercises", "target_body_parts"): "部位，不是人",
    ("sa_subscription_products", "max_family_seats"): "商品配置",
    ("skill_versions", "skill_name"): "技能名称，不是人",
    ("family_invites", "family_id"): "家庭编号，不是用户",
    ("family_relations", "family_id"): "家庭编号，不是用户",
    ("family_relations", "family_name"): "家庭名称，用户名下的行已按 user_id 删除",
    ("family_relations", "member_name"): "用户名下的行已按 user_id 删除",
    ("family_seats", "member_name"): "用户名下的行已按 user_id 删除；被邀请一方见 anonymize_family_seat_references",
    ("users", "phone"): "users 行本身，注销时匿名化 / 删除",
    ("users", "email"): "users 行本身，注销时匿名化 / 删除",
    ("users", "nickname"): "users 行本身，注销时匿名化 / 删除",
}

# 产品库 users 行里要清掉的个人信息列（存在才清）。
PRODUCT_USER_PII_COLUMNS = (
    "phone", "email", "nickname", "avatar_url", "gender", "birth_date", "province", "city",
    "constitution_type", "constitution_tested_at", "constitution_scores", "notification_settings",
    "preferred_wake_time", "preferred_sleep_time",
)


def user_columns_of(table: str, columns) -> list[str]:
    """该表里指向用户的列：user_id / *_user_id / user_id_* 加上逐表登记的额外列。"""
    found = [c for c in columns if USER_COLUMN.match(c)]
    for extra in EXTRA_USER_COLUMNS.get(table, ()):
        if extra in columns and extra not in found:
            found.append(extra)
    return found


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
        user_columns = user_columns_of(table, columns)
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
            user_columns = user_columns_of(table, columns)
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
        # 产品库的 users 行**不删，只匿名化**：
        # sa_subscription_orders（付款记录，依法保留）对它有外键，而且是 ON DELETE CASCADE ——
        # 删这一行会把订单连带删掉，而接口还照样回「保留了 1 条订单」。
        pending = [(t, w) for t, w in pending if t != "users"]
        if "users" in inspector.get_table_names():
            user_cols = {c["name"] for c in inspector.get_columns("users")}
            assignments = [f'"{c}" = NULL' for c in PRODUCT_USER_PII_COLUMNS if c in user_cols]
            if "is_deleted" in user_cols:
                assignments.append('"is_deleted" = TRUE')
            if "is_active" in user_cols:
                assignments.append('"is_active" = FALSE')
            if assignments:
                result = connection.execute(
                    text(f'UPDATE "users" SET {", ".join(assignments)} WHERE CAST("id" AS TEXT) = :uid'),
                    {"uid": user_id},
                )
                if result.rowcount:
                    deleted["users(anonymized)"] = int(result.rowcount)
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


# ── 导出（个人信息保护法第 45 条：查阅、复制）──────────────────────────────
# 原来「导出我的数据」只含核心库；产品库与记录库里的同一批数据（与注销时删除的范围一致）
# 都不在导出里。敏感凭证列不导出。
SECRET_COLUMN = re.compile(r"(password|token|secret|code_hash|private_key)", re.IGNORECASE)


def _plain(value):
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    return str(value)


def _row_dict(columns: list[str], row) -> dict:
    return {c: _plain(v) for c, v in zip(columns, row) if not SECRET_COLUMN.search(c)}


def export_record_store(db, user_id: str) -> dict[str, list[dict]]:
    out: dict[str, list[dict]] = {}
    tables = [row[0] for row in db.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    ).fetchall()]
    for table in tables:
        columns = [row[1] for row in db.execute(f'PRAGMA table_info("{table}")').fetchall()]
        user_columns = user_columns_of(table, columns)
        if table == "users":
            where, params = "id = ?", [user_id]
        elif user_columns:
            where = " OR ".join(f'"{c}" = ?' for c in user_columns)
            params = [user_id] * len(user_columns)
        else:
            continue
        rows = db.execute(f'SELECT * FROM "{table}" WHERE {where}', params).fetchall()
        if rows:
            out[table] = [_row_dict(columns, tuple(r)) for r in rows]
    return out


def export_product_store(user_id: str) -> dict[str, list[dict]]:
    from sqlalchemy import inspect, text

    from ..db.database import engine

    out: dict[str, list[dict]] = {}
    inspector = inspect(engine)
    with engine.connect() as connection:
        for table in inspector.get_table_names():
            columns = [column["name"] for column in inspector.get_columns(table)]
            user_columns = user_columns_of(table, columns)
            clauses = [f'CAST("{c}" AS TEXT) = :uid' for c in user_columns]
            if table == "users" and "id" in columns:
                clauses.append('CAST("id" AS TEXT) = :uid')
            if not clauses:
                continue
            result = connection.execute(
                text(f'SELECT * FROM "{table}" WHERE {" OR ".join(clauses)}'), {"uid": user_id}
            )
            keys = list(result.keys())
            rows = result.fetchall()
            if rows:
                out[table] = [_row_dict(keys, tuple(r)) for r in rows]
    return out
