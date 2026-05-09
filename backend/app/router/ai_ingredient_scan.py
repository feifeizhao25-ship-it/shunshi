"""
顺时 — AI食材扫描 API (shunshi-ai-ingredient-scan)
扫描食材识别、营养分析、中医属性查询
"""

from fastapi import APIRouter, HTTPException, Query, Path
from pydantic import BaseModel, Field
from typing import Optional, List, Dict

router = APIRouter(prefix="/api/v1/ingredient-scan", tags=["ai-ingredient-scan"])

INGREDIENT_DATABASE = {
    "goji_berry": {
        "name_cn": "枸杞", "name_en": "Goji Berry",
        "calories_per_100g": 349, "protein": 14.4, "carbs": 64.1, "fat": 0.4,
        "tcm": {"nature": "平", "flavor": "甘", "meridians": ["肝经", "肾经"], "functions": ["滋补肝肾", "益精明目"]},
        "season_best": ["autumn", "winter"],
        "constitution_suit": ["yin_deficiency", "qi_deficiency"],
        "constitution_avoid": ["damp_heat"],
        "cooking_tips": "泡茶、煮粥、炖汤均可，不宜煎炸"
    },
    "jujube": {
        "name_cn": "红枣", "name_en": "Jujube/Red Date",
        "calories_per_100g": 264, "protein": 3.7, "carbs": 67.8, "fat": 0.5,
        "tcm": {"nature": "温", "flavor": "甘", "meridians": ["脾经", "胃经"], "functions": ["补中益气", "养血安神"]},
        "season_best": ["all"],
        "constitution_suit": ["qi_deficiency", "blood_deficiency"],
        "constitution_avoid": ["damp_heat", "phlegm_dampness"],
        "cooking_tips": "去核后泡茶、煮粥；痰湿体质少食"
    },
    "lotus_root": {
        "name_cn": "莲藕", "name_en": "Lotus Root",
        "calories_per_100g": 74, "protein": 1.9, "carbs": 17.1, "fat": 0.1,
        "tcm": {"nature": "生用寒，熟用温", "flavor": "甘", "meridians": ["心经", "脾经", "胃经"],
                "functions": ["清热凉血（生用）", "健脾开胃（熟用）"]},
        "season_best": ["autumn"],
        "constitution_suit": ["yin_deficiency", "damp_heat"],
        "constitution_avoid": ["yang_deficiency"],
        "cooking_tips": "生食清热，煮熟温补；秋季食用最宜"
    },
    "yam": {
        "name_cn": "山药", "name_en": "Chinese Yam",
        "calories_per_100g": 63, "protein": 1.9, "carbs": 14.4, "fat": 0.2,
        "tcm": {"nature": "平", "flavor": "甘", "meridians": ["脾经", "肺经", "肾经"],
                "functions": ["补脾养胃", "生津益肺", "补肾涩精"]},
        "season_best": ["all"],
        "constitution_suit": ["qi_deficiency", "yin_deficiency", "phlegm_dampness"],
        "constitution_avoid": [],
        "cooking_tips": "清炒、蒸、煮汤均可；脾胃虚弱者最宜"
    },
    "hawthorn": {
        "name_cn": "山楂", "name_en": "Hawthorn",
        "calories_per_100g": 102, "protein": 0.7, "carbs": 25.1, "fat": 0.6,
        "tcm": {"nature": "微温", "flavor": "酸、甘", "meridians": ["脾经", "胃经", "肝经"],
                "functions": ["消食健胃", "行气散瘀", "降脂"]},
        "season_best": ["autumn"],
        "constitution_suit": ["qi_stagnation", "blood_stasis", "phlegm_dampness"],
        "constitution_avoid": ["spleen_stomach_weak"],
        "cooking_tips": "山楂茶、山楂糕；孕妇及胃酸多者慎用"
    }
}


class ScanResultRequest(BaseModel):
    image_url: Optional[str] = Field(None, description="食材图片URL")
    ingredient_name: Optional[str] = Field(None, description="直接输入食材名称")
    user_constitution: Optional[str] = Field(None, description="用户体质（用于个性化建议）")
    current_season: Optional[str] = Field(None, description="当前季节")


class MultiIngredientAnalysisRequest(BaseModel):
    ingredients: List[str] = Field(..., min_items=2, max_items=10, description="食材名称列表")
    user_constitution: Optional[str] = Field(None)


