# 养生名言 API 路由
from fastapi import APIRouter
from datetime import datetime
import hashlib
import random

from app.database.db import get_db, row_to_dict

router = APIRouter(prefix="/api/v1/wisdom", tags=["养生名言"])

# ═══════════════════════════════════════════════════════════
# 养生名言数据库（精选 180+ 条，覆盖四季×体质×场景）
# ═══════════════════════════════════════════════════════════

# 节气养生名言
SOLAR_TERM_QUOTES = [
    {"text": "春三月，此谓发陈。天地俱生，万物以荣。夜卧早起，广步于庭，被发缓形，以使志生。", "source": "《黄帝内经·素问·四气调神大论》", "tag": "spring"},
    {"text": "夏三月，此谓蕃秀。天地气交，万物华实。夜卧早起，无厌于日。", "source": "《黄帝内经·素问》", "tag": "summer"},
    {"text": "秋三月，此谓容平。天气以急，地气以明。早卧早起，与鸡俱兴。", "source": "《黄帝内经·素问》", "tag": "autumn"},
    {"text": "冬三月，此谓闭藏。水冰地坼，无扰乎阳。早卧晚起，必待日光。", "source": "《黄帝内经·素问》", "tag": "winter"},
    {"text": "惊蛰时节，万物出乎震，震为雷，蛰虫惊而出走。宜养肝护肝，舒达情志。", "source": "《月令七十二候集解》", "tag": "spring"},
    {"text": "春分者，阴阳相半也，故昼夜均而寒暑平。调其阴阳，以平为期。", "source": "《春秋繁露》", "tag": "spring"},
    {"text": "清明时节，万物生长，皆清洁而明净。宜疏肝理气，调畅情志。", "source": "《岁时百问》", "tag": "spring"},
    {"text": "谷雨时节，雨生百谷，春将尽，宜健脾祛湿。", "source": "《通纬·孝经援神契》", "tag": "spring"},
    {"text": "小满者，物至于此小得盈满。宜清淡饮食，静心养神。", "source": "《月令七十二候集解》", "tag": "summer"},
    {"text": "芒种时节，麦黄梅熟，忙种忙收。宜养心宁神，解暑清心。", "source": "民间谚语", "tag": "summer"},
    {"text": "夏至一阴生，阴气始起。宜养阴清热，午休养心。", "source": "《黄帝内经》", "tag": "summer"},
    {"text": "大暑时节，湿热最甚。宜清热解暑，静心安神。", "source": "《月令七十二候集解》", "tag": "summer"},
    {"text": "立秋时节，凉风至，白露降。宜养阴润燥，收敛神气。", "source": "《礼记·月令》", "tag": "autumn"},
    {"text": "处暑，暑气至此而止。宜早睡早起，滋阴润肺。", "source": "《月令七十二候集解》", "tag": "autumn"},
    {"text": "白露秋分夜，一夜凉一夜。宜滋阴润燥，润肺止咳。", "source": "民间谚语", "tag": "autumn"},
    {"text": "霜降，气肃而凝，露结为霜。宜温补脾胃，养血安神。", "source": "《月令七十二候集解》", "tag": "autumn"},
    {"text": "立冬，万物收藏。宜温补肾阳，敛阴护阳。", "source": "《月令七十二候集解》", "tag": "winter"},
    {"text": "小雪时节，寒气渐盛。宜温中散寒，养藏精气。", "source": "《群芳谱》", "tag": "winter"},
    {"text": "大雪时节，至此而雪盛。宜进补养藏，温养肾气。", "source": "《月令七十二候集解》", "tag": "winter"},
    {"text": "冬至一阳生，养藏之道。宜静养安神，温补阳气。", "source": "《黄帝内经》", "tag": "winter"},
    {"text": "小寒，冷气积久而为寒。宜温补脾肾，敛藏精气。", "source": "《月令七十二候集解》", "tag": "winter"},
    {"text": "大寒，寒气之逆极。宜温阳固表，养精蓄锐。", "source": "《授时通考》", "tag": "winter"},
]

