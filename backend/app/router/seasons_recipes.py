"""
SEASONS Recipes API
GET /api/v1/seasons/recipes
GET /api/v1/seasons/recipes/{id}
GET /api/v1/seasons/recipes/recommended
"""
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import psycopg2
import os
import json

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons-recipes"])

DB_CONFIG = {
    "host": "127.0.0.1",
    "dbname": "shunshi",
    "user": "shunshi",
    "password": "shunshi123",
}

def get_conn():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=psycopg2.extras.RealDictCursor)


def recipe_to_dict(r):
    return {
        "id": str(r["id"]),
        "title": r["title"],
        "subtitle": r["subtitle"] or "",
        "category": r["category"],
        "seasons": r.get("seasons") or [],
        "functions": r.get("functions") or [],
        "servings": r.get("servings") or 2,
        "prep_time": r.get("prep_time") or 0,
        "cook_time": r.get("cook_time") or 0,
        "difficulty": r.get("difficulty") or 1,
        "ingredients": r.get("ingredients") or [],
        "steps": r.get("steps") or [],
        "tips": r.get("tips") or "",
        "nutrition": r.get("nutrition") or {},
        "cover_image_url": r.get("cover_image_url") or "",
        "is_premium": r.get("is_premium") or False,
    }


@router.get("/recipes")
async def list_recipes(
    category: Optional[str] = None,
    season: Optional[str] = None,
    type: Optional[str] = None,
    page: int = Query(1),
    limit: int = Query(20),
):
    """List recipes with optional filtering"""
    conn = get_conn()
    cur = conn.cursor()
    try:
        query = "SELECT * FROM recipes WHERE is_published = true"
        params = []
        if category:
            query += " AND category = %s"
            params.append(category)
        if season:
            query += " AND seasons::text ILIKE %s"
            params.append(f"%{season}%")
        query += " ORDER BY created_at DESC"
        offset = (page - 1) * limit
        query += f" LIMIT {limit} OFFSET {offset}"
        cur.execute(query, params)
        rows = cur.fetchall()
        return [recipe_to_dict(r) for r in rows]
    finally:
        cur.close()
        conn.close()


@router.get("/recipes/recommended")
async def recommended_recipes(
    season: Optional[str] = Query(None),
    body_type: Optional[str] = Query(None),
    limit: int = Query(5),
):
    """Get recommended recipes based on season and body type"""
    conn = get_conn()
    cur = conn.cursor()
    try:
        query = "SELECT * FROM recipes WHERE is_published = true"
        params = []
        if season:
            query += " AND seasons::text ILIKE %s"
            params.append(f"%{season}%")
        query += " ORDER BY save_count DESC, like_count DESC LIMIT %s"
        params.append(limit)
        cur.execute(query, params)
        rows = cur.fetchall()
        return [recipe_to_dict(r) for r in rows]
    finally:
        cur.close()
        conn.close()


@router.get("/recipes/{recipe_id}")
async def get_recipe(recipe_id: str):
    """Get recipe detail"""
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT * FROM recipes WHERE id = %s", (recipe_id,))
        r = cur.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Recipe not found")
        return recipe_to_dict(r)
    finally:
        cur.close()
        conn.close()