def _find_ingredient(name: str) -> Optional[dict]:
    """按名称查找食材（模糊匹配）"""
    for key, ing in INGREDIENT_DATABASE.items():
        if name in ing["name_cn"] or name.lower() in ing["name_en"].lower():
            return {"id": key, **ing}
    return None


@router.post("/scan", summary="扫描/识别食材")
async def scan_ingredient(request: ScanResultRequest):
    if not request.ingredient_name and not request.image_url:
        raise HTTPException(status_code=400, detail="请提供食材图片或名称")

    # 模拟图像识别（实际生产中调用AI视觉API）
    if request.image_url and not request.ingredient_name:
        recognized_name = "枸杞"  # 模拟识别结果
        confidence = 0.92
    else:
        recognized_name = request.ingredient_name
        confidence = 1.0

    ingredient = _find_ingredient(recognized_name)
    if not ingredient:
        return {
            "success": True,
            "data": {
                "recognized": recognized_name,
                "confidence": confidence,
                "found_in_database": False,
                "message": "未在数据库中找到该食材的详细信息"
            }
        }

    # 个性化建议
    personalized_advice = {}
    if request.user_constitution:
        if request.user_constitution in ingredient["constitution_suit"]:
            personalized_advice["suitability"] = "非常适合您的体质"
        elif request.user_constitution in ingredient["constitution_avoid"]:
            personalized_advice["suitability"] = "不太适合您的体质，建议少食"
        else:
            personalized_advice["suitability"] = "对您的体质基本适合"

    # 季节建议
    season_advice = ""
    if request.current_season:
        if "all" in ingredient["season_best"] or request.current_season in ingredient["season_best"]:
            season_advice = "当季食用，效果最佳"
        else:
            season_advice = "非最佳食用季节，可适量食用"

    return {
        "success": True,
        "data": {
            "recognized": recognized_name,
            "confidence": confidence,
            "found_in_database": True,
            "ingredient": ingredient,
            "personalized_advice": personalized_advice,
            "season_advice": season_advice
        }
    }


@router.get("/search", summary="搜索食材")
async def search_ingredient(q: str = Query(..., description="食材名称")):
    results = []
    for key, ing in INGREDIENT_DATABASE.items():
        if q in ing["name_cn"] or q.lower() in ing["name_en"].lower():
            results.append({"id": key, **ing})
    return {"success": True, "data": {"results": results, "total": len(results)}}


@router.get("/{ingredient_id}", summary="食材详情")
async def get_ingredient(ingredient_id: str):
    if ingredient_id not in INGREDIENT_DATABASE:
        raise HTTPException(status_code=404, detail="食材不存在")
    return {"success": True, "data": {"id": ingredient_id, **INGREDIENT_DATABASE[ingredient_id]}}


@router.post("/analyze-combination", summary="分析食材搭配")
async def analyze_combination(request: MultiIngredientAnalysisRequest):
    found = []
    not_found = []
    for name in request.ingredients:
        ing = _find_ingredient(name)
        if ing:
            found.append(ing)
        else:
            not_found.append(name)

    # 分析性质冲突
    natures = [f["tcm"]["nature"] for f in found]
    has_cold = any("寒" in n or "凉" in n for n in natures)
    has_hot = any("热" in n or "温" in n for n in natures)

    analysis = {
        "ingredients_found": found,
        "ingredients_not_found": not_found,
        "total_calories": sum(f.get("calories_per_100g", 0) * 0.1 for f in found),
        "nature_balance": {
            "has_cold_ingredients": has_cold,
            "has_hot_ingredients": has_hot,
            "is_balanced": not (has_cold and has_hot)
        },
        "advice": "食材性质平衡，搭配合理" if not (has_cold and has_hot) else "食材中有寒热混搭，体质偏寒者注意"
    }
    return {"success": True, "data": {"analysis": analysis}}


@router.get("/by-constitution/{constitution}", summary="按体质推荐食材")
async def get_by_constitution(constitution: str, season: Optional[str] = Query(None)):
    ingredients = [
        {"id": k, **v} for k, v in INGREDIENT_DATABASE.items()
        if constitution in v["constitution_suit"]
        and (not season or "all" in v["season_best"] or season in v["season_best"])
    ]
    return {"success": True, "data": {"constitution": constitution, "ingredients": ingredients}}
