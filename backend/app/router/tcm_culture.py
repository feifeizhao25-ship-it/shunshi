"""
顺时 — 中医文化 API (shunshi-tcm-culture)
中医文化科普、历史人物、经典古籍、文化故事
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List

router = APIRouter(prefix="/api/v1/tcm-culture", tags=["tcm-culture"])

TCM_CLASSICS = [
    {
        "id": "huangdi_neijing", "title": "黄帝内经", "dynasty": "先秦至西汉",
        "type": "综合医学", "authors": ["多位医家合著"],
        "significance": "中医理论的奠基之作，阐述了阴阳五行、脏腑经络、病因病机等基本理论",
        "famous_quotes": [
            "上工治未病，不治已病",
            "春夏养阳，秋冬养阴",
            "正气存内，邪不可干"
        ]
    },
    {
        "id": "shennong_bencao", "title": "神农本草经", "dynasty": "东汉",
        "type": "本草学", "authors": ["神农（传说）"],
        "significance": "中国第一部本草学著作，记载了365种药物，奠定了中药学基础",
        "famous_quotes": ["药有酸咸甘苦辛五味，又有寒热温凉四气"]
    },
    {
        "id": "shanghan_lun", "title": "伤寒论", "dynasty": "东汉",
        "type": "临床医学", "authors": ["张仲景"],
        "significance": "中医临床医学的奠基之作，创立了六经辨证体系，记录大量临床方剂",
        "famous_quotes": ["观其脉证，知犯何逆，随证治之"]
    },
    {
        "id": "bencao_gangmu", "title": "本草纲目", "dynasty": "明代",
        "type": "本草学", "authors": ["李时珍"],
        "significance": "集中药学之大成，收录1892种药物，被誉为'东方药物巨典'",
        "famous_quotes": ["医者仁术"]
    }
]

FAMOUS_DOCTORS = [
    {
        "id": "huangdi", "name": "黄帝", "era": "上古时期",
        "title": "传说中的医学始祖",
        "contribution": "相传与岐伯等医家讨论医学，由此形成了《黄帝内经》",
        "legacy": "中医理论体系的奠基人，'岐黄之术'即源于此"
    },
    {
        "id": "bian_que", "name": "扁鹊", "era": "春秋战国",
        "title": "古代名医",
        "contribution": "精于诊脉，创望、闻、问、切四诊合参，奠定了中医诊断学基础",
        "legacy": "被誉为'脉学之宗'"
    },
    {
        "id": "hua_tuo", "name": "华佗", "era": "东汉",
        "title": "外科鼻祖",
        "contribution": "首创麻沸散（最早的麻醉药），发明五禽戏，擅长外科手术",
        "legacy": "'外科圣手'，五禽戏至今仍是重要养生功法"
    },
    {
        "id": "zhang_zhongjing", "name": "张仲景", "era": "东汉",
        "title": "医圣",
        "contribution": "著《伤寒杂病论》，创立了中医临床辨证论治体系",
        "legacy": "被尊为'医圣'，其理法方药体系沿用至今"
    },
    {
        "id": "sun_simiao", "name": "孙思邈", "era": "唐代",
        "title": "药王",
        "contribution": "著《千金方》，强调医德，提倡'大医精诚'",
        "legacy": "被尊为'药王'，'大医精诚'成为中医医德的最高准则"
    },
    {
        "id": "li_shizhen", "name": "李时珍", "era": "明代",
        "title": "本草学家",
        "contribution": "历时27年著成《本草纲目》，收录1892种药物",
        "legacy": "《本草纲目》是中医药学的百科全书式著作"
    }
]

TCM_PHILOSOPHY = [
    {
        "concept": "天人合一",
        "explanation": "人体是自然的一部分，人的生命活动与天地自然的变化规律相一致",
        "practical_meaning": "顺应节气、季节变化调整生活方式，是中医养生的核心理念"
    },
    {
        "concept": "阴阳平衡",
        "explanation": "世间万物包含阴阳两方面，健康就是阴阳的相对平衡",
        "practical_meaning": "寒热、虚实的平衡，是中医诊断和治疗的基本原则"
    },
    {
        "concept": "五行相生相克",
        "explanation": "金木水火土五种基本物质的相互生化与制约关系",
        "practical_meaning": "五脏六腑与五行对应，通过五行关系理解脏腑之间的相互影响"
    },
    {
        "concept": "治未病",
        "explanation": "在疾病未发生前进行预防，维护健康，是中医最高境界",
        "practical_meaning": "注重日常养生，预防胜于治疗"
    }
]

CULTURE_STORIES = [
    {
        "id": "story_001",
        "title": "扁鹊见蔡桓公",
        "summary": "扁鹊三次见蔡桓公，每次都告诫其有病需治，桓公不以为然，最终病入膏肓，无可救药。",
        "moral": "小病不治，大病难医。凡事应防患于未然，养生重在预防。",
        "tcm_lesson": "治未病是中医最高境界，早发现、早调理胜过治已病"
    },
    {
        "id": "story_002",
        "title": "神农尝百草",
        "summary": "相传神农氏亲自尝百草，辨别药性，为民众寻找治病的草药，历经七十二毒。",
        "moral": "中医药文化是祖先无数次实践和牺牲换来的智慧结晶。",
        "tcm_lesson": "中药的药性知识来自长期实践，应尊重和传承"
    }
]


@router.get("/classics", summary="中医经典著作")
async def list_classics():
    return {"success": True, "data": {"classics": TCM_CLASSICS}}


@router.get("/classics/{classic_id}", summary="经典著作详情")
async def get_classic(classic_id: str):
    classic = next((c for c in TCM_CLASSICS if c["id"] == classic_id), None)
    if not classic:
        raise HTTPException(status_code=404, detail="著作不存在")
    return {"success": True, "data": classic}


@router.get("/famous-doctors", summary="历代名医")
async def list_famous_doctors():
    return {"success": True, "data": {"doctors": FAMOUS_DOCTORS}}


@router.get("/famous-doctors/{doctor_id}", summary="名医详情")
async def get_famous_doctor(doctor_id: str):
    aliases = {
        "bianque": "bian_que",
        "huatuo": "hua_tuo",
        "zhangzhongjing": "zhang_zhongjing",
        "sunsimiao": "sun_simiao",
        "lishizhen": "li_shizhen",
    }
    canonical_id = aliases.get(doctor_id, doctor_id)
    doctor = next((d for d in FAMOUS_DOCTORS if d["id"] == canonical_id), None)
    if not doctor:
        raise HTTPException(status_code=404, detail="名医不存在")
    return {"success": True, "data": doctor}


@router.get("/philosophy", summary="中医哲学理念")
async def get_philosophy():
    return {"success": True, "data": {"concepts": TCM_PHILOSOPHY}}


@router.get("/stories", summary="中医文化故事")
async def list_stories():
    return {"success": True, "data": {"stories": CULTURE_STORIES}}


@router.get("/daily-wisdom", summary="每日中医智慧")
async def get_daily_wisdom():
    from datetime import date
    import hashlib

    all_quotes = []
    for classic in TCM_CLASSICS:
        all_quotes.extend(classic.get("famous_quotes", []))
    today = date.today().isoformat()
    if all_quotes:
        index = int(hashlib.sha256(today.encode("utf-8")).hexdigest(), 16) % len(all_quotes)
        quote = all_quotes[index]
    else:
        quote = "医者仁术"
    return {
        "success": True,
        "data": {"quote": quote, "wisdom": quote, "date": today},
    }
