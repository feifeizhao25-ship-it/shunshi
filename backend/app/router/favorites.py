"""
顺时 — 收藏 API（Favorites）
用户收藏内容（文章、食谱等）的增删查。
"""

from fastapi import APIRouter, Query, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.db.database import get_db

router = APIRouter(prefix="/api/v1/favorites", tags=["favorites"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求模型
# ─────────────────────────────────────────────────────────────────────────────

class FavoriteAddRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    content_id: str = Field(..., description="内容ID")
    content_type: Optional[str] = Field(None, description="内容类型（article, recipe, etc.）")


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("")
async def list_favorites(
    user_id: str = Query(..., description="用户ID"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """获取收藏列表"""
    rows = db.execute(
        text("""
            SELECT f.id, f.user_id, f.content_id, f.content_type, f.created_at,
                   c.title, c.summary, c.category, c.image_url
            FROM sa_favorites f
            LEFT JOIN sa_contents c ON c.id = f.content_id
            WHERE f.user_id = :user_id
            ORDER BY f.created_at DESC
            LIMIT :limit OFFSET :offset
        """),
        {"user_id": user_id, "limit": limit, "offset": offset},
    ).fetchall()

    total_row = db.execute(
        text("SELECT COUNT(*) as cnt FROM sa_favorites WHERE user_id = :user_id"),
        {"user_id": user_id},
    ).fetchone()

    return {
        "items": [
            {
                "id": str(r[0]),
                "user_id": r[1],
                "content_id": r[2],
                "content_type": r[3],
                "created_at": str(r[4]) if r[4] else None,
                "title": r[5],
                "summary": r[6],
                "category": r[7],
                "image_url": r[8],
            }
            for r in rows
        ],
        "total": total_row[0] if total_row else 0,
    }


@router.post("")
async def add_favorite(
    request: FavoriteAddRequest,
    db: Session = Depends(get_db),
):
    """添加收藏"""
    # 检查是否已收藏
    existing = db.execute(
        text("SELECT id FROM sa_favorites WHERE user_id = :uid AND content_id = :cid"),
        {"uid": request.user_id, "cid": request.content_id},
    ).fetchone()

    if existing:
        return {"message": "已收藏", "id": str(existing[0])}

    result = db.execute(
        text("""
            INSERT INTO sa_favorites (user_id, content_id, content_type, created_at)
            VALUES (:uid, :cid, :ctype, NOW())
            RETURNING id
        """),
        {"uid": request.user_id, "cid": request.content_id, "ctype": request.content_type},
    ).fetchone()
    db.commit()

    return {"message": "收藏成功", "id": str(result[0]) if result else None}


@router.delete("/{favorite_id}")
async def remove_favorite(
    favorite_id: str,
    user_id: str = Query(..., description="用户ID"),
    db: Session = Depends(get_db),
):
    """删除收藏"""
    result = db.execute(
        text("DELETE FROM sa_favorites WHERE id = :fid AND user_id = :uid"),
        {"fid": favorite_id, "uid": user_id},
    )
    db.commit()

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="收藏记录不存在")

    return {"message": "取消收藏成功"}


@router.get("/check")
async def check_favorite(
    user_id: str = Query(..., description="用户ID"),
    content_id: str = Query(..., description="内容ID"),
    db: Session = Depends(get_db),
):
    """检查是否已收藏"""
    row = db.execute(
        text("SELECT id FROM sa_favorites WHERE user_id = :uid AND content_id = :cid"),
        {"uid": user_id, "cid": content_id},
    ).fetchone()

    return {"is_favorited": row is not None, "favorite_id": str(row[0]) if row else None}
