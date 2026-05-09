"""
顺时 — 本草知识 API (shunshi-herbal-knowledge)
中药材基础知识、功效、用法、配伍禁忌
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List

router = APIRouter(prefix="/api/v1/herbal", tags=["herbal-knowledge"])

HERBS = {
    "goji": {
        "id": "goji", "name_cn": "枸杞", "name_en": "Wolfberry",
        "latin": "Lycium barbarum", "category": "补益药",
        "nature": "平", "flavor": "甘", "meridians": ["肝经", "肾经"],
        "functions": ["滋补肝肾", "益精明目", "润肺"],
        "indications": ["虚劳精亏", "腰膝酸痛", "眩晕耳鸣", "视力减退"],
        "dosage": "6-12g，煎服或泡茶",
        "contraindications": "外感实热、脾虚腹泻者不宜",
        "storage": "置阴凉干燥处，防潮防蛀",
        "common_pairs": ["菊花", "黑芝麻", "熟地黄"],
        "popular_uses": ["枸杞茶", "枸杞粥", "枸杞泡酒"]
    },
    "astragalus": {
        "id": "astragalus", "name_cn": "黄芪", "name_en": "Astragalus",
        "latin": "Astragalus membranaceus", "category": "补益药",
        "nature": "微温", "flavor": "甘", "meridians": ["脾经", "肺经"],
        "functions": ["补气固表", "利水退肿", "托毒排脓", "生肌"],
        "indications": ["气虚乏力", "食少便溏", "中气下陷", "久泻脱肛"],
        "dosage": "9-30g，煎服",
        "contraindications": "表实邪盛、气滞湿阻、食积内停者不宜",
        "storage": "置通风干燥处，防潮防蛀",
        "common_pairs": ["党参", "白术", "当归"],
        "popular_uses": ["黄芪鸡汤", "黄芪茶", "黄芪粥"]
    },
    "ginseng": {
        "id": "ginseng", "name_cn": "人参", "name_en": "Ginseng",
        "latin": "Panax ginseng", "category": "补益药",
        "nature": "微温", "flavor": "甘、微苦", "meridians": ["脾经", "肺经", "心经"],
        "functions": ["大补元气", "复脉固脱", "补脾益肺", "生津养血", "安神益智"],
        "indications": ["体虚欲脱", "肢冷脉微", "脾虚食少", "肺虚喘咳"],
        "dosage": "3-9g，另煎兑服；研末吞服，每次2g",
        "contraindications": "实证、热证慎用；不宜与藜芦、五灵脂、皂荚同用",
        "storage": "密封，置阴凉干燥处",
        "common_pairs": ["麦冬", "五味子", "白术"],
        "popular_uses": ["人参汤", "人参茶", "人参炖鸡"]
    },
    "angelica": {
        "id": "angelica", "name_cn": "当归", "name_en": "Angelica",
        "latin": "Angelica sinensis", "category": "补益药",
        "nature": "温", "flavor": "甘、辛", "meridians": ["肝经", "心经", "脾经"],
        "functions": ["补血活血", "调经止痛", "润肠通便"],
        "indications": ["血虚萎黄", "月经不调", "闭经痛经", "肠燥便秘"],
        "dosage": "6-12g，煎服",
        "contraindications": "湿盛中满、大便泄泻者慎用；孕妇慎用",
        "storage": "置阴凉干燥处，防潮防霉",
        "common_pairs": ["黄芪", "白芍", "川芎"],
        "popular_uses": ["当归炖鸡", "当归补血汤", "四物汤"]
    },
    "jujube": {
        "id": "jujube", "name_cn": "大枣", "name_en": "Jujube",
        "latin": "Ziziphus jujuba", "category": "补益药",
        "nature": "温", "flavor": "甘", "meridians": ["脾经", "胃经"],
        "functions": ["补中益气", "养血安神", "缓和药性"],
        "indications": ["脾虚食少", "乏力便溏", "妇人脏躁"],
        "dosage": "6-15g（3-10枚），煎服",
        "contraindications": "湿盛脘腹胀满、食积、虫积者慎用",
        "storage": "置阴凉干燥处",
        "common_pairs": ["生姜", "甘草", "枸杞"],
        "popular_uses": ["红枣粥", "红枣茶", "红枣枸杞汤"]
    },
    "licorice": {
        "id": "licorice", "name_cn": "甘草", "name_en": "Licorice",
        "latin": "Glycyrrhiza uralensis", "category": "补益药",
        "nature": "平", "flavor": "甘", "meridians": ["心经", "肺经", "脾经", "胃经"],
        "functions": ["补脾益气", "清热解毒", "祛痰止咳", "缓急止痛", "调和诸药"],
        "indications": ["脾胃虚弱", "倦怠乏力", "心悸气短", "咽喉肿痛"],
        "dosage": "2-10g，煎服",
        "contraindications": "湿盛胀满、浮肿者不宜用；不宜与海藻、京大戟、芫花、甘遂同用",
        "storage": "置通风干燥处",
        "common_pairs": ["茯苓", "白术", "党参"],
        "popular_uses": ["甘草茶", "甘草糖浆", "各种汤剂调和"]
    },
    "hawthorn": {
        "id": "hawthorn", "name_cn": "山楂", "name_en": "Hawthorn",
        "latin": "Crataegus pinnatifida", "category": "消食药",
        "nature": "微温", "flavor": "酸、甘", "meridians": ["脾经", "胃经", "肝经"],
        "functions": ["消食健胃", "行气散瘀", "降脂"],
        "indications": ["肉食积滞", "胃脘胀满", "泻痢腹痛", "血瘀经闭"],
        "dosage": "9-12g，煎服",
        "contraindications": "脾胃虚弱者慎用；孕妇慎用",
        "storage": "置通风干燥处",
        "common_pairs": ["麦芽", "神曲", "莱菔子"],
        "popular_uses": ["山楂茶", "山楂糕", "冰糖葫芦"]
    }
}


@router.get("/list", summary="中药材列表")
async def list_herbs(
    category: Optional[str] = Query(None, description="药材分类"),
    nature: Optional[str] = Query(None, description="药性筛选")
):
    items = list(HERBS.values())
    if category:
        items = [h for h in items if h["category"] == category]
    if nature:
        items = [h for h in items if nature in h["nature"]]
    return {"success": True, "data": {"herbs": items, "total": len(items)}}


@router.get("/search", summary="搜索中药材")
async def search_herbs(q: str = Query(..., description="搜索关键词")):
    results = [
        h for h in HERBS.values()
        if q in h["name_cn"] or q in h.get("name_en", "").lower()
        or any(q in f for f in h["functions"])
    ]
    return {"success": True, "data": {"results": results, "total": len(results)}}


@router.get("/{herb_id}", summary="中药材详情")
async def get_herb(herb_id: str):
    if herb_id not in HERBS:
        raise HTTPException(status_code=404, detail="药材不存在")
    return {"success": True, "data": HERBS[herb_id]}


@router.get("/{herb_id}/pairs", summary="常用配伍")
async def get_herb_pairs(herb_id: str):
    if herb_id not in HERBS:
        raise HTTPException(status_code=404, detail="药材不存在")
    h = HERBS[herb_id]
    paired = [HERBS[k] for k in HERBS if HERBS[k]["name_cn"] in h["common_pairs"]]
    return {
        "success": True,
        "data": {
            "herb": h["name_cn"],
            "common_pairs": h["common_pairs"],
            "pair_details": paired
        }
    }


@router.get("/by-function/{function}", summary="按功效查询药材")
async def get_herbs_by_function(function: str):
    items = [h for h in HERBS.values() if any(function in f for f in h["functions"])]
    return {"success": True, "data": {"function": function, "herbs": items}}
