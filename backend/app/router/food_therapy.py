"""
顺时 — 食疗方案 API (shunshi-food-therapy)
基于中医理论的食疗配方、功效分类和个性化食疗推荐
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List

router = APIRouter(prefix="/api/v1/food-therapy", tags=["food-therapy"])

FOOD_THERAPY_RECIPES = {
    "red_date_goji": {
        "id": "red_date_goji", "name": "红枣枸杞茶",
        "category": "补气养血",
        "constitution": ["qi_deficiency", "blood_deficiency"],
        "season": ["all"],
        "ingredients": [
            {"name": "红枣", "amount": "5-8颗", "function": "补气养血"},
            {"name": "枸杞", "amount": "15g", "function": "滋补肝肾"},
        ],
        "preparation": "红枣去核，与枸杞同放入杯中，用开水冲泡10分钟即可。",
        "function": "补气养血，滋补肝肾，改善面色萎黄、疲乏乏力",
        "contraindication": "痰湿体质、湿热体质慎用；感冒发烧期间不宜",
        "dosage": "每日1-2次，连续饮用1-2周"
    },
    "yam_congee": {
        "id": "yam_congee", "name": "山药薏米粥",
        "category": "健脾祛湿",
        "constitution": ["phlegm_dampness", "qi_deficiency"],
        "season": ["spring", "summer", "long_summer"],
        "ingredients": [
            {"name": "山药", "amount": "100g", "function": "健脾益胃，补肺固肾"},
            {"name": "薏米", "amount": "50g", "function": "健脾利湿，清热排毒"},
            {"name": "大米", "amount": "100g", "function": "养胃和中"},
        ],
        "preparation": "薏米提前浸泡2小时，山药去皮切块，与大米同煮成粥，小火慢熬40分钟。",
        "function": "健脾祛湿，益气养胃，适合脾虚湿重、消化不良",
        "contraindication": "孕妇不宜多食薏米；阴虚燥热者慎用",
        "dosage": "早餐食用，每周3-5次"
    },
    "lily_lotus_soup": {
        "id": "lily_lotus_soup", "name": "百合莲子银耳汤",
        "category": "养心安神",
        "constitution": ["yin_deficiency", "qi_stagnation"],
        "season": ["summer", "autumn"],
        "ingredients": [
            {"name": "百合", "amount": "30g", "function": "润肺止咳，清心安神"},
            {"name": "莲子", "amount": "30g", "function": "补脾止泻，益肾固精，养心安神"},
            {"name": "银耳", "amount": "1朵", "function": "滋阴润肺，益胃生津"},
            {"name": "冰糖", "amount": "适量", "function": "润肺止咳"},
        ],
        "preparation": "银耳提前泡发，撕成小朵。莲子去芯。所有食材加水，大火煮开，小火炖1小时，加冰糖调味。",
        "function": "养阴润肺，养心安神，适合失眠多梦、心烦口燥",
        "contraindication": "脾胃虚寒、腹泻者慎用",
        "dosage": "晚上睡前1-2小时食用"
    },
    "ginger_brown_sugar": {
        "id": "ginger_brown_sugar", "name": "生姜红糖水",
        "category": "温阳散寒",
        "constitution": ["yang_deficiency", "blood_stasis"],
        "season": ["winter", "autumn"],
        "ingredients": [
            {"name": "生姜", "amount": "3-5片", "function": "温中散寒，发汗解表"},
            {"name": "红糖", "amount": "15g", "function": "温中补虚，活血化瘀"},
        ],
        "preparation": "生姜切片，加水煮沸后，转小火再煮10分钟，加入红糖溶化即可。",
        "function": "温中散寒，活血止痛，适合宫寒痛经、受寒感冒初期",
        "contraindication": "阴虚火旺、糖尿病患者慎用；热性体质不宜",
        "dosage": "趁热饮用，每日1-2次"
    },
    "black_sesame_walnut": {
        "id": "black_sesame_walnut", "name": "黑芝麻核桃糊",
        "category": "补肾益脑",
        "constitution": ["kidney_deficiency", "yin_deficiency"],
        "season": ["winter", "autumn"],
        "ingredients": [
            {"name": "黑芝麻", "amount": "30g", "function": "补肝肾，益精血，润肠燥"},
            {"name": "核桃仁", "amount": "30g", "function": "补肾固精，温肺定喘，润肠通便"},
        ],
        "preparation": "黑芝麻和核桃仁分别炒熟，磨成粉，用热水冲调成糊状，可加少许蜂蜜调味。",
        "function": "补肾益脑，乌发润肤，改善记忆力减退、腰膝酸软",
        "contraindication": "痰多咳嗽者慎用；腹泻者不宜",
        "dosage": "早餐食用，每周3-4次"
    },
    "chrysanthemum_wolfberry": {
        "id": "chrysanthemum_wolfberry", "name": "菊花枸杞茶",
        "category": "清肝明目",
        "constitution": ["yin_deficiency", "damp_heat"],
        "season": ["spring", "summer"],
        "ingredients": [
            {"name": "菊花", "amount": "5g", "function": "清热降火，疏散风热，平肝明目"},
            {"name": "枸杞", "amount": "10g", "function": "滋补肝肾，明目"},
        ],
        "preparation": "菊花和枸杞一同放入杯中，用85°C热水冲泡，焖5分钟即可饮用。",
        "function": "清热明目，适合用眼过度、眼睛干涩疲劳",
        "contraindication": "脾胃虚寒、阳虚体质者不宜多饮",
        "dosage": "每日1-2杯，不宜过量"
    },
    "rose_hawthorn": {
        "id": "rose_hawthorn", "name": "玫瑰山楂茶",
        "category": "疏肝理气",
        "constitution": ["qi_stagnation", "blood_stasis"],
        "season": ["spring", "all"],
        "ingredients": [
            {"name": "玫瑰花", "amount": "5g", "function": "疏肝解郁，活血化瘀"},
            {"name": "山楂", "amount": "10g", "function": "消食健胃，行气散瘀"},
        ],
        "preparation": "玫瑰花和山楂一同放入杯中，开水冲泡10分钟即可。",
        "function": "疏肝理气，消食化滞，适合情绪郁结、消化不良",
        "contraindication": "孕妇禁用；胃酸过多者慎用",
        "dosage": "饭后饮用，每日1次"
    }
}


class FoodTherapyQueryRequest(BaseModel):
    constitution: Optional[str] = Field(None, description="体质类型")
    symptom: Optional[str] = Field(None, description="症状描述")
    season: Optional[str] = Field(None, description="季节")


@router.get("/list", summary="食疗方案列表")
async def list_food_therapy(
    category: Optional[str] = Query(None, description="功效分类"),
    constitution: Optional[str] = Query(None, description="适合体质"),
    season: Optional[str] = Query(None, description="适合季节")
):
    items = list(FOOD_THERAPY_RECIPES.values())
    if category:
        items = [r for r in items if category in r["category"]]
    if constitution:
        items = [r for r in items if constitution in r["constitution"]]
    if season:
        items = [r for r in items if "all" in r["season"] or season in r["season"]]
    return {"success": True, "data": {"recipes": items, "total": len(items)}}


@router.get("/{recipe_id}", summary="食疗方案详情")
async def get_food_therapy(recipe_id: str):
    if recipe_id not in FOOD_THERAPY_RECIPES:
        raise HTTPException(status_code=404, detail="食疗方案不存在")
    return {"success": True, "data": FOOD_THERAPY_RECIPES[recipe_id]}


@router.post("/recommend", summary="个性化食疗推荐")
async def recommend_food_therapy(request: FoodTherapyQueryRequest):
    items = list(FOOD_THERAPY_RECIPES.values())
    if request.constitution:
        items = [r for r in items if request.constitution in r["constitution"]]
    if request.season:
        items = [r for r in items if "all" in r["season"] or request.season in r["season"]]
    return {
        "success": True,
        "data": {
            "recommendations": items[:3],
            "tips": "食疗需根据个人体质调整，建议咨询专业中医师。"
        }
    }


@router.get("/categories/list", summary="食疗功效分类")
async def list_categories():
    categories = list(set(r["category"] for r in FOOD_THERAPY_RECIPES.values()))
    return {"success": True, "data": {"categories": categories}}