# 体质调理名言
CONSTITUTION_QUOTES = [
    {"text": "正气存内，邪不可干。邪之所凑，其气必虚。", "source": "《黄帝内经·素问》", "tag": "qixu", "constitution": "气虚质"},
    {"text": "劳则气耗，思则气结。气虚者当以补气为先，黄芪人参为君。", "source": "《黄帝内经》", "tag": "qixu", "constitution": "气虚质"},
    {"text": "阳气者，若天与日，失其所则折寿而不彰。阳虚者当温阳固本。", "source": "《黄帝内经·素问》", "tag": "yangxu", "constitution": "阳虚质"},
    {"text": "阴者，藏精而起亟也。阴虚者当滋阴降火，以静制动。", "source": "《黄帝内经·素问》", "tag": "yinxu", "constitution": "阴虚质"},
    {"text": "脾为生痰之源，肺为贮痰之器。痰湿者当健脾化湿。", "source": "《黄帝内经》", "tag": "tanshi", "constitution": "痰湿质"},
    {"text": "湿热内蕴，如暑天之闷热。当清热利湿，分消走泄。", "source": "《温热经纬》", "tag": "shire", "constitution": "湿热质"},
    {"text": "血瘀者，经络不通，不通则痛。当活血化瘀，行气通络。", "source": "《金匮要略》", "tag": "xueyu", "constitution": "血瘀质"},
    {"text": "肝喜条达而恶抑郁。气郁者当疏肝理气，调畅情志。", "source": "《黄帝内经》", "tag": "qiyu", "constitution": "气郁质"},
    {"text": "先天禀赋不足，后天调养为要。特禀质当固表益气，避免过敏。", "source": "《景岳全书》", "tag": "tebing", "constitution": "特禀质"},
    {"text": "阴阳平秘，精神乃治。平和质者当顺应四时，调和阴阳。", "source": "《黄帝内经》", "tag": "pinghe", "constitution": "平和质"},
]

