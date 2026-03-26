"""
内容 CMS 管理路由
后台管理接口，支持内容的 CRUD、发布/下架、媒体管理和标签管理
"""
from fastapi import APIRouter, HTTPException, Query, Header
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from datetime import datetime
import json

from app.database.db import get_db

router = APIRouter(tags=["内容管理"])


# ==================== 常量定义 ====================

# 支持的内容类型
VALID_CONTENT_TYPES = [
    "food", "tea", "acupoint", "exercise",
    "sleep", "emotion", "solar_term", "constitution"
]

# 内容状态（含审核流程）
VALID_STATUSES = ["draft", "pending_review", "approved", "published", "rejected", "archived"]

# 审核状态流转规则: (from_status, action) -> to_status
REVIEW_TRANSITIONS = {
    ("draft", "submit"): "pending_review",
    ("pending_review", "approve"): "approved",
    ("pending_review", "reject"): "rejected",
    ("rejected", "submit"): "pending_review",
    ("approved", "publish"): "published",
    ("published", "archive"): "archived",
    ("archived", "restore"): "draft",
}

# 会员内容分级
VALID_ACCESS_TIERS = ["free", "yangxin", "yiyang"]
ACCESS_TIER_PRIORITY = {"free": 0, "yangxin": 1, "yiyang": 2}


# ==================== 数据库初始化 ====================

def _init_cms_tables():
    """创建CMS相关表"""
    db = get_db()
    db.executescript("""
        -- CMS内容表（独立于旧contents表）
        CREATE TABLE IF NOT EXISTS cms_content (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            body TEXT DEFAULT '',
            type TEXT NOT NULL,
            status TEXT DEFAULT 'draft',
            tags TEXT DEFAULT '[]',
            difficulty TEXT,
            duration TEXT,
            season_tag TEXT,
            locale TEXT DEFAULT 'zh-CN',
            author_id TEXT,
            sort_order INTEGER DEFAULT 0,
            view_count INTEGER DEFAULT 0,
            like_count INTEGER DEFAULT 0,
            extra TEXT DEFAULT '{}',
            published_at TEXT,
            archived_at TEXT,
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now')),
            deleted_at TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_cms_content_type ON cms_content(type);
        CREATE INDEX IF NOT EXISTS idx_cms_content_status ON cms_content(status);
        CREATE INDEX IF NOT EXISTS idx_cms_content_deleted ON cms_content(deleted_at);

        -- CMS媒体表
        CREATE TABLE IF NOT EXISTS cms_media (
            id TEXT PRIMARY KEY,
            content_id TEXT NOT NULL,
            media_type TEXT NOT NULL DEFAULT 'image',
            url TEXT NOT NULL,
            thumbnail_url TEXT,
            title TEXT DEFAULT '',
            sort_order INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (content_id) REFERENCES cms_content(id) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_cms_media_content ON cms_media(content_id);

        -- CMS标签表
        CREATE TABLE IF NOT EXISTS cms_tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            slug TEXT NOT NULL UNIQUE,
            description TEXT DEFAULT '',
            content_count INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE INDEX IF NOT EXISTS idx_cms_tags_slug ON cms_tags(slug);

        -- 审核日志表
        CREATE TABLE IF NOT EXISTS content_review_logs (
            id TEXT PRIMARY KEY,
            content_id TEXT NOT NULL,
            reviewer_id TEXT,
            action TEXT NOT NULL,
            status_from TEXT,
            status_to TEXT NOT NULL,
            comment TEXT DEFAULT '',
            created_at TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_review_logs_content ON content_review_logs(content_id);
        CREATE INDEX IF NOT EXISTS idx_review_logs_action ON content_review_logs(action);
    """)

    # 迁移: 为 cms_content 添加审核相关字段（如果不存在）
    cursor = db.execute("PRAGMA table_info(cms_content)")
    existing_cols = {row[1] for row in cursor.fetchall()}

    migrations = []
    if "reviewed_by" not in existing_cols:
        migrations.append("ALTER TABLE cms_content ADD COLUMN reviewed_by TEXT")
    if "reviewed_at" not in existing_cols:
        migrations.append("ALTER TABLE cms_content ADD COLUMN reviewed_at TEXT")
    if "review_comment" not in existing_cols:
        migrations.append("ALTER TABLE cms_content ADD COLUMN review_comment TEXT DEFAULT ''")
    if "access_tier" not in existing_cols:
        migrations.append("ALTER TABLE cms_content ADD COLUMN access_tier TEXT DEFAULT 'free'")

    for m in migrations:
        try:
            db.execute(m)
        except Exception:
            pass  # 列已存在则跳过

    if migrations:
        db.execute("CREATE INDEX IF NOT EXISTS idx_cms_content_access_tier ON cms_content(access_tier)")
        db.commit()
    db.commit()


