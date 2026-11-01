"""
顺时 — 收藏 API（Favorites）
用户收藏内容（文章、食谱等）的增删查。
"""

from fastapi import APIRouter, Query, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.locale_context import RequestLocale, request_locale
from app.models.favorite import Favorite

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

def _content_lookup(db: Session, content_ids: list) -> dict:
    """content_id 若是内容库（sa_content_items）里的 UUID，就带上标题等；不是就只返回收藏本身。"""
    import uuid as _uuid

    from app.models.content import ContentItem

    ids = []
    for cid in content_ids:
        try:
            ids.append(_uuid.UUID(str(cid)))
        except (ValueError, AttributeError):
            continue
    if not ids:
        return {}
    rows = db.query(ContentItem).filter(ContentItem.id.in_(ids)).all()
    return {str(r.id): r for r in rows}


@router.get("")
async def list_favorites(
    user_id: str = Query(..., description="用户ID"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """获取收藏列表"""
    q = db.query(Favorite).filter(Favorite.user_id == user_id)
    total = q.count()
    rows = q.order_by(Favorite.created_at.desc()).offset(offset).limit(limit).all()
    contents = _content_lookup(db, [r.content_id for r in rows])
    items = []
    for r in rows:
        c = contents.get(str(r.content_id))
        items.append({
            "id": str(r.id),
            "user_id": r.user_id,
            "content_id": r.content_id,
            "content_type": r.content_type,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "title": getattr(c, "title", None),
            "summary": getattr(c, "subtitle", None) or getattr(c, "description", None),
            "category": getattr(c, "content_type", None),
            "image_url": None,
        })
    # 同时给扁平的 {items,total} 和 App 使用的 {success,data:{items,total}} 两种形状
    return {"success": True, "items": items, "total": total, "data": {"items": items, "total": total}}


@router.post("")
async def add_favorite(
    request: FavoriteAddRequest,
    db: Session = Depends(get_db),
    loc: RequestLocale = Depends(request_locale),
):
    """添加收藏（同一内容重复收藏只留一条）"""
    existing = (
        db.query(Favorite)
        .filter(Favorite.user_id == request.user_id, Favorite.content_id == request.content_id)
        .first()
    )
    if existing:
        return {"success": True, "message": "Already saved" if loc.is_global else "已收藏", "id": str(existing.id)}
    row = Favorite(user_id=request.user_id, content_id=request.content_id, content_type=request.content_type)
    db.add(row)
    db.commit()
    db.refresh(row)
    return {"success": True, "message": "Saved" if loc.is_global else "收藏成功", "id": str(row.id)}


@router.delete("/{favorite_id}")
async def remove_favorite(
    favorite_id: str,
    user_id: str = Query(..., description="用户ID"),
    db: Session = Depends(get_db),
    loc: RequestLocale = Depends(request_locale),
):
    """删除收藏。路径里可以是收藏记录 id，也可以是内容 id（App 按内容 id 取消收藏）。"""
    rows = db.query(Favorite).filter(Favorite.id == favorite_id, Favorite.user_id == user_id).all()
    if not rows:
        rows = db.query(Favorite).filter(Favorite.content_id == favorite_id, Favorite.user_id == user_id).all()
    if not rows:
        raise HTTPException(status_code=404, detail="Favorite not found" if loc.is_global else "收藏记录不存在")
    for r in rows:
        db.delete(r)
    db.commit()
    return {"success": True, "message": "Removed" if loc.is_global else "取消收藏成功"}


@router.get("/check")
async def check_favorite(
    user_id: str = Query(..., description="用户ID"),
    content_id: str = Query(..., description="内容ID"),
    db: Session = Depends(get_db),
):
    """检查是否已收藏"""
    row = db.query(Favorite).filter(Favorite.user_id == user_id, Favorite.content_id == content_id).first()
    fav = {"is_favorited": row is not None, "favorite_id": str(row.id) if row else None}
    return {"success": True, **fav, "data": fav}
