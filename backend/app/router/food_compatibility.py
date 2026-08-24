"""
顺时 — 食物相克 API (shunshi-food-compatibility)
常见食物相克组合查询及安全饮食建议
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import AliasChoices, BaseModel, Field
from typing import Optional, List

router = APIRouter(prefix="/api/v1/food-compatibility", tags=["food-compatibility"])

# 经审核的条件性饮食风险。不要把传统“食物相克”传言当成毒理结论。
INCOMPATIBLE_PAIRS = [
    {
        "id": "fc_005",
        "food_a": "高嘌呤食物", "food_b": "酒精",
        "severity": "conditional",
        "reason": "痛风或高尿酸人群需要结合总嘌呤摄入、饮酒量和医生建议进行管理；这不是针对所有人的绝对禁食规则。",
        "evidence_level": "clinical-guidance",
        "applies_to": ["痛风", "高尿酸血症"],
        "advice": "相关人群请咨询医生或注册营养师制定个体化方案。"
    }
]

FOOD_PROPERTIES = {
    "螃蟹": {"nature": "寒", "flavor": "咸", "meridians": ["肝", "胃"]},
    "柿子": {"nature": "寒", "flavor": "甘、涩", "meridians": ["肺", "胃", "大肠"]},
    "菠菜": {"nature": "凉", "flavor": "甘", "meridians": ["肝", "胃", "大肠"]},
    "豆腐": {"nature": "凉", "flavor": "甘", "meridians": ["脾", "胃", "大肠"]},
    "萝卜": {"nature": "凉", "flavor": "辛、甘", "meridians": ["肺", "胃"]},
    "绿豆": {"nature": "寒", "flavor": "甘", "meridians": ["心", "胃"]},
    "人参": {"nature": "微温", "flavor": "甘、微苦", "meridians": ["脾", "肺", "心"]},
}


class CompatibilityCheckRequest(BaseModel):
    food_a: str = Field(validation_alias=AliasChoices("food_a", "food1"), description="食物A")
    food_b: str = Field(validation_alias=AliasChoices("food_b", "food2"), description="食物B")


@router.get("/list", summary="食物相克列表")
async def list_incompatible_pairs(
    severity: Optional[str] = Query(None, description="严重程度: high/medium/low")
):
    items = INCOMPATIBLE_PAIRS
    if severity:
        items = [p for p in items if p["severity"] == severity]
    return {"success": True, "data": {
        "pairs": items,
        "incompatible_pairs": items,
        "total": len(items),
        "disclaimer": "本页仅列有条件的饮食风险，不支持传统‘食物相克’或食物中毒推断。",
    }}


@router.post("/check", summary="检查两种食物是否相克")
async def check_compatibility(request: CompatibilityCheckRequest):
    matches = [
        p for p in INCOMPATIBLE_PAIRS
        if (request.food_a in p["food_a"] or request.food_a in p["food_b"])
        and (request.food_b in p["food_a"] or request.food_b in p["food_b"])
    ]
    if matches:
        return {
            "success": True,
            "data": {
                "compatible": False,
                "is_compatible": False,
                "requires_caution": True,
                "pairs": matches,
                "advice": "是否需要限制取决于个人疾病、用药、过敏和摄入量，请按专业人员建议处理。"
            }
        }
    return {
        "success": True,
        "data": {
            "compatible": None,
            "is_compatible": None,
            "requires_caution": None,
            "message": f"未发现{request.food_a}与{request.food_b}的已审核条件性风险；这不等于证明组合绝对安全。",
            "disclaimer": "请结合过敏、疾病、用药、食物新鲜度和摄入量判断；出现不适请及时就医。"
        }
    }


@router.get("/food/{food_name}", summary="查询食物的相克组合")
async def get_food_incompatibilities(food_name: str):
    matches = [
        p for p in INCOMPATIBLE_PAIRS
        if food_name in p["food_a"] or food_name in p["food_b"]
    ]
    properties = FOOD_PROPERTIES.get(food_name, {})
    return {
        "success": True,
        "data": {
            "food": food_name,
            "properties": properties,
            "incompatible_with": matches
        }
    }


@router.get("/properties/{food_name}", summary="食物中医属性")
async def get_food_properties(food_name: str):
    if food_name not in FOOD_PROPERTIES:
        return {"success": True, "data": {"food": food_name, "properties": None, "message": "暂无该食物的中医属性数据"}}
    return {"success": True, "data": {"food": food_name, "properties": FOOD_PROPERTIES[food_name]}}
