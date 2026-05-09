from __future__ import annotations

"""文章/资讯模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, TIMESTAMP, Text, JSON
from app.db.types import GUID
from app.models.base import Base


class Article(Base):
    __tablename__ = "sa_articles"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    title = Column(String(200), nullable=False)
    title_en = Column(String(200))
    subtitle = Column(String(300))
    author = Column(String(100))
    author_id = Column(String(64))
    category = Column(String(50), default="wellness")  # wellness / tcm / nutrition / lifestyle
    tags = Column(JSON, default=[])
    summary = Column(Text)
    content = Column(Text, nullable=False)
    content_blocks = Column(JSON, default=[])  # 结构化内容块
    cover_image = Column(String(500))
    images = Column(JSON, default=[])
    read_time_min = Column(Integer, default=3)
    tcm_concepts = Column(JSON, default=[])
    related_recipes = Column(JSON, default=[])
    related_exercises = Column(JSON, default=[])
    related_teas = Column(JSON, default=[])
    season = Column(String(20), default="all")
    is_premium = Column(Boolean, default=False)
    is_featured = Column(Boolean, default=False)
    is_published = Column(Boolean, default=False)
    published_at = Column(TIMESTAMP)
    view_count = Column(Integer, default=0)
    like_count = Column(Integer, default=0)
    share_count = Column(Integer, default=0)
    status = Column(String(20), default="draft")  # draft / review / published / archived
    created_at = Column(TIMESTAMP, default=datetime.now)
    updated_at = Column(TIMESTAMP, default=datetime.now, onupdate=datetime.now)


class ArticleBookmark(Base):
    __tablename__ = "sa_article_bookmarks"
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(64), nullable=False, index=True)
    article_id = Column(GUID(), nullable=False, index=True)
    created_at = Column(TIMESTAMP, default=datetime.now)
