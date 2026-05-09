"""
顺时 — 养生误区辟谣 API (shunshi-wellness-myth)
常见养生误区的科学辟谣和正确指导
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List

router = APIRouter(prefix="/api/v1/wellness-myth", tags=["wellness-myth"])

MYTHS = {
    "myth_001": {
        "id": "myth_001",
        "myth": "每天喝8杯水才健康",
        "category": "饮水",
        "truth": "每天饮水量因人而异，一般成人1500-1700ml即可，不必强迫自己喝够8杯。运动量、气候、体重都会影响所需水量。",
        "tcm_view": "中医讲究适度饮水，过量饮水反而会加重脾肾负担，导致水湿内停。",
        "correct_advice": "根据自身口渴感和尿液颜色判断补水需求，尿液呈淡黄色为适宜。",
        "tags": ["饮水", "日常养生"]
    },
    "myth_002": {
        "id": "myth_002",
        "myth": "冬天不需要防晒",
        "category": "皮肤护理",
        "truth": "紫外线全年存在，冬季阴天时紫外线仍可达到夏季的80%。积雪还会反射紫外线，增加暴露量。",
        "tcm_view": "中医认为阳光为自然界阳气，冬天适当晒太阳有益补阳，但也需防止过度日晒伤肤。",
        "correct_advice": "冬季户外活动仍应使用SPF30+的防晒产品，尤其是面部和手部。",
        "tags": ["护肤", "紫外线", "冬季养生"]
    },
    "myth_003": {
        "id": "myth_003",
        "myth": "饭后立即运动能帮助消化",
        "category": "运动",
        "truth": "饭后立即剧烈运动会使血液流向肌肉，减少胃部供血，影响消化，可能导致腹痛、恶心。",
        "tcm_view": "中医认为饭后宜缓行，'饭后百步走，活到九十九'指的是缓慢散步，而非剧烈运动。",
        "correct_advice": "饭后30分钟内只做轻度散步，剧烈运动应在饭后1.5-2小时进行。",
        "tags": ["运动", "消化", "饮食"]
    },
    "myth_004": {
        "id": "myth_004",
        "myth": "出汗越多减肥效果越好",
        "category": "减重",
        "truth": "大量出汗减少的是水分而非脂肪，一旦补水体重即恢复。真正的减脂需要热量赤字。",
        "tcm_view": "中医认为过度出汗会损伤津液和阳气，导致气津两虚，反而不利健康。",
        "correct_advice": "科学减重需结合合理饮食控制和规律有氧运动，避免过度追求出汗量。",
        "tags": ["减重", "出汗", "运动"]
    },
    "myth_005": {
        "id": "myth_005",
        "myth": "枸杞越多越好",
        "category": "中药养生",
        "truth": "枸杞虽好但不是人人适合。湿热体质、外感实热、脾虚腹泻者不宜食用。即使适合，也不宜过量。",
        "tcm_view": "中医讲究'是药三分毒'，即便是补益药材也需辨证使用，过量可能产生'上火'等不适。",
        "correct_advice": "枸杞每日用量6-15g为宜，阴虚肝肾不足者最为适合，其他体质需酌情减量或暂停。",
        "tags": ["枸杞", "中药", "体质"]
    },
    "myth_006": {
        "id": "myth_006",
        "myth": "晚上不吃东西就能减肥",
        "category": "饮食",
        "truth": "减肥的关键是全天总热量摄入，而非不吃晚餐。长期不吃晚餐可能导致营养不均衡和代谢紊乱。",
        "tcm_view": "中医认为晚餐宜清淡少量，但不应不吃。脾胃需定时进食维持功能正常运转。",
        "correct_advice": "晚餐应在睡前3小时完成，以清淡易消化食物为主，控制分量但不要完全不吃。",
        "tags": ["减重", "饮食", "晚餐"]
    },
    "myth_007": {
        "id": "myth_007",
        "myth": "中药没有副作用",
        "category": "中药养生",
        "truth": "中药同样有副作用和禁忌证。有些中草药含有肝毒性成分，长期大量服用可能损伤肝肾。",
        "tcm_view": "中医历来强调辨证论治，'有是证，用是药'，不辨证滥用中药同样有害。",
        "correct_advice": "中药应在专业中医师指导下使用，自行购买服用要了解禁忌，不可随意长期大量服用。",
        "tags": ["中药", "安全", "副作用"]
    },
    "myth_008": {
        "id": "myth_008",
        "myth": "空腹喝蜂蜜水能排毒",
        "category": "排毒",
        "truth": "人体有肝脏和肾脏等专门的解毒排毒系统，不需要特定食物'排毒'。蜂蜜水空腹饮用可能刺激胃酸分泌。",
        "tcm_view": "中医并无'排毒'的概念，而是通过调理脏腑功能来达到去除'浊气'的效果。",
        "correct_advice": "保持规律排便、充足睡眠和均衡饮食是最好的'排毒'方式。",
        "tags": ["排毒", "蜂蜜", "饮食"]
    }
}


@router.get("/list", summary="养生误区列表")
async def list_myths(
    category: Optional[str] = Query(None, description="分类筛选"),
    tag: Optional[str] = Query(None, description="标签筛选")
):
    items = list(MYTHS.values())
    if category:
        items = [m for m in items if m["category"] == category]
    if tag:
        items = [m for m in items if tag in m["tags"]]
    return {"success": True, "data": {"myths": items, "total": len(items)}}


@router.get("/{myth_id}", summary="误区详情")
async def get_myth(myth_id: str):
    if myth_id not in MYTHS:
        raise HTTPException(status_code=404, detail="误区条目不存在")
    return {"success": True, "data": MYTHS[myth_id]}


@router.get("/categories/list", summary="误区分类")
async def list_categories():
    categories = list(set(m["category"] for m in MYTHS.values()))
    return {"success": True, "data": {"categories": categories}}


@router.get("/search/query", summary="搜索养生误区")
async def search_myths(q: str = Query(..., description="搜索关键词")):
    results = [
        m for m in MYTHS.values()
        if q in m["myth"] or q in m["truth"] or any(q in t for t in m["tags"])
    ]
    return {"success": True, "data": {"results": results, "total": len(results)}}


@router.get("/daily/tip", summary="每日辟谣提示")
async def daily_myth_tip():
    import random
    myth = random.choice(list(MYTHS.values()))
    return {
        "success": True,
        "data": {
            "myth": myth["myth"],
            "truth": myth["truth"],
            "correct_advice": myth["correct_advice"],
            "id": myth["id"]
        }
    }
