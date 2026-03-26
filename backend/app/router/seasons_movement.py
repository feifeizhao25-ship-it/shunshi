"""
SEASONS Movement Practices API
GET /api/v1/seasons/practices
GET /api/v1/seasons/practices/{id}
GET /api/v1/seasons/practices/recommended
"""
from fastapi import APIRouter, Query, HTTPException
from typing import Optional
import psycopg2
import psycopg2.extras

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-movement"])
DB_CONFIG = {
    "host": "127.0.0.1",
    "dbname": "shunshi",
    "user": "shunshi",
    "password": "shunshi123",
}

def get_conn():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=psycopg2.extras.RealDictCursor)

def mov_to_dict(r):
    return {
        "id": str(r["id"]),
        "title": r["title"],
        "category": r["category"],
        "description": r.get("description") or "",
        "duration_minutes": r.get("duration_minutes") or 10,
        "difficulty": r.get("difficulty") or "beginner",
        "steps": r.get("steps") or [],
        "equipment_needed": r.get("equipment_needed") or [],
        "benefits": r.get("benefits") or [],
        "contraindications": r.get("contraindications") or "",
        "cover_image_url": r.get("cover_image_url") or "",
        "video_url": r.get("video_url") or "",
        "is_premium": r.get("is_premium") or False,
    }

@router.get("/practices")
async def list_practices(
    category: Optional[str] = None,
    season: Optional[str] = None,
    difficulty: Optional[str] = None,
    page: int = Query(1),
    limit: int = Query(20),
):
    conn = get_conn()
    cur = conn.cursor()
    try:
        query = "SELECT * FROM movement_practices WHERE 1=1"
        params = []
        if category:
            query += " AND category = %s"
            params.append(category)
        if difficulty:
            query += " AND difficulty = %s"
            params.append(difficulty)
        query += " ORDER BY id LIMIT %s OFFSET %s"
        params.extend([limit, (page-1)*limit])
        cur.execute(query, params)
        rows = cur.fetchall()
        if season:
            rows = [r for r in rows if season in (r.get("seasons") or [])]
        return [mov_to_dict(r) for r in rows]
    finally:
        cur.close(); conn.close()

@router.get("/practices/recommended")
async def recommended_practices(season: Optional[str] = Query("spring"), limit: int = Query(3)):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT * FROM movement_practices ORDER BY id LIMIT %s",
            (limit,)
        )
        rows = cur.fetchall()
        if season:
            rows = [r for r in rows if season in (r.get("seasons") or [])]
        return [mov_to_dict(r) for r in rows[:limit]]
    finally:
        cur.close(); conn.close()

@router.get("/practices/{practice_id}")
async def get_practice(practice_id: str):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT * FROM movement_practices WHERE id = %s", (practice_id,))
        r = cur.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Practice not found")
        return mov_to_dict(r)
    finally:
        cur.close(); conn.close()