# 模块加载时初始化
_init_cms_tables()


# ==================== Pydantic 模型 ====================

class ContentCreateRequest(BaseModel):
    """创建内容请求"""
    title: str
    description: Optional[str] = ""
    body: Optional[str] = ""
    type: str
    tags: Optional[List[str]] = []
    difficulty: Optional[str] = None
    duration: Optional[str] = None
    season_tag: Optional[str] = None
    locale: Optional[str] = "zh-CN"
    author_id: Optional[str] = None
    sort_order: Optional[int] = 0
    extra: Optional[Dict] = None


class ContentUpdateRequest(BaseModel):
    """更新内容请求"""
    title: Optional[str] = None
    description: Optional[str] = None
    body: Optional[str] = None
    type: Optional[str] = None
    tags: Optional[List[str]] = None
    difficulty: Optional[str] = None
    duration: Optional[str] = None
    season_tag: Optional[str] = None
    locale: Optional[str] = None
    author_id: Optional[str] = None
    sort_order: Optional[int] = None
    extra: Optional[Dict] = None


class MediaCreateRequest(BaseModel):
    """添加媒体请求"""
    media_type: str = "image"  # image / video / audio
    url: str
    thumbnail_url: Optional[str] = None
    title: Optional[str] = None
    sort_order: Optional[int] = 0


class TagCreateRequest(BaseModel):
    """创建标签请求"""
    name: str
    slug: Optional[str] = None
    description: Optional[str] = ""


class ReviewRejectRequest(BaseModel):
    """驳回审核请求"""
    comment: str = Field(..., min_length=1, description="驳回原因（必填）")


class ReviewSubmitRequest(BaseModel):
    """提交审核请求（可选附带审核备注）"""
    reviewer_id: Optional[str] = None
    comment: Optional[str] = ""


# ==================== 辅助函数 ====================

def _generate_id(prefix: str = "cms") -> str:
    """生成唯一ID"""
    return f"{prefix}_{datetime.now().strftime('%Y%m%d%H%M%S%f')}"


def _row_to_dict(row, extra_fields: list = None) -> dict:
    """将数据库行转为字典，处理JSON字段"""
    if not row:
        return None
    d = dict(row)
    # 将JSON字符串字段转为列表/字典
    for field in (extra_fields or []) + ["tags", "extra"]:
        if field in d and isinstance(d[field], str):
            try:
                d[field] = json.loads(d[field])
            except (json.JSONDecodeError, TypeError):
                d[field] = [] if field == "tags" else {}
    return d


def _validate_content_type(content_type: str):
    """验证内容类型"""
    if content_type not in VALID_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"无效的内容类型: {content_type}，可选: {', '.join(VALID_CONTENT_TYPES)}"
        )


def _validate_status(status: str):
    """验证内容状态"""
    if status not in VALID_STATUSES:
        raise HTTPException(
            status_code=400,
            detail=f"无效的状态: {status}，可选: {', '.join(VALID_STATUSES)}"
        )


# ==================== 内容 CRUD ====================

