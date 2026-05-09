"""
顺时 — 食物相克 API (shunshi-food-compatibility)
常见食物相克组合查询及安全饮食建议
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List

router = APIRouter(prefix="/api/v1/food-compatibility", tags=["food-compatibility"])

# 食物相克数据库
INCOMPATIBLE_PAIRS = [
    {
        "id": "fc_001",
        "food_a": "螃蟹", "food_b": "柿子",
        "severity": "high",
        "reason": "螃蟹和柿子均属寒性食物，同食可能导致腹泻、腹痛。柿子中的鞣酸会与蛋白质结合形成沉淀，加重消化负担。",
        "tcm_view": "两者皆寒，寒上加寒，最易伤脾胃阳气。",
        "symptoms": ["腹痛", "腹泻", "恶心"],
        "interval": "至少间隔4小时"
    },
    {
        "id": "fc_002",
        "food_a": "牛奶", "food_b": "橙汁",
        "severity": "medium",
        "reason": "牛奶中的蛋白质遇到橙汁中的果酸会发生凝固，影响消化吸收，可能导致胃胀、腹泻。",
        "tcm_view": "牛奶滋阴补液，橙汁酸而生津，酸甘相合虽不算大忌，但胃弱者需注意。",
        "symptoms": ["胃胀", "消化不良"],
        "interval": "至少间隔30分钟"
    },
    {
        "id": "fc_003",
        "food_a": "菠菜", "food_b": "豆腐",
        "severity": "medium",
        "reason": "菠菜中的草酸与豆腐中的钙结合，形成草酸钙，影响钙的吸收，长期同食可能导致结石。",
        "tcm_view": "两者营养丰富，但同食会降低营养价值，不宜经常同食。",
        "symptoms": ["钙吸收减少", "结石风险（长期）"],
        "interval": "可以同食，但不宜频繁；建议菠菜焯水后食用"
    },
    {
        "id": "fc_004",
        "food_a": "萝卜", "food_b": "橘子",
        "severity": "medium",
        "reason": "萝卜中的硫氰酸盐与橘子中的黄酮类物质作用，可能抑制甲状腺功能，诱发甲状腺肿。",
        "tcm_view": "萝卜理气化痰，橘子行气宽中，两者性质相近但互有制约。",
        "symptoms": ["甲状腺功能影响（长期大量同食）"],
        "interval": "偶尔同食无妨，避免长期大量同食"
    },
    {
        "id": "fc_005",
        "food_a": "海鲜", "food_b": "啤酒",
        "severity": "high",
        "reason": "海鲜富含嘌呤，啤酒中的酒精会抑制尿酸排泄。两者同食会大量增加血尿酸水平，诱发痛风发作。",
        "tcm_view": "海鲜性寒，啤酒湿热，寒湿交杂，对脾胃和关节均有损害。",
        "symptoms": ["痛风发作", "关节红肿疼痛", "血尿酸升高"],
        "interval": "痛风患者绝对禁止同食"
    },
    {
        "id": "fc_006",
        "food_a": "鸡蛋", "food_b": "豆浆",
        "severity": "low",
        "reason": "豆浆中的胰蛋白酶抑制物会抑制蛋白质消化，影响鸡蛋蛋白质的吸收率。",
        "tcm_view": "此说法有一定争议，充分煮熟的豆浆影响较小。",
        "symptoms": ["蛋白质吸收率降低"],
        "interval": "豆浆煮沸后影响减小，偶尔同食无大碍"
    },
    {
        "id": "fc_007",
        "food_a": "人参", "food_b": "萝卜",
        "severity": "high",
        "reason": "萝卜有消食下气的作用，会消解人参的补气功效，降低人参的疗效。中医有'服人参勿食萝卜'的说法。",
        "tcm_view": "人参大补元气，萝卜破气，两者功效相克，大大降低人参的补益作用。",
        "symptoms": ["人参功效减弱"],
        "interval": "服用人参期间忌食萝卜"
    },
    {
        "id": "fc_008",
        "food_a": "绿豆", "food_b": "狗肉",
        "severity": "medium",
        "reason": "绿豆性寒，狗肉性温，两者性质相反，同食可能引起消化不适。",
        "tcm_view": "绿豆清热解毒，狗肉温补肾阳，两者功效相悖，易引起腹胀腹泻。",
        "symptoms": ["腹胀", "消化不适"],
        "interval": "避免同食"
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
    food_a: str = Field(..., description="食物A")
    food_b: str = Field(..., description="食物B")


@router.get("/list", summary="食物相克列表")
async def list_incompatible_pairs(
    severity: Optional[str] = Query(None, description="严重程度: high/medium/low")
):
    items = INCOMPATIBLE_PAIRS
    if severity:
        items = [p for p in items if p["severity"] == severity]
    return {"success": True, "data": {"pairs": items, "total": len(items)}}


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
                "pairs": matches,
                "advice": f"建议避免{request.food_a}和{request.food_b}同食"
            }
        }
    return {
        "success": True,
        "data": {
            "compatible": True,
            "message": f"未发现{request.food_a}与{request.food_b}的相克记录，可以正常食用",
            "disclaimer": "本数据库仅供参考，如有疑问请咨询营养师或中医师"
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
