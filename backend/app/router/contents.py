# 内容系统 API 路由
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from app.database.db import get_db

router = APIRouter(prefix="/api/v1/contents", tags=["内容"])

# ============ Models ============

class Content(BaseModel):
    id: str
    title: str
    description: str
    type: str
    category: str
    tags: List[str]
    difficulty: Optional[str] = None
    time: Optional[str] = None
    duration: Optional[str] = None
    ingredients: Optional[List[str]] = None
    steps: Optional[List[str]] = None
    location: Optional[str] = None
    method: Optional[str] = None
    effect: Optional[str] = None
    benefits: Optional[List[str]] = None
    best_time: Optional[str] = None
    view_count: int = 0
    like_count: int = 0
    created_at: str = "2026-01-01T00:00:00Z"

# ============ Helper Functions ============

def _parse_json_str(s):
    """安全解析 JSON 字符串"""
    if not s:
        return []
    import json
    try:
        val = json.loads(s)
        return val if isinstance(val, list) else []
    except (json.JSONDecodeError, TypeError):
        return []


def _content_row_to_dict(row) -> dict:
    """将数据库行转为 API 格式"""
    d = dict(row)
    d["tags"] = _parse_json_str(d.get("tags"))
    d["ingredients"] = _parse_json_str(d.get("ingredients"))
    d["steps"] = _parse_json_str(d.get("steps"))
    d["benefits"] = _parse_json_str(d.get("benefits"))
    return d


def search_contents(db, query: str = None, type: str = None, category: str = None, tags: List[str] = None, locale: str = "zh-CN"):
    """搜索内容"""
    sql = "SELECT * FROM contents WHERE 1=1"
    params = []
    
    if locale:
        sql += " AND locale = ?"
        params.append(locale)
    if query:
        sql += " AND (title LIKE ? OR description LIKE ?)"
        params.extend([f"%{query}%", f"%{query}%"])
    if type:
        sql += " AND type = ?"
        params.append(type)
    if category:
        sql += " AND category = ?"
        params.append(category)
    if tags:
        for tag in tags:
            sql += " AND tags LIKE ?"
            params.append(f'%"{tag}"%')
    
    sql += " ORDER BY created_at DESC"
    
    return db.execute(sql, params).fetchall()

# ============ API Endpoints ============

@router.get("", response_model=dict)
async def get_contents(
    type: str = Query(None, description="内容类型: recipe/acupoint/exercise/tips"),
    category: str = Query(None),
    tags: str = Query(None),
    query: str = Query(None, description="搜索关键词"),
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100)
):
    """获取内容列表"""
    db = get_db()
    tag_list = tags.split(',') if tags else None
    
    rows = search_contents(db, query, type, category, tag_list, locale)
    total = len(rows)
    
    start = (page - 1) * limit
    items = [_content_row_to_dict(r) for r in rows[start:start + limit]]
    
    return {
        "success": True,
        "data": {
            "items": items,
            "total": total,
            "page": page,
            "limit": limit
        }
    }