@router.get("/content/{content_id}")
async def get_content(content_id: str):
    """获取单个内容详情"""
    db = get_db()
    row = db.execute(
        """SELECT * FROM cms_content
           WHERE id = ? AND deleted_at IS NULL""",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    # 获取关联媒体
    media_rows = db.execute(
        """SELECT id, media_type, url, thumbnail_url, title, sort_order, created_at
           FROM cms_media WHERE content_id = ?
           ORDER BY sort_order ASC, created_at ASC""",
        (content_id,)
    ).fetchall()
    media_list = [_row_to_dict(m) for m in media_rows]

    result = _row_to_dict(row, ["tags", "extra"])
    result["media"] = media_list
    return result


@router.post("/content")
async def create_content(request: ContentCreateRequest):
    """创建内容"""
    _validate_content_type(request.type)

    db = get_db()
    content_id = _generate_id("cms_content")

    try:
        db.execute(
            """INSERT INTO cms_content
               (id, title, description, body, type, status, tags,
                difficulty, duration, season_tag, locale, author_id,
                sort_order, extra)
               VALUES (?, ?, ?, ?, ?, 'draft', ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                content_id,
                request.title,
                request.description or "",
                request.body or "",
                request.type,
                json.dumps(request.tags or [], ensure_ascii=False),
                request.difficulty,
                request.duration,
                request.season_tag,
                request.locale or "zh-CN",
                request.author_id,
                request.sort_order or 0,
                json.dumps(request.extra or {}, ensure_ascii=False),
            )
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"创建内容失败: {str(e)}")

    return {
        "id": content_id,
        "message": "内容创建成功",
    }


@router.put("/content/{content_id}")
async def update_content(content_id: str, request: ContentUpdateRequest):
    """更新内容"""
    db = get_db()
    row = db.execute(
        "SELECT id, type FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    if request.type:
        _validate_content_type(request.type)

    # 构建动态更新
    updates = []
    params = []
    fields_map = {
        "title": request.title,
        "description": request.description,
        "body": request.body,
        "type": request.type,
        "difficulty": request.difficulty,
        "duration": request.duration,
        "season_tag": request.season_tag,
        "locale": request.locale,
        "author_id": request.author_id,
        "sort_order": request.sort_order,
    }

    for field, value in fields_map.items():
        if value is not None:
            updates.append(f"{field} = ?")
            params.append(value)

    if request.tags is not None:
        updates.append("tags = ?")
        params.append(json.dumps(request.tags, ensure_ascii=False))

    if request.extra is not None:
        updates.append("extra = ?")
        params.append(json.dumps(request.extra, ensure_ascii=False))

    if not updates:
        return {"message": "没有需要更新的字段"}

    updates.append("updated_at = datetime('now')")
    params.append(content_id)

    try:
        db.execute(
            f"UPDATE cms_content SET {', '.join(updates)} WHERE id = ?",
            params
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"更新内容失败: {str(e)}")

    return {"message": "内容更新成功"}


@router.delete("/content/{content_id}")
async def delete_content(content_id: str):
    """软删除内容"""
    db = get_db()
    row = db.execute(
        "SELECT id FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在或已删除")

    now = datetime.now().isoformat()
    try:
        db.execute(
            "UPDATE cms_content SET deleted_at = ?, status = 'archived' WHERE id = ?",
            (now, content_id)
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"删除内容失败: {str(e)}")

    return {"message": "内容已删除"}


# ==================== 内容状态管理 ====================

@router.post("/content/{content_id}/publish")
async def publish_content(content_id: str):
    """上架内容（状态改为published）"""
    db = get_db()
    row = db.execute(
        "SELECT id, status FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    now = datetime.now().isoformat()
    try:
        db.execute(
            """UPDATE cms_content
               SET status = 'published', published_at = ?, archived_at = NULL,
                   updated_at = datetime('now')
               WHERE id = ?""",
            (now, content_id)
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"上架失败: {str(e)}")

    return {"message": "内容已上架", "published_at": now}


@router.post("/content/{content_id}/archive")
async def archive_content(content_id: str):
    """下架内容（状态改为archived）"""
    db = get_db()
    row = db.execute(
        "SELECT id, status FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    now = datetime.now().isoformat()
    try:
        db.execute(
            """UPDATE cms_content
               SET status = 'archived', archived_at = ?,
                   updated_at = datetime('now')
               WHERE id = ?""",
            (now, content_id)
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"下架失败: {str(e)}")

    return {"message": "内容已下架", "archived_at": now}


# ==================== 媒体管理 ====================

@router.post("/content/{content_id}/media")
async def add_media(content_id: str, request: MediaCreateRequest):
    """为内容添加媒体（图片/视频/音频）"""
    # 验证内容存在
    db = get_db()
    row = db.execute(
        "SELECT id FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    if request.media_type not in ("image", "video", "audio"):
        raise HTTPException(
            status_code=400,
            detail=f"无效的媒体类型: {request.media_type}，可选: image, video, audio"
        )

    media_id = _generate_id("media")
    try:
        db.execute(
            """INSERT INTO cms_media
               (id, content_id, media_type, url, thumbnail_url, title, sort_order)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                media_id,
                content_id,
                request.media_type,
                request.url,
                request.thumbnail_url,
                request.title or "",
                request.sort_order or 0,
            )
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"添加媒体失败: {str(e)}")

    return {
        "id": media_id,
        "message": "媒体添加成功",
    }


