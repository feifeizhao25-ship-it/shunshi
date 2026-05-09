"""
顺时 — 儿童养护 API (shunshi-child-wellness)
0-12岁儿童中医养护建议、季节调护、常见儿科问题调理
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List

router = APIRouter(prefix="/api/v1/child-wellness", tags=["child-wellness"])

AGE_GROUPS = {
    "infant": {"label": "婴儿期", "age_range": "0-1岁", "key": "infant"},
    "toddler": {"label": "幼儿期", "age_range": "1-3岁", "key": "toddler"},
    "preschool": {"label": "学前期", "age_range": "3-6岁", "key": "preschool"},
    "school": {"label": "学龄期", "age_range": "6-12岁", "key": "school"},
}

SEASONAL_CARE = {
    "spring": {
        "season": "春季", "key_risk": "过敏、感冒",
        "advice": "春季气温多变，注意随温加减衣物，'春捂秋冻'对孩子仍适用。",
        "diet": ["多吃绿色蔬菜", "少吃酸味食物", "多喝水"],
        "foods": ["春笋", "菠菜", "豌豆苗", "韭菜"],
        "avoid": ["过早脱衣", "生冷食物", "海鲜（易过敏者）"],
        "exercise": ["户外踏青", "放风筝", "跳绳"],
        "tcm_tip": "春天肝气旺，儿童情绪易波动，应多户外运动疏肝"
    },
    "summer": {
        "season": "夏季", "key_risk": "中暑、腹泻、手足口病",
        "advice": "夏季暑热，注意防暑降温，保持室内通风，避免贪凉吹空调。",
        "diet": ["清淡饮食", "多喝水", "绿豆汤", "西瓜"],
        "foods": ["绿豆", "西瓜", "苦瓜", "莲子", "薏米"],
        "avoid": ["冷饮过量", "长时间空调", "隔夜食物"],
        "exercise": ["早晨或傍晚运动", "游泳（注意卫生）"],
        "tcm_tip": "夏季心火旺，儿童容易烦躁，宜用莲子、百合等安神"
    },
    "autumn": {
        "season": "秋季", "key_risk": "咳嗽、秋燥、腹泻",
        "advice": "秋季干燥，需要润肺养肺，注意保湿和水分补充。",
        "diet": ["梨", "银耳", "百合", "藕", "蜂蜜"],
        "foods": ["白色食物为主", "梨汤", "银耳羹"],
        "avoid": ["辛辣干燥食物", "过凉食物"],
        "exercise": ["爬山", "跑步", "适度户外活动"],
        "tcm_tip": "秋季肺气虚，儿童易咳嗽，可用梨水、百合粥润肺"
    },
    "winter": {
        "season": "冬季", "key_risk": "感冒、流感、冻疮",
        "advice": "冬季注意保暖，尤其是背部和脚部，但不要穿得过厚导致出汗。",
        "diet": ["温补食物", "羊肉汤", "黑色食物"],
        "foods": ["黑芝麻", "核桃", "红枣", "姜"],
        "avoid": ["生冷食物", "频繁洗澡（尤其婴幼儿）"],
        "exercise": ["室内运动为主", "阳光好时户外晒太阳"],
        "tcm_tip": "冬季肾气需储存，儿童不宜过度运动消耗阳气"
    }
}

COMMON_ISSUES = {
    "cold": {
        "name": "感冒", "tcm_name": "外感风寒/风热",
        "symptoms": ["流鼻涕", "打喷嚏", "咽痛", "发热"],
        "tcm_treatment": {
            "wind_cold": {
                "type": "风寒感冒",
                "signs": ["怕冷", "清鼻涕", "无汗"],
                "remedies": ["葱姜汤", "热水泡脚", "推拿大椎穴"],
                "diet": ["姜汤", "热稀粥"]
            },
            "wind_heat": {
                "type": "风热感冒",
                "signs": ["发热重", "黄鼻涕", "咽痛"],
                "remedies": ["菊花薄荷茶", "金银花茶"],
                "diet": ["梨水", "西瓜汁（适量）"]
            }
        },
        "when_to_see_doctor": ["高热超过38.5°C", "精神萎靡", "呼吸困难", "发热超过3天"]
    },
    "indigestion": {
        "name": "积食", "tcm_name": "食积",
        "symptoms": ["腹胀", "食欲不振", "口臭", "大便酸臭"],
        "remedies": ["山楂麦芽茶", "顺时针按摩腹部", "捏脊"],
        "diet": ["清淡饮食", "山楂", "白萝卜", "陈皮茶"],
        "avoid": ["强迫进食", "油腻食物"],
        "when_to_see_doctor": ["腹痛剧烈", "高热", "腹泻严重脱水"]
    },
    "night_sweats": {
        "name": "小儿盗汗", "tcm_name": "阴虚内热或气虚",
        "symptoms": ["睡觉时大量出汗", "醒后出汗停止"],
        "tcm_view": "多为气虚或阴虚，需辨证施治",
        "remedies": ["玉屏风散（益气固表）", "六味地黄丸（滋阴）"],
        "diet": ["浮小麦大枣茶", "百合莲子粥"],
        "when_to_see_doctor": ["伴有发热", "盗汗严重影响睡眠质量"]
    }
}


@router.get("/age-groups", summary="儿童年龄分组")
async def list_age_groups():
    return {"success": True, "data": {"age_groups": list(AGE_GROUPS.values())}}


@router.get("/seasonal-care/{season}", summary="季节养护建议")
async def get_seasonal_care(season: str):
    if season not in SEASONAL_CARE:
        raise HTTPException(status_code=404, detail="季节参数无效，请使用: spring/summer/autumn/winter")
    return {"success": True, "data": SEASONAL_CARE[season]}


@router.get("/common-issues", summary="常见儿科问题列表")
async def list_common_issues():
    issues = [{"name": v["name"], "tcm_name": v["tcm_name"], "id": k} for k, v in COMMON_ISSUES.items()]
    return {"success": True, "data": {"issues": issues}}


@router.get("/common-issues/{issue_id}", summary="儿科问题详细调理方案")
async def get_issue_care(issue_id: str):
    if issue_id not in COMMON_ISSUES:
        raise HTTPException(status_code=404, detail="问题类型不存在")
    return {"success": True, "data": COMMON_ISSUES[issue_id]}


@router.get("/diet-guide", summary="儿童饮食指南")
async def get_diet_guide(age_group: str = Query("toddler", description="年龄段")):
    guides = {
        "infant": {
            "principle": "母乳或配方奶为主，6个月后逐步添加辅食",
            "tcm_view": "婴儿脾胃娇嫩，辅食宜由少到多、由稀到稠，以米汤、菜泥为宜",
            "recommended": ["母乳", "配方奶", "米汤", "蔬菜泥", "果泥"],
            "avoid": ["蜂蜜（1岁前禁用）", "坚果整粒", "盐和糖（尽量少）"]
        },
        "toddler": {
            "principle": "三餐规律，食物多样，培养良好饮食习惯",
            "tcm_view": "幼儿脾胃功能逐渐完善，但仍需清淡饮食，避免过多补品",
            "recommended": ["五谷为主", "蔬菜水果", "适量肉蛋鱼奶"],
            "avoid": ["零食过多", "偏食挑食", "过辣过咸"]
        },
        "preschool": {
            "principle": "饮食均衡，控制零食，培养自主饮食能力",
            "tcm_view": "学前儿童阳气旺盛，不宜过多温补，以平补为宜",
            "recommended": ["彩虹饮食", "粗细搭配", "适量坚果"],
            "avoid": ["含糖饮料", "垃圾食品", "不吃早餐"]
        },
        "school": {
            "principle": "保证能量供应，重视早餐，适量零食",
            "tcm_view": "学龄儿童学习压力增加，可适当补益脑力，如核桃、黑芝麻等",
            "recommended": ["核桃", "鱼类（DHA）", "深色蔬菜", "豆类"],
            "avoid": ["熬夜后过量进食", "碳酸饮料", "方便食品"]
        }
    }
    guide = guides.get(age_group, guides["toddler"])
    return {"success": True, "data": {"age_group": age_group, "guide": guide}}


@router.get("/massage-guide", summary="儿童推拿按摩基础指南")
async def get_massage_guide():
    guides = [
        {"name": "补脾经", "location": "拇指末节螺纹面", "method": "旋推或直推，200-500次", "benefit": "健脾和胃"},
        {"name": "推三关", "location": "前臂桡侧，腕横纹到肘横纹", "method": "从腕推向肘，100-300次", "benefit": "补气温阳"},
        {"name": "清天河水", "location": "前臂正中，腕横纹到肘横纹", "method": "从腕推向肘，100-300次", "benefit": "清热退烧"},
        {"name": "捏脊", "location": "脊柱两旁", "method": "从长强穴到大椎穴，捏3遍", "benefit": "调理脏腑，强壮体质"},
    ]
    return {
        "success": True,
        "data": {
            "guides": guides,
            "precautions": ["手法宜轻柔", "不宜在饭前1小时或饭后1小时进行", "皮肤破损处禁用"]
        }
    }