@router.get("/types", response_model=dict)
async def get_content_types(locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """获取内容类型"""
    if locale == "en-US":
        types = [
            {"id": "recipe", "name": "Food Therapy", "icon": "🍵"},
            {"id": "acupoint", "name": "Acupressure", "icon": "💆"},
            {"id": "exercise", "name": "Exercise", "icon": "🏃"},
            {"id": "tips", "name": "Wellness Tips", "icon": "💡"},
        ]
    else:
        types = [
            {"id": "recipe", "name": "食疗", "icon": "🍵"},
            {"id": "acupoint", "name": "穴位", "icon": "💆"},
            {"id": "exercise", "name": "运动", "icon": "🏃"},
            {"id": "tips", "name": "养生小贴士", "icon": "💡"},
        ]
    return {"success": True, "data": types}

@router.get("/categories", response_model=dict)
async def get_categories(type: str = Query(None), locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """获取分类"""
    if locale == "en-US":
        en_categories = {
            "recipe": ["Tea", "Congee", "Soup", "Dessert", "Cold Dishes", "Hot Dishes"],
            "food_therapy": ["Spring Diet Therapy", "Summer Diet Therapy", "Autumn Diet Therapy", "Winter Diet Therapy"],
            "acupoint": ["Head Acupoints", "Upper Limb Acupoints", "Lower Limb Acupoints", "Back Acupoints"],
            "exercise": ["Traditional Exercises", "Daily Exercise", "Seasonal Exercise"],
            "tips": ["Sleep Techniques", "Bedtime Habits", "Sleep Environment"],
            "sleep_tip": ["Sleep Techniques", "Bedtime Habits", "Sleep Environment"],
            "tea": ["Spring Tea", "Summer Tea", "Autumn Tea", "Winter Tea"],
            "acupressure": ["Head Acupoints", "Upper Limb Acupoints", "Lower Limb Acupoints", "Back Acupoints"],
        }
        categories = en_categories.get(type, [])
    else:
        if type == "recipe":
            categories = ["茶饮", "粥品", "汤品", "甜品", "凉菜", "热菜"]
        elif type == "acupoint":
            categories = ["穴位"]
        elif type == "exercise":
            categories = ["传统功法", "有氧", "力量", "柔韧", "静功"]
        elif type == "tips":
            categories = ["睡眠", "情绪", "生活", "季节"]
        else:
            categories = []
    
    return {"success": True, "data": categories}

@router.get("/search", response_model=dict)
async def search(
    q: str = Query(..., description="搜索关键词"),
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
    limit: int = Query(20, ge=1, le=100)
):
    """搜索内容"""
    db = get_db()
    rows = db.execute("""
        SELECT * FROM contents 
        WHERE (title LIKE ? OR description LIKE ?) AND locale = ?
        ORDER BY created_at DESC LIMIT ?
    """, (f"%{q}%", f"%{q}%", locale, limit)).fetchall()
    
    items = [_content_row_to_dict(r) for r in rows]
    
    return {
        "success": True,
        "data": {
            "items": items,
            "total": len(items),
            "query": q
        }
    }

@router.get("/recommend", response_model=dict)
async def get_recommend(
    user_id: str = Query("user-001"),
    type: Optional[str] = Query(None, description="内容类型过滤"),
    season: Optional[str] = Query(None, description="季节过滤: spring/summer/autumn/winter"),
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
    limit: int = Query(10, ge=1, le=20)
):
    """个性化推荐内容 - 基于用户偏好 + 当前季节 + 随机探索
    
    推荐权重: 用户偏好60% + 季节相关30% + 随机探索10%
    """
    import random
    db = get_db()
    
    # 确定当前季节
    month = datetime.now().month
    season_map = {1: "winter", 2: "spring", 3: "spring", 4: "spring", 5: "spring", 6: "summer",
                  7: "summer", 8: "summer", 9: "autumn", 10: "autumn", 11: "autumn", 12: "winter"}
    current_season = season or season_map.get(month, "spring")
    
    # 1. 用户偏好 (60%) - 查询用户最近的care_records中最常查看的type
    user_pref_types = []
    try:
        pref_rows = db.execute("""
            SELECT type, COUNT(*) as cnt FROM contents 
            WHERE locale = ? AND type IS NOT NULL
            GROUP BY type ORDER BY cnt DESC LIMIT 3
        """, (locale,)).fetchall()
        # 如果用户有follow_up或care_status记录，用其type偏好
        follow_rows = db.execute("""
            SELECT type, COUNT(*) as cnt FROM follow_ups 
            WHERE user_id = ? AND status = 'completed'
            GROUP BY type ORDER BY cnt DESC LIMIT 3
        """, (user_id,)).fetchall()
        if follow_rows:
            user_pref_types = [r["type"] for r in follow_rows]
        elif pref_rows:
            user_pref_types = [r["type"] for r in pref_rows]
    except Exception:
        pass
    
    # 2. 季节相关 (30%) - 匹配season_tag
    season_items = []
    try:
        season_rows = db.execute("""
            SELECT * FROM contents 
            WHERE locale = ? AND season_tag = ?
            ORDER BY RANDOM() LIMIT ?
        """, (locale, current_season, max(limit // 3, 3))).fetchall()
        season_items = [_content_row_to_dict(r) for r in season_rows]
    except Exception:
        pass
    
    # 3. 随机探索 (10%)
    random_items = []
    try:
        random_rows = db.execute("""
            SELECT * FROM contents WHERE locale = ? ORDER BY RANDOM() LIMIT ?
        """, (locale, max(limit // 10, 1))).fetchall()
        random_items = [_content_row_to_dict(r) for r in random_rows]
    except Exception:
        pass
    
    # 4. 用户偏好内容 (60%)
    pref_items = []
    try:
        if user_pref_types and type:
            types_filter = ",".join([f"'{t}'" for t in user_pref_types[:3]])
            pref_rows = db.execute(f"""
                SELECT * FROM contents WHERE locale = ? AND type IN ({types_filter})
                ORDER BY RANDOM() LIMIT ?
            """, (locale, max(limit * 6 // 10, 3))).fetchall()
            pref_items = [_content_row_to_dict(r) for r in pref_rows]
        elif user_pref_types:
            types_filter = ",".join([f"'{t}'" for t in user_pref_types[:3]])
            pref_rows = db.execute(f"""
                SELECT * FROM contents WHERE locale = ? AND type IN ({types_filter})
                ORDER BY RANDOM() LIMIT ?
            """, (locale, max(limit * 6 // 10, 3))).fetchall()
            pref_items = [_content_row_to_dict(r) for r in pref_rows]
        else:
            # 无偏好，取全部类型
            all_types_filter = ""
            if type:
                all_types_filter = f" AND type = '{type}'"
            pref_rows = db.execute(f"""
                SELECT * FROM contents WHERE locale = ?{all_types_filter}
                ORDER BY RANDOM() LIMIT ?
            """, (locale, max(limit * 6 // 10, 3))).fetchall()
            pref_items = [_content_row_to_dict(r) for r in pref_rows]
    except Exception:
        pass
    
    # 合并去重
    seen_ids = set()
    merged = []
    for item in pref_items + season_items + random_items:
        if item["id"] not in seen_ids:
            seen_ids.add(item["id"])
            merged.append(item)
    
    # 如果类型过滤，额外筛选
    if type:
        merged = [item for item in merged if item.get("type") == type]
    
    return {
        "success": True,
        "data": {
            "items": merged[:limit],
            "total": len(merged[:limit]),
            "season": current_season,
            "user_preferences": user_pref_types[:3] if user_pref_types else [],
        }
    }

@router.get("/{content_id}", response_model=dict)
async def get_content(content_id: str):
    """获取内容详情"""
    db = get_db()
    
    row = db.execute("SELECT * FROM contents WHERE id = ?", (content_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")
    
    # 增加浏览次数
    db.execute("UPDATE contents SET view_count = view_count + 1 WHERE id = ?", (content_id,))
    db.commit()
    
    item = _content_row_to_dict(row)
    item["view_count"] = item.get("view_count", 0) + 1
    
    return {"success": True, "data": item}

@router.post("/{content_id}/like")
async def like_content(content_id: str):
    """点赞内容"""
    db = get_db()
    
    row = db.execute("SELECT * FROM contents WHERE id = ?", (content_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="内容不存在")
    
    db.execute("UPDATE contents SET like_count = like_count + 1 WHERE id = ?", (content_id,))
    db.commit()
    
    new_count = (row["like_count"] or 0) + 1
    
    return {"success": True, "like_count": new_count}