# 日常养生名言（通用）
DAILY_QUOTES = [
    {"text": "上医治未病，中医治欲病，下医治已病。养生之道，贵在未病先防。", "source": "《黄帝内经》", "tag": "general"},
    {"text": "饮食有节，起居有常，不妄作劳，故能形与神俱。", "source": "《黄帝内经·上古天真论》", "tag": "general"},
    {"text": "人以天地之气生，四时之法成。顺应天时，方为养生之根本。", "source": "《黄帝内经》", "tag": "general"},
    {"text": "恬淡虚无，真气从之；精神内守，病安从来。", "source": "《黄帝内经·上古天真论》", "tag": "general"},
    {"text": "胃者，五脏六腑之海也。水谷皆入于胃，五脏六腑皆禀气于胃。", "source": "《黄帝内经·素问》", "tag": "diet"},
    {"text": "五谷为养，五果为助，五畜为益，五菜为充。气味合而服之，以补精益气。", "source": "《黄帝内经·脏气法时论》", "tag": "diet"},
    {"text": "药补不如食补。食者，生民之天，活人之本也。", "source": "《太平圣惠方》", "tag": "diet"},
    {"text": "食不语，寝不言。细嚼慢咽，脾胃自安。", "source": "《论语·乡党》", "tag": "diet"},
    {"text": "脾胃者，后天之本，气血生化之源。养脾胃即所以养元气。", "source": "《景岳全书》", "tag": "diet"},
    {"text": "药养不如食养，食养不如心养。心定则气顺，气和则血畅。", "source": "《寿世保元》", "tag": "emotion"},
    {"text": "怒伤肝、喜伤心、思伤脾、悲伤肺、恐伤肾。情志调和，五脏乃安。", "source": "《黄帝内经》", "tag": "emotion"},
    {"text": "心者，君主之官也，神明出焉。养心安神，百病不侵。", "source": "《黄帝内经·灵兰秘典论》", "tag": "emotion"},
    {"text": "怒则气上，喜则气缓，悲则气消，恐则气下，惊则气乱。", "source": "《黄帝内经·举痛论》", "tag": "emotion"},
    {"text": "百病生于气也。怒则气逆，甚则呕血。", "source": "《黄帝内经》", "tag": "emotion"},
    {"text": "动则生阳，静则生阴。一动一静，互为其根。", "source": "《周易·系辞》", "tag": "exercise"},
    {"text": "流水不腐，户枢不蠹。形不动则精不流，精不流则气郁。", "source": "《吕氏春秋》", "tag": "exercise"},
    {"text": "导引者，熊经鸟伸，为寿而已矣。此导引之士，养形之人。", "source": "《庄子·刻意》", "tag": "exercise"},
    {"text": "一身动则一身强。每日步行三千步，胜过补药一钱。", "source": "《老老恒言》", "tag": "exercise"},
    {"text": "太极拳者，以心行气，以气运身。意气君来骨肉臣。", "source": "《太极拳论》", "tag": "exercise"},
    {"text": "起居有常，不妄作劳。日出而作，日入而息。", "source": "《黄帝内经》", "tag": "sleep"},
    {"text": "子时（23-1点）胆经当令，丑时（1-3点）肝经当令。此时安睡，养肝利胆。", "source": "《黄帝内经》", "tag": "sleep"},
    {"text": "先睡心，后睡眼。心定神安，自然入眠。", "source": "《蔡季通睡诀》", "tag": "sleep"},
    {"text": "药补千朝，不如独眠一宿。安眠是养生第一要务。", "source": "《养性延命录》", "tag": "sleep"},
    {"text": "寐不厌蹙，觉不厌舒。侧卧为佳，右侧尤宜。", "source": "《老老恒言》", "tag": "sleep"},
    {"text": "春捂秋冻，不生杂病。穿衣之道，顺应天时。", "source": "《摄生消息论》", "tag": "season"},
    {"text": "春养肝，夏养心，秋养肺，冬养肾。四时养生，各有所宜。", "source": "《黄帝内经》", "tag": "season"},
    {"text": "不治已病治未病，不治已乱治未乱，此之谓也。", "source": "《黄帝内经·四气调神大论》", "tag": "general"},
    {"text": "五劳所伤：久视伤血，久卧伤气，久坐伤肉，久立伤骨，久行伤筋。", "source": "《黄帝内经·宣明五气》", "tag": "general"},
    {"text": "人以水谷为本，故人绝水谷则死，脉无胃气亦死。", "source": "《黄帝内经·平人绝谷论》", "tag": "diet"},
    {"text": "天有四时五行，以生长收藏，以生寒暑燥湿风。人有五脏化五气，以生喜怒悲忧恐。", "source": "《黄帝内经·阴阳应象大论》", "tag": "general"},
    {"text": "善养生者，上养神，中养气，下养形。", "source": "《三元参赞延寿书》", "tag": "general"},
    {"text": "养心莫善于寡欲。欲不可纵，志不可满。", "source": "《孟子》", "tag": "emotion"},
    {"text": "冬不藏精，春必病温。冬季养生，重在藏精。", "source": "《黄帝内经》", "tag": "winter"},
    {"text": "春夏养阳，秋冬养阴，以从其根，故与万物沉浮于生长之门。", "source": "《黄帝内经·四气调神大论》", "tag": "season"},
    {"text": "早卧早起，与鸡俱兴，使志安宁，以缓秋刑。", "source": "《黄帝内经》", "tag": "autumn"},
    {"text": "夏月伏阴在内，暖食尤宜。瓜果虽美，不可贪多。", "source": "《颐身集》", "tag": "summer"},
    {"text": "八段锦、太极拳，功不在猛，贵在持久。日日不辍，功效自见。", "source": "养生古训", "tag": "exercise"},
    {"text": "背为阳，腹为阴。常摩腹以助消化，常擦背以升阳气。", "source": "《老老恒言》", "tag": "exercise"},
    {"text": "一日之计在于晨，一年之计在于春。晨起一杯温水，润五脏、通经络。", "source": "民间养生谚语", "tag": "general"},
]

# 全部名言合并
ALL_QUOTES = SOLAR_TERM_QUOTES + CONSTITUTION_QUOTES + DAILY_QUOTES


def _get_daily_seed(extra: str = "") -> int:
    """基于日期生成确定性随机种子，同一天返回同一结果"""
    today = datetime.now().strftime("%Y-%m-%d")
    seed_str = f"{today}-{extra}"
    return int(hashlib.md5(seed_str.encode()).hexdigest(), 16)


def _get_season() -> str:
    """获取当前季节"""
    month = datetime.now().month
    if month in (3, 4, 5):
        return "spring"
    elif month in (6, 7, 8):
        return "summer"
    elif month in (9, 10, 11):
        return "autumn"
    else:
        return "winter"