@router.get("/content/{content_id}/media")
async def list_media(content_id: str):
    """获取内容的媒体列表"""
    db = get_db()

    # 验证内容存在
    content = db.execute(
        "SELECT id FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not content:
        raise HTTPException(status_code=404, detail="内容不存在")

    rows = db.execute(
        """SELECT id, content_id, media_type, url, thumbnail_url, title, sort_order, created_at
           FROM cms_media
           WHERE content_id = ?
           ORDER BY sort_order ASC, created_at ASC""",
        (content_id,)
    ).fetchall()

    return {"items": [_row_to_dict(r) for r in rows]}


# ==================== 标签管理 ====================

@router.get("/tags")
async def list_tags(
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
):
    """获取标签列表"""
    db = get_db()
    offset = (page - 1) * limit

    total_row = db.execute("SELECT COUNT(*) as total FROM cms_tags").fetchone()
    total = total_row["total"]

    rows = db.execute(
        """SELECT id, name, slug, description, content_count, created_at
           FROM cms_tags
           ORDER BY content_count DESC, name ASC
           LIMIT ? OFFSET ?""",
        (limit, offset)
    ).fetchall()

    return {
        "total": total,
        "page": page,
        "limit": limit,
        "items": [_row_to_dict(r) for r in rows],
    }


@router.post("/tags")
async def create_tag(request: TagCreateRequest):
    """创建标签"""
    db = get_db()

    # 生成slug
    slug = request.slug or request.name.lower().replace(" ", "-").replace("_", "-")

    try:
        tag_id = _generate_id("tag")
        db.execute(
            """INSERT INTO cms_tags (id, name, slug, description)
               VALUES (?, ?, ?, ?)""",
            (tag_id, request.name, slug, request.description or "")
        )
        db.commit()
    except Exception as e:
        db.rollback()
        if "UNIQUE" in str(e):
            raise HTTPException(status_code=409, detail=f"标签名称或slug已存在: {request.name}")
        raise HTTPException(status_code=500, detail=f"创建标签失败: {str(e)}")

    return {
        "id": tag_id,
        "name": request.name,
        "slug": slug,
        "message": "标签创建成功",
    }


# ==================== 内容统计 ====================

@router.get("/stats")
async def get_cms_stats():
    """
    获取内容统计信息

    返回各类型内容数量、各状态内容数量、最近创建/发布的内容
    """
    db = get_db()

    # 按类型统计
    type_stats = {}
    for ct in VALID_CONTENT_TYPES:
        row = db.execute(
            "SELECT COUNT(*) as count FROM cms_content WHERE type = ? AND deleted_at IS NULL",
            (ct,)
        ).fetchone()
        type_stats[ct] = row["count"]

    # 按状态统计
    status_stats = {}
    for st in VALID_STATUSES:
        row = db.execute(
            "SELECT COUNT(*) as count FROM cms_content WHERE status = ? AND deleted_at IS NULL",
            (st,)
        ).fetchone()
        status_stats[st] = row["count"]

    # 总数
    total_row = db.execute(
        "SELECT COUNT(*) as count FROM cms_content WHERE deleted_at IS NULL"
    ).fetchone()

    # 媒体总数
    media_row = db.execute("SELECT COUNT(*) as count FROM cms_media").fetchone()

    # 标签总数
    tag_row = db.execute("SELECT COUNT(*) as count FROM cms_tags").fetchone()

    # 最近5篇发布内容
    recent_rows = db.execute(
        """SELECT id, title, type, published_at
           FROM cms_content
           WHERE status = 'published' AND deleted_at IS NULL
           ORDER BY published_at DESC
           LIMIT 5"""
    ).fetchall()

    return {
        "total_content": total_row["count"],
        "by_type": type_stats,
        "by_status": status_stats,
        "total_media": media_row["count"],
        "total_tags": tag_row["count"],
        "recent_published": [_row_to_dict(r) for r in recent_rows],
    }


# ==================== 审核工作流 ====================

# 简单权限校验: 通过 X-Admin-Token header 传递审核员令牌
# 后续可接入完整的 RBAC 系统
ADMIN_TOKEN = "shunshi-admin-2026"


def _check_reviewer_permission(x_admin_token: Optional[str] = None) -> None:
    """校验审核员权限（admin 或 reviewer 角色）"""
    if not x_admin_token or x_admin_token != ADMIN_TOKEN:
        raise HTTPException(
            status_code=403,
            detail="需要审核员权限，请在 X-Admin-Token header 中提供有效令牌"
        )


def _check_creator_permission(content_row, author_id: Optional[str] = None) -> None:
    """校验内容创建者权限"""
    content_author = content_row["author_id"] if content_row else None
    if not author_id or (content_author and author_id != content_author):
        raise HTTPException(
            status_code=403,
            detail="只有内容创建者可以执行此操作"
        )


def _validate_transition(current_status: str, action: str) -> str:
    """验证并执行状态转换，返回目标状态"""
    key = (current_status, action)
    if key not in REVIEW_TRANSITIONS:
        raise HTTPException(
            status_code=400,
            detail=f"不允许的状态转换: {current_status} --[{action}]--> ?, "
                   f"当前状态可执行的操作: "
                   f"{[a for (s, a) in REVIEW_TRANSITIONS if s == current_status]}"
        )
    return REVIEW_TRANSITIONS[key]


def _log_review(
    db, content_id: str, action: str,
    status_from: str, status_to: str,
    reviewer_id: Optional[str] = None,
    comment: str = ""
) -> str:
    """追加审核日志（不可删除，只能追加）"""
    log_id = _generate_id("review")
    db.execute(
        """INSERT INTO content_review_logs
           (id, content_id, reviewer_id, action, status_from, status_to, comment, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
        (log_id, content_id, reviewer_id, action, status_from, status_to, comment,
         datetime.now().isoformat())
    )
    return log_id


def _validate_access_tier(tier: str):
    """验证会员内容分级"""
    if tier not in VALID_ACCESS_TIERS:
        raise HTTPException(
            status_code=400,
            detail=f"无效的内容分级: {tier}，可选: {', '.join(VALID_ACCESS_TIERS)}"
        )


@router.post("/review/submit/{content_id}")
async def submit_for_review(
    content_id: str,
    request: ReviewSubmitRequest = ReviewSubmitRequest(),
    x_author_id: Optional[str] = Header(None, alias="X-Author-Id"),
):
    """
    提交内容审核

    draft/rejected → pending_review
    只有内容创建者可以提交
    """
    db = get_db()
    row = db.execute(
        "SELECT id, status, author_id FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    # 权限检查: 创建者
    _check_creator_permission(row, x_author_id or request.reviewer_id)

    current_status = row["status"]
    new_status = _validate_transition(current_status, "submit")

    try:
        _log_review(
            db, content_id, "submit",
            status_from=current_status, status_to=new_status,
            reviewer_id=x_author_id or request.reviewer_id,
            comment=request.comment or "",
        )
        db.execute(
            "UPDATE cms_content SET status = ?, updated_at = datetime('now') WHERE id = ?",
            (new_status, content_id)
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"提交审核失败: {str(e)}")

    return {
        "content_id": content_id,
        "status": new_status,
        "message": "已提交审核",
    }


@router.post("/review/approve/{content_id}")
async def approve_content(
    content_id: str,
    x_admin_token: Optional[str] = Header(None, alias="X-Admin-Token"),
    reviewer_id: Optional[str] = Header(None, alias="X-Author-Id"),
):
    """
    通过内容审核

    pending_review → approved
    需要 admin/reviewer 权限
    """
    _check_reviewer_permission(x_admin_token)

    db = get_db()
    row = db.execute(
        "SELECT id, status FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    current_status = row["status"]
    new_status = _validate_transition(current_status, "approve")

    now = datetime.now().isoformat()
    try:
        _log_review(
            db, content_id, "approve",
            status_from=current_status, status_to=new_status,
            reviewer_id=reviewer_id or "admin",
            comment="审核通过",
        )
        db.execute(
            """UPDATE cms_content
               SET status = ?, reviewed_by = ?, reviewed_at = ?,
                   review_comment = '审核通过', updated_at = datetime('now')
               WHERE id = ?""",
            (new_status, reviewer_id or "admin", now, content_id)
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"审核通过失败: {str(e)}")

    return {
        "content_id": content_id,
        "status": new_status,
        "reviewed_by": reviewer_id or "admin",
        "message": "审核通过",
    }


@router.post("/review/reject/{content_id}")
async def reject_content(
    content_id: str,
    request: ReviewRejectRequest,
    x_admin_token: Optional[str] = Header(None, alias="X-Admin-Token"),
    reviewer_id: Optional[str] = Header(None, alias="X-Author-Id"),
):
    """
    驳回内容审核

    pending_review → rejected
    需要 admin/reviewer 权限，必须提供驳回原因
    """
    _check_reviewer_permission(x_admin_token)

    db = get_db()
    row = db.execute(
        "SELECT id, status FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    current_status = row["status"]
    new_status = _validate_transition(current_status, "reject")

    now = datetime.now().isoformat()
    try:
        _log_review(
            db, content_id, "reject",
            status_from=current_status, status_to=new_status,
            reviewer_id=reviewer_id or "admin",
            comment=request.comment,
        )
        db.execute(
            """UPDATE cms_content
               SET status = ?, reviewed_by = ?, reviewed_at = ?,
                   review_comment = ?, updated_at = datetime('now')
               WHERE id = ?""",
            (new_status, reviewer_id or "admin", now, request.comment, content_id)
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"驳回失败: {str(e)}")

    return {
        "content_id": content_id,
        "status": new_status,
        "reviewed_by": reviewer_id or "admin",
        "message": "内容已驳回",
    }


@router.post("/review/publish/{content_id}")
async def publish_approved(
    content_id: str,
    x_admin_token: Optional[str] = Header(None, alias="X-Admin-Token"),
    reviewer_id: Optional[str] = Header(None, alias="X-Author-Id"),
):
    """
    发布已审核通过的内容

    approved → published
    """
    _check_reviewer_permission(x_admin_token)

    db = get_db()
    row = db.execute(
        "SELECT id, status FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    current_status = row["status"]
    new_status = _validate_transition(current_status, "publish")

    now = datetime.now().isoformat()
    try:
        _log_review(
            db, content_id, "publish",
            status_from=current_status, status_to=new_status,
            reviewer_id=reviewer_id or "admin",
            comment="",
        )
        db.execute(
            """UPDATE cms_content
               SET status = ?, published_at = ?, updated_at = datetime('now')
               WHERE id = ?""",
            (new_status, now, content_id)
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"发布失败: {str(e)}")

    return {
        "content_id": content_id,
        "status": new_status,
        "message": "内容已发布",
    }


@router.get("/review/pending")
async def list_pending_reviews(
    x_admin_token: Optional[str] = Header(None, alias="X-Admin-Token"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
):
    """
    获取待审核内容列表

    需要 admin/reviewer 权限
    """
    _check_reviewer_permission(x_admin_token)

    db = get_db()

    total_row = db.execute(
        "SELECT COUNT(*) as total FROM cms_content WHERE status = 'pending_review' AND deleted_at IS NULL"
    ).fetchone()
    total = total_row["total"]

    offset = (page - 1) * limit
    rows = db.execute(
        """SELECT id, title, description, type, status, access_tier,
                  author_id, created_at, updated_at
           FROM cms_content
           WHERE status = 'pending_review' AND deleted_at IS NULL
           ORDER BY created_at ASC
           LIMIT ? OFFSET ?""",
        (limit, offset)
    ).fetchall()

    return {
        "total": total,
        "page": page,
        "limit": limit,
        "items": [_row_to_dict(r, ["tags"]) for r in rows],
    }


@router.get("/review/history/{content_id}")
async def get_review_history(content_id: str):
    """
    获取内容的审核历史记录

    任何人可查看（审核日志为追加式，不可删除/修改）
    """
    db = get_db()

    # 验证内容存在
    content = db.execute(
        "SELECT id, title, status FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not content:
        raise HTTPException(status_code=404, detail="内容不存在")

    rows = db.execute(
        """SELECT id, content_id, reviewer_id, action, status_from, status_to,
                  comment, created_at
           FROM content_review_logs
           WHERE content_id = ?
           ORDER BY created_at ASC""",
        (content_id,)
    ).fetchall()

    return {
        "content_id": content_id,
        "title": content["title"],
        "current_status": content["status"],
        "history": [_row_to_dict(r) for r in rows],
    }


@router.put("/content/{content_id}/access-tier")
async def set_access_tier(
    content_id: str,
    access_tier: str,
    x_admin_token: Optional[str] = Header(None, alias="X-Admin-Token"),
):
    """
    设置内容的会员访问等级

    - free: 所有用户可见
    - yangxin: 养心版及以上
    - yiyang: 颐养版及以上
    需要 admin 权限
    """
    _check_reviewer_permission(x_admin_token)
    _validate_access_tier(access_tier)

    db = get_db()
    row = db.execute(
        "SELECT id FROM cms_content WHERE id = ? AND deleted_at IS NULL",
        (content_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")

    try:
        db.execute(
            "UPDATE cms_content SET access_tier = ?, updated_at = datetime('now') WHERE id = ?",
            (access_tier, content_id)
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"设置访问等级失败: {str(e)}")

    return {
        "content_id": content_id,
        "access_tier": access_tier,
        "message": "访问等级已更新",
    }


@router.get("/content")
async def list_content(
    type: Optional[str] = Query(None, description="按类型筛选"),
    status: Optional[str] = Query(None, description="按状态筛选"),
    page: int = Query(1, ge=1, description="页码"),
    limit: int = Query(20, ge=1, le=100, description="每页数量"),
    keyword: Optional[str] = Query(None, description="关键词搜索"),
    access_tier: Optional[str] = Query(None, description="按会员等级筛选"),
):
    """
    获取内容列表

    支持按类型、状态筛选和关键词搜索，分页返回
    支持按会员等级 (access_tier) 过滤: free/yangxin/yiyang
    """
    if type:
        _validate_content_type(type)
    if status:
        _validate_status(status)
    if access_tier and access_tier not in VALID_ACCESS_TIERS:
        raise HTTPException(
            status_code=400,
            detail=f"无效的访问等级: {access_tier}"
        )

    db = get_db()
    conditions = ["deleted_at IS NULL"]
    params = []

    if type:
        conditions.append("type = ?")
        params.append(type)
    if status:
        conditions.append("status = ?")
        params.append(status)
    if keyword:
        conditions.append("(title LIKE ? OR description LIKE ?)")
        params.extend([f"%{keyword}%", f"%{keyword}%"])
    if access_tier:
        # 返回该等级及以下的所有内容
        # e.g. access_tier=yangxin 返回 free + yangxin
        tier_priority = ACCESS_TIER_PRIORITY[access_tier]
        tier_list = [t for t, p in ACCESS_TIER_PRIORITY.items() if p <= tier_priority]
        placeholders = ",".join(["?"] * len(tier_list))
        conditions.append(f"COALESCE(access_tier, 'free') IN ({placeholders})")
        params.extend(tier_list)

    where_clause = " AND ".join(conditions)

    # 总数
    count_row = db.execute(
        f"SELECT COUNT(*) as total FROM cms_content WHERE {where_clause}",
        params
    ).fetchone()
    total = count_row["total"]

    # 分页数据
    offset = (page - 1) * limit
    rows = db.execute(
        f"""SELECT id, title, description, type, status, tags, difficulty, duration,
                   season_tag, locale, view_count, like_count, sort_order,
                   access_tier, published_at, created_at, updated_at
            FROM cms_content
            WHERE {where_clause}
            ORDER BY sort_order DESC, created_at DESC
            LIMIT ? OFFSET ?""",
        params + [limit, offset]
    ).fetchall()

    items = [_row_to_dict(r, ["tags"]) for r in rows]

    return {
        "total": total,
        "page": page,
        "limit": limit,
        "pages": (total + limit - 1) // limit,
        "items": items,
    }
