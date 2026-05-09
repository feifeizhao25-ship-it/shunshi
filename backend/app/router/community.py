"""
顺时 — 社区 API (shunshi-community)
用户养生社区、帖子、评论、点赞 (PostgreSQL backed)
"""
import uuid
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.wellness_tracking import CommunityPost, CommunityComment

router = APIRouter(prefix="/api/v1/community", tags=["community"])

_CATEGORIES = [
    {"id": "constitution", "name": "体质养生", "icon": "🌿"},
    {"id": "food", "name": "食疗药膳", "icon": "🍲"},
    {"id": "exercise", "name": "功法运动", "icon": "🧘"},
    {"id": "seasonal", "name": "节气养生", "icon": "🌸"},
    {"id": "emotion", "name": "情志调养", "icon": "💆"},
    {"id": "experience", "name": "心得分享", "icon": "✨"},
    {"id": "general", "name": "综合讨论", "icon": "💬"},
]


class PostIn(BaseModel):
    user_id: str
    content: str = Field(..., min_length=5)
    category: str = "general"
    tags: List[str] = []


class CommentIn(BaseModel):
    user_id: str
    content: str = Field(..., min_length=2)


class LikeIn(BaseModel):
    user_id: str


def _post_to_dict(p: CommunityPost) -> dict:
    return {
        "post_id": str(p.id),
        "user_id": p.user_id,
        "content": p.content,
        "category": p.category,
        "tags": p.tags,
        "likes": p.likes,
        "comment_count": p.comment_count,
        "is_featured": p.is_featured,
        "created_at": p.created_at.isoformat(),
    }


@router.get("/posts", summary="社区帖子列表")
def list_posts(
    category: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=50),
    sort: str = Query("latest", enum=["latest", "popular"]),
    db: Session = Depends(get_db),
):
    q = db.query(CommunityPost).filter(CommunityPost.is_active == True)  # noqa: E712
    if category:
        q = q.filter(CommunityPost.category == category)
    if sort == "popular":
        q = q.order_by(CommunityPost.likes.desc())
    else:
        q = q.order_by(CommunityPost.created_at.desc())
    total = q.count()
    posts = q.offset((page - 1) * page_size).limit(page_size).all()
    return {
        "success": True,
        "data": {
            "posts": [_post_to_dict(p) for p in posts],
            "total": total,
            "page": page,
        }
    }


@router.post("/posts", summary="发布帖子")
def create_post(body: PostIn, db: Session = Depends(get_db)):
    post = CommunityPost(
        id=uuid.uuid4(),
        user_id=body.user_id,
        content=body.content,
        category=body.category,
        tags=body.tags,
        likes=0,
        comment_count=0,
        is_featured=False,
        is_active=True,
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return {"success": True, "data": _post_to_dict(post)}


@router.get("/posts/{post_id}", summary="帖子详情")
def get_post(post_id: str, db: Session = Depends(get_db)):
    try:
        pid = uuid.UUID(post_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="帖子不存在")
    post = db.query(CommunityPost).filter(
        CommunityPost.id == pid,
        CommunityPost.is_active == True,  # noqa: E712
    ).first()
    if not post:
        raise HTTPException(status_code=404, detail="帖子不存在")
    return {"success": True, "data": _post_to_dict(post)}


@router.post("/posts/{post_id}/like", summary="点赞帖子")
def like_post(post_id: str, body: LikeIn, db: Session = Depends(get_db)):
    try:
        pid = uuid.UUID(post_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="帖子不存在")
    post = db.query(CommunityPost).filter(CommunityPost.id == pid).first()
    if not post:
        raise HTTPException(status_code=404, detail="帖子不存在")
    post.likes += 1
    post.updated_at = datetime.now()
    db.commit()
    return {
        "success": True,
        "data": {"post_id": post_id, "likes": post.likes, "message": "点赞成功"}
    }


@router.get("/posts/{post_id}/comments", summary="帖子评论")
def get_comments(
    post_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db),
):
    try:
        pid = uuid.UUID(post_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="帖子不存在")
    total = db.query(CommunityComment).filter(CommunityComment.post_id == pid).count()
    comments = db.query(CommunityComment).filter(
        CommunityComment.post_id == pid,
    ).order_by(CommunityComment.created_at.asc()).offset((page - 1) * page_size).limit(page_size).all()
    return {
        "success": True,
        "data": {
            "comments": [
                {
                    "comment_id": str(c.id),
                    "user_id": c.user_id,
                    "content": c.content,
                    "likes": c.likes,
                    "created_at": c.created_at.isoformat(),
                }
                for c in comments
            ],
            "total": total,
            "page": page,
        }
    }


@router.post("/posts/{post_id}/comments", summary="发表评论")
def add_comment(post_id: str, body: CommentIn, db: Session = Depends(get_db)):
    try:
        pid = uuid.UUID(post_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="帖子不存在")
    post = db.query(CommunityPost).filter(CommunityPost.id == pid).first()
    if not post:
        raise HTTPException(status_code=404, detail="帖子不存在")
    comment = CommunityComment(
        id=uuid.uuid4(),
        post_id=pid,
        user_id=body.user_id,
        content=body.content,
        likes=0,
        created_at=datetime.now(),
    )
    db.add(comment)
    post.comment_count += 1
    post.updated_at = datetime.now()
    db.commit()
    db.refresh(comment)
    return {
        "success": True,
        "data": {
            "comment_id": str(comment.id),
            "post_id": post_id,
            "content": body.content,
            "created_at": comment.created_at.isoformat(),
        }
    }


@router.get("/categories", summary="社区分类")
def get_categories():
    return {"success": True, "data": {"categories": _CATEGORIES}}


@router.get("/featured", summary="精选内容")
def get_featured(db: Session = Depends(get_db)):
    posts = db.query(CommunityPost).filter(
        CommunityPost.is_featured == True,  # noqa: E712
        CommunityPost.is_active == True,    # noqa: E712
    ).order_by(CommunityPost.created_at.desc()).limit(10).all()
    return {
        "success": True,
        "data": {
            "featured_posts": [_post_to_dict(p) for p in posts],
            "total": len(posts),
        }
    }
