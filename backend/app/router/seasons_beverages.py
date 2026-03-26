"""
SEASONS Beverages API
GET /api/v1/seasons/beverages
GET /api/v1/seasons/beverages/{id}
GET /api/v1/seasons/beverages/recommended
"""
from fastapi import APIRouter, Query, HTTPException
from typing import Optional
import psycopg2
import psycopg2.extras

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-beverages"])
DB_CONFIG = {
    "host": "127.0.0.1",
    "dbname": "shunshi",
    "user": "shunshi",
    "password": "shunshi123",
}

def get_conn():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=psycopg2.extras.RealDictCursor)

def bev_to_dict(r):
    return {
        "id": str(r["id"]),
        "name": r["name"],
        "type": r["type"],
        "ingredients": r.get("ingredients") or [],
        "preparation_method": r.get("preparation_method") or "",
        "water_temperature": r.get("water_temperature") or 0,
        "steeping_time": r.get("steep_time") or 0,
        "benefits": r.get("benefits") or [],
        "best_time": r.get("best_time") or "any",
        "contraindications": r.get("contraindications") or "",
        "cover_image_url": r.get("cover_image_url") or "",
        "is_premium": r.get("is_premium") or False,
    }

@router.get("/beverages")
async def list_beverages(type: Optional[str] = None, season: Optional[str] = None, page: int = Query(1), limit: int = Query(20)):
    conn = get_conn()
    cur = conn.cursor()
    try:
        query = "SELECT * FROM beverages WHERE 1=1"
        params = []
        if type:
            query += " AND type = %s"
            params.append(type)
        if season:
            query += " AND (benefits::text ILIKE %s OR best_time = 'any')"
            params.append(f"%{season}%")
        query += " ORDER BY id LIMIT %s OFFSET %s"
        params.extend([limit, (page-1)*limit])
        cur.execute(query, params)
        return [bev_to_dict(r) for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()

@router.get("/beverages/recommended")
async def recommended_beverages(season: Optional[str] = Query("spring"), time_of_day: Optional[str] = Query("evening"), limit: int = Query(3)):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT * FROM beverages WHERE best_time IN (%s, 'any') ORDER BY id LIMIT %s",
            (time_of_day, limit)
        )
        return [bev_to_dict(r) for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()

@router.get("/beverages/{beverage_id}")
async def get_beverage(beverage_id: str):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT * FROM beverages WHERE id = %s", (beverage_id,))
        r = cur.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Beverage not found")
        return bev_to_dict(r)
    finally:
        cur.close(); conn.close()
