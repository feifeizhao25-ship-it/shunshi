"""口语 → 知识库用词的别名表（查询扩展）。

用户爱说“睡不着、头发掉、脖子僵”，知识库写的是“失眠、脱发、颈椎”。词面检索对不上，是口语化问法漏召回的主要原因。
本表只做一件事：当问句里出现左边的口语说法，就把右边的书面词追加进检索用的查询（不改变展示给用户的问句）。
约束：
- 只收通用生活用语到通用健康词的对应，不收疾病诊断、药物、功效承诺；
- 每条都可审阅；新增条目走和知识条目一样的“待审核→人工通过”流程（见 self_improve 的 alias 候选，暂不自动入库）；
- RAG_ALIASES=0 可单独关闭。
"""
from __future__ import annotations

import os

ALIASES_CN: dict[str, list[str]] = {
    "睡不着": ["失眠", "睡眠", "助眠"], "睡不好": ["失眠", "睡眠"], "翻来覆去": ["失眠", "睡眠"], "夜里醒": ["失眠", "睡眠"], "夜里老是醒": ["失眠", "睡眠"],
    "犯困": ["疲劳", "睡眠"], "没精神": ["疲劳乏力"], "觉得累": ["疲劳乏力"], "累": ["疲劳"],
    "头发掉": ["脱发"], "掉头发": ["脱发"], "脖子": ["颈椎"], "颈": ["颈椎"], "腰酸": ["腰部放松"], "背痛": ["肩部放松", "腰部放松"],
    "肚子": ["胃肠", "脾胃"], "胃不舒服": ["胃寒胃痛", "胃病"], "胃胀": ["胃病"], "拉肚子": ["腹泻", "脾胃"], "便秘": ["便秘", "肠道"],
    "眼睛干": ["干眼症"], "眼睛疲劳": ["眼部保健操", "干眼症"], "眼睛不好": ["视力保护"], "盯着屏幕": ["电子设备", "视力保护"], "看手机": ["电子设备", "干眼症"],
    "怀孕": ["孕期", "孕早期"], "孕": ["孕期"], "生完孩子": ["产后"], "坐月子": ["产后"], "例假": ["经期"], "月经": ["经期"],
    "爸妈": ["老年人", "中老年"], "老人": ["老年人", "高龄老人"], "爷爷奶奶": ["老年人", "高龄老人"], "上年纪": ["老年人"],
    "孩子": ["儿童"], "小孩": ["儿童"], "小朋友": ["儿童青少年"], "青春期": ["青少年"], "学生": ["备考学生", "青少年"],
    "加班": ["上班族", "加班应急"], "上班": ["上班族"], "办公室": ["上班族"], "夜班": ["夜班倒班"], "出差": ["商旅人士"], "倒时差": ["商旅人士"], "应酬": ["应酬饮酒"],
    "减肥": ["减重", "体重管理"], "变胖": ["体重管理"], "吃素": ["素食者"], "素食": ["素食者"],
    "喝水": ["饮水"], "喝茶": ["饮茶", "茶饮"], "没胃口": ["饮食建议", "脾胃"],
    "心烦": ["情绪", "烦躁"], "烦躁": ["情绪释放", "即时情绪应对"], "发火": ["情绪释放", "即时情绪应对"], "崩溃": ["即时情绪应对", "情绪释放"], "焦虑": ["焦虑", "正念冥想"], "紧张": ["焦虑", "压力管理"], "压力大": ["压力管理"], "想不开": ["心理关怀"],
    "放松": ["放松", "睡前仪式"], "睡前": ["睡前仪式", "助眠"],
    "穴位": ["助眠穴位", "穴位"], "做操": ["保健操"], "站桩": ["太极站桩"],
    "运动多久": ["每周动多少", "运动建议"], "锻炼": ["运动建议"],
    "写日记": ["日记记录", "感恩日记"], "日记": ["日记记录"],
    "AI助手": ["温和回复原则", "对话风格"], "语气": ["温和回复原则", "对话风格"],
    "饮食": ["饮食建议"], "吃什么": ["食疗", "饮食建议"], "干燥": ["秋季食疗", "润燥"],
}

ALIASES_EN: dict[str, list[str]] = {
    "vegetarian": ["plant-based", "vegan"], "inflammation": ["anti-inflammatory"], "tired": ["fatigue", "energy"], "sleepless": ["insomnia", "sleep"],
    "wake up": ["sleep", "morning ritual"], "waking": ["sleep"], "screens": ["eye strain", "screen"], "eyesight": ["eye health", "vision"],
    "teenager": ["teen", "adolescent"], "anxious": ["anxiety", "stress"], "stress": ["stress management"], "wind down": ["evening ritual", "sleep optimization"],
    "baby": ["postpartum"], "pregnant": ["pregnancy", "trimester"], "older": ["elderly", "senior"], "retirement": ["senior", "elderly"],
    "calm": ["relaxation", "breathing"], "gym": ["fitness"], "jet lag": ["frequent traveler", "travel"], "shift": ["shift work"],
    "snacks": ["nutrition", "meals"], "tone": ["tone style", "communication"], "words": ["prohibited language"],
}


def enabled(env=None) -> bool:
    env = os.environ if env is None else env
    return str(env.get("RAG_ALIASES", "1")).strip().lower() not in ("0", "false", "no", "off")


def expand(query: str, lang: str) -> str:
    """返回“原问句 + 追加的书面词”；没有命中任何别名时原样返回。"""
    table = ALIASES_CN if lang == "cn" else ALIASES_EN
    q = query if lang == "cn" else query.lower()
    extra: list[str] = []
    for k, vs in table.items():
        if k in q:
            for v in vs:
                if v not in extra and v not in q:
                    extra.append(v)
    return f"{query} {' '.join(extra)}" if extra else query