def _get_solar_term() -> str:
    """获取当前节气关键词"""
    month = datetime.now().month
    day = datetime.now().day
    terms = [
        (1, 6, "小寒"), (1, 20, "大寒"), (2, 4, "立春"), (2, 19, "雨水"),
        (3, 6, "惊蛰"), (3, 21, "春分"), (4, 5, "清明"), (4, 20, "谷雨"),
        (5, 6, "立夏"), (5, 21, "小满"), (6, 6, "芒种"), (6, 21, "夏至"),
        (7, 7, "小暑"), (7, 23, "大暑"), (8, 7, "立秋"), (8, 23, "处暑"),
        (9, 8, "白露"), (9, 23, "秋分"), (10, 8, "寒露"), (10, 23, "霜降"),
        (11, 7, "立冬"), (11, 22, "小雪"), (12, 7, "大雪"), (12, 22, "冬至"),
    ]
    current = terms[0][2]
    for m, d, name in terms:
        if (month > m) or (month == m and day >= d):
            current = name
    return current


@router.get("/daily")
async def get_daily_wisdom(
    constitution: str = None,
    category: str = None,
):
    """
    获取每日养生名言

    - 同一天同一用户看到相同名言（确定性随机）
    - 可按体质、分类筛选优先级
    - category: diet/exercise/sleep/emotion/season/general
    """
    season = _get_season()

    # 按优先级分组
    priority_quotes = []

    # 1. 体质相关名言（最高优先）
    if constitution:
        ct = constitution.lower()
        for q in CONSTITUTION_QUOTES:
            if q.get("tag") == ct or q.get("constitution") == constitution:
                priority_quotes.append({**q, "priority": 3})

    # 2. 节气相关名言
    for q in SOLAR_TERM_QUOTES:
        if q.get("tag") == season:
            priority_quotes.append({**q, "priority": 2})

    # 3. 指定分类
    if category:
        for q in DAILY_QUOTES:
            if q.get("tag") == category:
                priority_quotes.append({**q, "priority": 2})

    # 4. 通用名言
    for q in DAILY_QUOTES:
        if q.get("tag") in ("general", category or "general"):
            priority_quotes.append({**q, "priority": 1})

    # 确定性选择（每天固定）
    seed = _get_daily_seed(constitution or "all")
    rng = random.Random(seed)

    # 按优先级排序后随机选
    if priority_quotes:
        priority_quotes.sort(key=lambda x: x["priority"], reverse=True)
        # 从前60%高优先中随机选
        top_n = max(1, len(priority_quotes) // 2)
        selected = rng.choice(priority_quotes[:top_n])
    else:
        selected = rng.choice(ALL_QUOTES)

    return {
        "success": True,
        "data": {
            "text": selected["text"],
            "source": selected["source"],
            "category": selected.get("tag", "general"),
            "constitution": selected.get("constitution"),
            "date": datetime.now().strftime("%Y-%m-%d"),
            "solar_term": _get_solar_term(),
            "season": season,
        }
    }


@router.get("/collection")
async def get_wisdom_collection(
    category: str = None,
    constitution: str = None,
    limit: int = 10,
    offset: int = 0,
):
    """获取养生名言集合（知识库）"""
    quotes = ALL_QUOTES

    if category:
        quotes = [q for q in quotes if q.get("tag") == category]

    if constitution:
        ct = constitution.lower()
        ct_quotes = [q for q in quotes if q.get("tag") == ct or q.get("constitution") == constitution]
        if ct_quotes:
            quotes = ct_quotes

    total = len(quotes)
    quotes = quotes[offset:offset + limit]

    return {
        "success": True,
        "data": {
            "items": quotes,
            "total": total,
            "limit": limit,
            "offset": offset,
        }
    }


@router.get("/categories")
async def get_wisdom_categories():
    """获取名言分类列表"""
    categories = {
        "diet": {"name": "饮食养生", "icon": "🍽️", "count": 0},
        "exercise": {"name": "运动养生", "icon": "🏃", "count": 0},
        "sleep": {"name": "睡眠养生", "icon": "🌙", "count": 0},
        "emotion": {"name": "情志养生", "icon": "💭", "count": 0},
        "season": {"name": "四季养生", "icon": "🌿", "count": 0},
        "general": {"name": "综合养生", "icon": "📖", "count": 0},
        "spring": {"name": "春季节气", "icon": "🌸", "count": 0},
        "summer": {"name": "夏季节气", "icon": "☀️", "count": 0},
        "autumn": {"name": "秋季节气", "icon": "🍂", "count": 0},
        "winter": {"name": "冬季节气", "icon": "❄️", "count": 0},
    }

    # 统计数量
    for key in categories:
        categories[key]["count"] = len([q for q in ALL_QUOTES if q.get("tag") == key])

    return {
        "success": True,
        "data": categories,
    }
