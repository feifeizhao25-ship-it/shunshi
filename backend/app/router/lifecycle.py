"""
顺时 - 生命周期 API 路由
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, Dict, Any

from app.database.db import get_db
from app.services.lifecycle_engine import lifecycle_engine, LifeStage, STAGE_CONFIGS_EN

router = APIRouter(prefix="/api/v1/lifecycle", tags=["生命周期"])


# ============ Models ============

class LifecycleProfile(BaseModel):
    """生命周期档案"""
    birth_year: int
    gender: Optional[str] = None
    name: Optional[str] = None


class LifecycleProfileResponse(BaseModel):
    """生命周期档案响应"""
    user_id: str
    birth_year: Optional[int] = None
    age: Optional[int] = None
    life_stage: Optional[str] = None
    stage_name: Optional[str] = None
    gender: Optional[str] = None
    updated_at: Optional[str] = None


# ============ 生命周期档案存储 ============

# 使用 users 表的 birthday 字段存储出生年份
# 额外信息存到 user_settings 或直接在 users 表中

def _get_user_lifecycle_data(user_id: str) -> Optional[Dict[str, Any]]:
    """获取用户生命周期数据"""
    conn = get_db()
    row = conn.execute(
        "SELECT id, name, birthday, gender FROM users WHERE id = ?",
        (user_id,),
    ).fetchone()
    if not row:
        return None
    d = dict(row)
    birth_year = None
    if d.get("birthday"):
        try:
            birth_year = int(d["birthday"][:4])
        except (ValueError, TypeError, IndexError):
            pass
    d["birth_year"] = birth_year
    return d


def _update_user_lifecycle(
    user_id: str, birth_year: int, gender: Optional[str] = None
):
    """更新用户生命周期数据"""
    conn = get_db()
    # 用出生年份构建简单的birthday字符串
    birthday = f"{birth_year}-01-01"

    if gender:
        conn.execute(
            "UPDATE users SET birthday = ?, gender = ?, updated_at = datetime('now') WHERE id = ?",
            (birthday, gender, user_id),
        )
    else:
        conn.execute(
            "UPDATE users SET birthday = ?, updated_at = datetime('now') WHERE id = ?",
            (birthday, user_id),
        )
    conn.commit()


# ============ API 端点 ============

@router.get("/stage")
async def get_life_stage(user_id: str = Query(..., description="用户ID"), locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """
    获取当前用户的生命阶段

    如果用户没有设置出生年份，返回提示信息
    """
    user_data = _get_user_lifecycle_data(user_id)
    if not user_data:
        raise HTTPException(status_code=404, detail="用户不存在")

    birth_year = user_data.get("birth_year")
    if not birth_year:
        return {
            "user_id": user_id,
            "life_stage": None,
            "stage_name": None,
            "message": "请先设置出生年份以获取个性化推荐" if locale == "zh-CN" else "Please set your birth year for personalized recommendations",
        }

    stage = lifecycle_engine.detect_life_stage(birth_year)
    age = lifecycle_engine.get_age(birth_year)
    config = lifecycle_engine.get_stage_config(stage)
    en_config = STAGE_CONFIGS_EN.get(stage, {})

    result = {
        "user_id": user_id,
        "birth_year": birth_year,
        "age": age,
        "life_stage": stage.value,
        "stage_name": en_config.get("name", config["name"]) if locale == "en-US" else config["name"],
        "age_range": en_config.get("age_range", config["age_range"]) if locale == "en-US" else config["age_range"],
        "description": en_config.get("description", config["description"]) if locale == "en-US" else config["description"],
        "focus_areas": en_config.get("focus_areas", config["focus_areas"]) if locale == "en-US" else config["focus_areas"],
        "ai_tone": en_config.get("ai_tone", config["ai_tone"]) if locale == "en-US" else config["ai_tone"],
    }

    if locale == "en-US":
        result["health_priorities"] = en_config.get("health_priorities", config["health_priorities"])
    else:
        result["health_priorities"] = config["health_priorities"]

    return result


@router.put("/profile")
async def update_lifecycle_profile(
    user_id: str = Query(..., description="用户ID"),
    profile: LifecycleProfile = None,
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
):
    """
    更新用户生命周期档案

    设置出生年份、性别等信息
    """
    import json
    from fastapi import Request

    # 确保用户存在
    conn = get_db()
    row = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="用户不存在")

    _update_user_lifecycle(
        user_id,
        birth_year=profile.birth_year,
        gender=profile.gender,
    )

    # 返回更新后的数据
    stage = lifecycle_engine.detect_life_stage(profile.birth_year)
    age = lifecycle_engine.get_age(profile.birth_year)
    config = lifecycle_engine.get_stage_config(stage)
    en_config = STAGE_CONFIGS_EN.get(stage, {})

    return {
        "user_id": user_id,
        "birth_year": profile.birth_year,
        "age": age,
        "life_stage": stage.value,
        "stage_name": en_config.get("name", config["name"]) if locale == "en-US" else config["name"],
        "updated": True,
    }


@router.get("/recommendations")
async def get_recommendations(
    user_id: str = Query(..., description="用户ID"),
    solar_term: Optional[str] = Query(None, description="当前节气名称"),
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
):
    """
    获取基于生命阶段的个性化推荐

    包含：健康优先事项、关键习惯、作息建议、节气调整
    """
    user_data = _get_user_lifecycle_data(user_id)
    if not user_data:
        raise HTTPException(status_code=404, detail="用户不存在")

    birth_year = user_data.get("birth_year")
    if not birth_year:
        return {
            "user_id": user_id,
            "message": "请先设置出生年份以获取个性化推荐" if locale == "zh-CN" else "Please set your birth year for personalized recommendations",
        }

    stage = lifecycle_engine.detect_life_stage(birth_year)
    config = lifecycle_engine.get_stage_config(stage)
    en_config = STAGE_CONFIGS_EN.get(stage, {})
    rhythm = lifecycle_engine.get_daily_rhythm(stage)

    result = {
        "user_id": user_id,
        "life_stage": stage.value,
        "stage_name": en_config.get("name", config["name"]) if locale == "en-US" else config["name"],
        "health_priorities": en_config.get("health_priorities", config["health_priorities"]) if locale == "en-US" else config["health_priorities"],
        "key_habits": en_config.get("key_habits", config["key_habits"]) if locale == "en-US" else config["key_habits"],
        "avoid": en_config.get("avoid", config["avoid"]) if locale == "en-US" else config["avoid"],
        "recommended_content_types": config["recommended_content_types"],
        "daily_rhythm": rhythm,
    }

    if solar_term:
        seasonal = lifecycle_engine.get_seasonal_adjustment(stage, solar_term)
        result["seasonal"] = seasonal

    return result


@router.get("/seasonal/{solar_term}")
async def get_seasonal_advice(
    user_id: str = Query(..., description="用户ID"),
    solar_term: str = ...,
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
):
    """
    获取特定节气的养生建议

    根据用户生命阶段提供个性化的节气养生指导
    """
    user_data = _get_user_lifecycle_data(user_id)
    if not user_data:
        raise HTTPException(status_code=404, detail="用户不存在")

    birth_year = user_data.get("birth_year")
    if not birth_year:
        # 没有出生年份时返回通用建议
        stage = LifeStage.STABLE  # 默认使用稳定期
    else:
        stage = lifecycle_engine.detect_life_stage(birth_year)

    seasonal = lifecycle_engine.get_seasonal_adjustment(stage, solar_term)
    config = lifecycle_engine.get_stage_config(stage)
    en_config = STAGE_CONFIGS_EN.get(stage, {})

    return {
        "user_id": user_id,
        "life_stage": stage.value,
        "stage_name": en_config.get("name", config["name"]) if locale == "en-US" else config["name"],
        "solar_term": solar_term,
        **seasonal,
    }


@router.get("/rhythm")
async def get_daily_rhythm(user_id: str = Query(..., description="用户ID"), locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """
    获取日常作息建议

    根据生命阶段提供个性化的作息、饮食、运动建议
    """
    user_data = _get_user_lifecycle_data(user_id)
    if not user_data:
        raise HTTPException(status_code=404, detail="用户不存在")

    birth_year = user_data.get("birth_year")
    if not birth_year:
        return {
            "user_id": user_id,
            "message": "请先设置出生年份以获取个性化作息建议" if locale == "zh-CN" else "Please set your birth year for personalized rhythm recommendations",
        }

    stage = lifecycle_engine.detect_life_stage(birth_year)
    rhythm = lifecycle_engine.get_daily_rhythm(stage)

    return {
        "user_id": user_id,
        "life_stage": stage.value,
        "daily_rhythm": rhythm,
    }
