"""
SEASONS Articles API
GET /api/v1/seasons/articles
GET /api/v1/seasons/articles/{slug_or_id}
GET /api/v1/seasons/articles/recommended
"""
from fastapi import APIRouter, Query, HTTPException
from typing import Optional
import psycopg2
import psycopg2.extras

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-articles"])
DB_CONFIG = {
    "host": "127.0.0.1",
    "dbname": "shunshi",
    "user": "shunshi",
    "password": "shunshi123",
}

def get_conn():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=psycopg2.extras.RealDictCursor)

def art_to_dict(r):
    return {
        "id": str(r["id"]),
        "title": r["title"],
        "subtitle": r["subtitle"] or "",
        "content_markdown": r.get("content_markdown") or "",
        "content_html": r.get("content_html") or "",
        "excerpt": r.get("excerpt") or (r.get("content_markdown", "")[:120] if r.get("content_markdown") else ""),
        "category": r["category"],
        "tags": r.get("tags") or [],
        "cover_image_url": r.get("cover_image_url") or "",
        "author_name": r.get("author_name") or "",
        "reading_time_minutes": r.get("reading_time_minutes") or 3,
        "view_count": r.get("view_count") or 0,
        "like_count": r.get("like_count") or 0,
        "is_premium": r.get("is_premium") or False,
    }

@router.get("/articles")
async def list_articles(
    category: Optional[str] = None,
    season: Optional[str] = None,
    page: int = Query(1),
    limit: int = Query(20),
):
    conn = get_conn()
    cur = conn.cursor()
    try:
        query = "SELECT * FROM articles WHERE is_published = true"
        params = []
        if category:
            query += " AND category = %s"
            params.append(category)
        if season:
            query += " AND (season_codes::text ILIKE %s OR season_codes = '[]')"
            params.append(f"%{season}%")
        query += " ORDER BY published_at DESC NULLS LAST LIMIT %s OFFSET %s"
        params.extend([limit, (page-1)*limit])
        cur.execute(query, params)
        return [art_to_dict(r) for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()

@router.get("/articles/recommended")
async def recommended_articles(season: Optional[str] = Query(None), limit: int = Query(5)):
    conn = get_conn()
    cur = conn.cursor()
    try:
        if season:
            cur.execute(
                "SELECT * FROM articles WHERE is_published = true AND season_codes::text ILIKE %s ORDER BY view_count DESC LIMIT %s",
                (f"%{season}%", limit)
            )
        else:
            cur.execute("SELECT * FROM articles WHERE is_published = true ORDER BY view_count DESC LIMIT %s", (limit,))
        return [art_to_dict(r) for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()

@router.get("/articles/{slug_or_id}")
async def get_article(slug_or_id: str):
    conn = get_conn()
    cur = conn.cursor()
    try:
        # Try by slug first, then by id
        cur.execute("SELECT * FROM articles WHERE slug = %s OR id::text = %s", (slug_or_id, slug_or_id))
        r = cur.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Article not found")
        # Increment view count
        cur.execute("UPDATE articles SET view_count = view_count + 1 WHERE id = %s", (r["id"],))
        conn.commit()
        return art_to_dict(r)
    finally:
        cur.close(); conn.close()
