"""
体质辨识 API 路由
基于中医九种体质理论，提供问卷评估和个性化养生建议
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime

from app.database.db import get_db

router = APIRouter(tags=["体质辨识"])


# ==================== 九种体质定义 ====================

CONSTITUTION_TYPES = {
    "pinghe": {
        "name": "平和质",
        "name_en": "Balanced Constitution",
        "description": "阴阳气血调和，体态适中，面色润泽，精力充沛，睡眠良好",
        "characteristics": [
            "体形匀称健壮",
            "面色润泽红润",
            "精力充沛",
            "睡眠良好",
            "食欲正常",
            "二便调畅",
            "舌色淡红，苔薄白",
            "脉象和缓有力",
        ],
        "diet_advice": "饮食有节，不偏食偏嗜，粗细搭配，荤素均衡",
        "tea_advice": "四季均可饮用绿茶、菊花茶等平和茶饮",
        "exercise_advice": "适度运动，散步、太极拳、游泳均可",
        "avoid_list": ["暴饮暴食", "过度劳累", "熬夜", "偏食偏嗜"],
    },
    "qixu": {
        "name": "气虚质",
        "name_en": "Qi Deficiency",
        "description": "元气不足，易疲乏，气短懒言，易出汗，易感冒",
        "characteristics": [
            "容易疲乏",
            "气短懒言",
            "容易出汗",
            "容易感冒",
            "声音低弱",
            "易精神不振",
            "舌淡红，舌体胖大",
            "脉虚缓",
        ],
        "diet_advice": "多食益气健脾食物：黄芪、人参、山药、大枣、小米、糯米、扁豆",
        "tea_advice": "黄芪红枣茶、人参茶、党参茶",
        "exercise_advice": "舒缓运动为主：散步、太极拳、八段锦，避免剧烈运动",
        "avoid_list": ["过度劳累", "大汗淋漓", "生冷食物", "熬夜", "剧烈运动"],
    },
    "yangxu": {
        "name": "阳虚质",
        "name_en": "Yang Deficiency",
        "description": "阳气不足，手脚发凉，畏寒怕冷，精神不振",
        "characteristics": [
            "手足不温",
            "畏寒怕冷",
            "精神不振",
            "面色柔白",
            "喜热饮食",
            "吃凉则不适",
            "舌淡胖嫩",
            "脉沉迟",
        ],
        "diet_advice": "多食温阳散寒食物：羊肉、生姜、桂圆、韭菜、核桃、栗子、红枣",
        "tea_advice": "姜枣茶、桂圆红茶、肉桂茶",
        "exercise_advice": "多晒太阳，适合户外运动，太极拳、艾灸足三里",
        "avoid_list": ["生冷食物", "寒凉环境", "过度吹空调", "冰饮", "寒性水果"],
    },
    "yinxu": {
        "name": "阴虚质",
        "name_en": "Yin Deficiency",
        "description": "体内阴液亏少，口燥咽干，手足心热，盗汗",
        "characteristics": [
            "口燥咽干",
            "手足心热",
            "鼻微干",
            "喜冷饮",
            "大便干燥",
            "面色潮红",
            "舌红少津",
            "脉细数",
        ],
        "diet_advice": "多食滋阴润燥食物：银耳、百合、雪梨、枸杞、黑芝麻、鸭肉、甲鱼",
        "tea_advice": "百合银耳茶、枸杞菊花茶、麦冬茶",
        "exercise_advice": "中小强度运动，游泳、瑜伽、慢跑，避免大汗",
        "avoid_list": ["辛辣食物", "煎炸食物", "熬夜", "过度运动", "羊肉等温热食物"],
    },
    "tanshi": {
        "name": "痰湿质",
        "name_en": "Phlegm-Dampness",
        "description": "痰湿凝聚，形体肥胖，腹部肥满松软，口黏腻",
        "characteristics": [
            "体形肥胖，腹部肥满松软",
            "面部油脂较多",
            "多汗且黏",
            "口黏腻或口甜",
            "身重不爽",
            "嗜食肥甘",
            "舌体胖大，苔滑腻",
            "脉滑",
        ],
        "diet_advice": "少食肥甘厚腻，多食健脾利湿食物：薏米、赤小豆、冬瓜、荷叶、陈皮、山药",
        "tea_advice": "荷叶茶、薏米红豆茶、陈皮茶、山楂茶",
        "exercise_advice": "加强有氧运动，快走、慢跑、游泳，控制体重",
        "avoid_list": ["肥甘厚腻", "甜食", "酒类", "久坐不动", "生冷食物"],
    },
    "shire": {
        "name": "湿热质",
        "name_en": "Damp-Heat",
        "description": "湿热内蕴，面垢油光，口苦口干，身重困倦",
        "characteristics": [
            "面垢油光",
            "易生痤疮",
            "口苦口干",
            "身重困倦",
            "大便黏滞不畅",
            "小便短黄",
            "舌质偏红，苔黄腻",
            "脉滑数",
        ],
        "diet_advice": "多食清热利湿食物：绿豆、苦瓜、冬瓜、黄瓜、薏米、莲藕",
        "tea_advice": "金银花茶、菊花茶、荷叶茶、绿豆汤",
        "exercise_advice": "中等强度有氧运动，游泳最佳，适合夏季户外活动",
        "avoid_list": ["辛辣食物", "油腻食物", "酒类", "煎炸食物", "熬夜"],
    },
    "xueyu": {
        "name": "血瘀质",
        "name_en": "Blood Stasis",
        "description": "血行不畅，肤色晦暗，容易出现瘀斑",
        "characteristics": [
            "肤色晦暗",
            "色素沉着",
            "容易出现瘀斑",
            "口唇暗淡",
            "眼眶暗黑",
            "易有疼痛",
            "舌暗有瘀点",
            "脉细涩",
        ],
        "diet_advice": "多食活血化瘀食物：山楂、红花、玫瑰花、黑豆、醋、黑木耳",
        "tea_advice": "玫瑰花茶、山楂茶、红花茶、三七茶",
        "exercise_advice": "适当运动促进气血运行，太极拳、瑜伽、舞蹈",
        "avoid_list": ["久坐不动", "寒凉环境", "情绪压抑", "过度安逸"],
    },
    "qiyu": {
        "name": "气郁质",
        "name_en": "Qi Stagnation",
        "description": "气机郁滞，神情抑郁，忧虑脆弱",
        "characteristics": [
            "神情抑郁",
            "情感脆弱",
            "烦闷不乐",
            "多愁善感",
            "胸胁胀满",
            "善太息",
            "舌淡红，苔薄白",
            "脉弦",
        ],
        "diet_advice": "多食疏肝理气食物：玫瑰花、佛手、柑橘、萝卜、荞麦、金针菇",
        "tea_advice": "玫瑰花茶、茉莉花茶、佛手茶、合欢花茶",
        "exercise_advice": "多参加户外运动和社交活动，跑步、登山、唱歌、舞蹈",
        "avoid_list": ["长期压抑情绪", "过度思虑", "久坐不动", "独处寡言"],
    },
    "tebing": {
        "name": "特禀质",
        "name_en": "Special Constitution",
        "description": "先天禀赋不足或过敏体质，易过敏，对外界适应能力差",
        "characteristics": [
            "过敏体质",
            "易患哮喘",
            "容易打喷嚏",
            "鼻塞流涕",
            "皮肤易起荨麻疹",
            "对季节变化敏感",
            "适应能力差",
        ],
        "diet_advice": "饮食清淡，避免过敏源食物。多食益气固表食物：黄芪、大枣、山药、灵芝",
        "tea_advice": "黄芪红枣茶、灵芝茶、防风茶",
        "exercise_advice": "适度运动增强体质，游泳、散步、太极拳",
        "avoid_list": ["已知过敏食物", "花粉环境", "冷空气", "新装修环境", "宠物毛发"],
    },
}

# 9种体质键名列表（保持顺序）
CONSTITUTION_KEYS = [
    "pinghe", "qixu", "yangxu", "yinxu", "tanshi", "shire", "xueyu", "qiyu", "tebing"
]


# ==================== 25道问卷题目 ====================

QUESTIONS = [
    {
        "id": 1,
        "question": "您精力充沛吗？",
        "options": [
            {"text": "是", "score_map": {"pinghe": 5, "qiyu": 1}},
            {"text": "有时是", "score_map": {"pinghe": 3}},
            {"text": "否", "score_map": {"qixu": 2, "tebing": 1}},
        ],
    },
    {
        "id": 2,
        "question": "您容易疲乏吗？",
        "options": [
            {"text": "容易", "score_map": {"qixu": 5, "yangxu": 2}},
            {"text": "有时容易", "score_map": {"qixu": 3}},
            {"text": "不容易", "score_map": {"pinghe": 3}},
        ],
    },
    {
        "id": 3,
        "question": "您容易气短（呼吸短促、接不上气）吗？",
        "options": [
            {"text": "是", "score_map": {"qixu": 4, "yangxu": 1}},
            {"text": "有时是", "score_map": {"qixu": 2}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 4,
        "question": "您容易心慌吗？",
        "options": [
            {"text": "是", "score_map": {"yinxu": 3, "qixu": 2}},
            {"text": "有时是", "score_map": {"yinxu": 2, "qiyu": 1}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 5,
        "question": "您容易头晕或站起时眩晕吗？",
        "options": [
            {"text": "是", "score_map": {"yinxu": 4, "qixu": 2, "xueyu": 1}},
            {"text": "有时是", "score_map": {"yinxu": 2, "qixu": 1}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 6,
        "question": "您容易失眠吗？",
        "options": [
            {"text": "是", "score_map": {"yinxu": 4, "qiyu": 2}},
            {"text": "有时是", "score_map": {"yinxu": 2, "qiyu": 1}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 7,
        "question": "您感到手脚冰凉吗？",
        "options": [
            {"text": "是", "score_map": {"yangxu": 5, "xueyu": 1}},
            {"text": "有时是", "score_map": {"yangxu": 3}},
            {"text": "否", "score_map": {"pinghe": 2, "yinxu": 1}},
        ],
    },
    {
        "id": 8,
        "question": "您怕冷吗（衣服比别人穿得多）？",
        "options": [
            {"text": "是", "score_map": {"yangxu": 5}},
            {"text": "有时是", "score_map": {"yangxu": 3}},
            {"text": "否", "score_map": {"pinghe": 2, "yinxu": 1}},
        ],
    },
    {
        "id": 9,
        "question": "您感觉身体沉重或不轻松吗？",
        "options": [
            {"text": "是", "score_map": {"tanshi": 5, "shire": 2}},
            {"text": "有时是", "score_map": {"tanshi": 3, "shire": 1}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 10,
        "question": "您吃（喝）凉的东西会感到不舒服或者怕吃凉的嗎？",
        "options": [
            {"text": "是", "score_map": {"yangxu": 5}},
            {"text": "有时是", "score_map": {"yangxu": 3, "qixu": 1}},
            {"text": "否", "score_map": {"pinghe": 2, "yinxu": 1}},
        ],
    },
    {
        "id": 11,
        "question": "您感到口干舌燥吗？",
        "options": [
            {"text": "是", "score_map": {"yinxu": 5, "shire": 2}},
            {"text": "有时是", "score_map": {"yinxu": 3}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 12,
        "question": "您感到口苦或嘴里有异味吗？",
        "options": [
            {"text": "是", "score_map": {"shire": 5, "xueyu": 1}},
            {"text": "有时是", "score_map": {"shire": 3}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 13,
        "question": "您面部或鼻部有油腻感或者油亮发光吗？",
        "options": [
            {"text": "是", "score_map": {"tanshi": 5, "shire": 3}},
            {"text": "有时是", "score_map": {"tanshi": 3, "shire": 1}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 14,
        "question": "您腹痛吗？",
        "options": [
            {"text": "是", "score_map": {"xueyu": 3, "yangxu": 2, "qiyu": 1}},
            {"text": "有时是", "score_map": {"xueyu": 2, "qiyu": 1}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 15,
        "question": "您大便黏滞不爽（容易粘马桶）吗？",
        "options": [
            {"text": "是", "score_map": {"tanshi": 5, "shire": 2}},
            {"text": "有时是", "score_map": {"tanshi": 3, "shire": 1}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 16,
        "question": "您大便干燥吗？",
        "options": [
            {"text": "是", "score_map": {"yinxu": 4, "xueyu": 1}},
            {"text": "有时是", "score_map": {"yinxu": 2}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 17,
        "question": "您小便时尿道有发热感、尿色浓（深）吗？",
        "options": [
            {"text": "是", "score_map": {"shire": 5}},
            {"text": "有时是", "score_map": {"shire": 3}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 18,
        "question": "您手脚心发热吗？",
        "options": [
            {"text": "是", "score_map": {"yinxu": 5}},
            {"text": "有时是", "score_map": {"yinxu": 3}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 19,
        "question": "您的皮肤在不知不觉中会出现青紫瘀斑吗？",
        "options": [
            {"text": "是", "score_map": {"xueyu": 5}},
            {"text": "有时是", "score_map": {"xueyu": 3}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 20,
        "question": "您两颧部有红斑或肤色暗沉吗？",
        "options": [
            {"text": "是", "score_map": {"xueyu": 4, "yinxu": 2}},
            {"text": "有时是", "score_map": {"xueyu": 2}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 21,
        "question": "您眼睛干涩吗？",
        "options": [
            {"text": "是", "score_map": {"yinxu": 4, "xueyu": 1}},
            {"text": "有时是", "score_map": {"yinxu": 2}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 22,
        "question": "您感到郁闷、不高兴吗？",
        "options": [
            {"text": "是", "score_map": {"qiyu": 5}},
            {"text": "有时是", "score_map": {"qiyu": 3}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 23,
        "question": "您容易感冒吗？",
        "options": [
            {"text": "是", "score_map": {"qixu": 5, "tebing": 3, "yangxu": 1}},
            {"text": "有时是", "score_map": {"qixu": 3, "tebing": 1}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 24,
        "question": "您没有感冒也会打喷嚏吗？",
        "options": [
            {"text": "是", "score_map": {"tebing": 5, "yangxu": 1}},
            {"text": "有时是", "score_map": {"tebing": 3}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
    {
        "id": 25,
        "question": "您起荨麻疹（风疹块、风疙瘩）吗？",
        "options": [
            {"text": "是", "score_map": {"tebing": 5, "shire": 1}},
            {"text": "有时是", "score_map": {"tebing": 3}},
            {"text": "否", "score_map": {"pinghe": 2}},
        ],
    },
]


# ==================== 数据库初始化 ====================

def _init_constitution_tables():
    """创建体质评估相关表"""
    db = get_db()
    db.executescript("""
        CREATE TABLE IF NOT EXISTS constitution_results (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            version TEXT DEFAULT 'v1',
            answers TEXT NOT NULL DEFAULT '[]',
            scores TEXT NOT NULL DEFAULT '{}',
            primary_type TEXT NOT NULL,
            secondary_types TEXT NOT NULL DEFAULT '[]',
            advice TEXT NOT NULL DEFAULT '',
            created_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_constitution_user ON constitution_results(user_id);
        CREATE INDEX IF NOT EXISTS idx_constitution_created ON constitution_results(created_at);
    """)
    db.commit()


# 在模块加载时初始化表
_init_constitution_tables()


# ==================== Pydantic 模型 ====================

class AnswerItem(BaseModel):
    """单题答案"""
    question_id: int
    option_index: int


class SubmitRequest(BaseModel):
    """提交问卷请求"""
    user_id: str
    answers: List[AnswerItem]


class ScoreItem(BaseModel):
    """单个体质分数"""
    type: str
    name: str
    score: float
    level: str  # normal / tendency / obvious


class SubmitResponse(BaseModel):
    """提交问卷响应"""
    result_id: str
    user_id: str
    primary_type: str
    primary_name: str
    secondary_types: List[str]
    scores: List[ScoreItem]
    advice: str


class ResultResponse(BaseModel):
    """评估结果响应"""
    result_id: str
    user_id: str
    version: str
    primary_type: str
    primary_name: str
    secondary_types: List[str]
    scores: Dict[str, float]
    advice: str
    created_at: str


class QuestionOption(BaseModel):
    """问卷选项"""
    text: str


class QuestionItem(BaseModel):
    """问卷题目"""
    id: int
    question: str
    options: List[str]


class ConstitutionTypeSummary(BaseModel):
    """体质摘要"""
    type: str
    name: str
    name_en: str
    description: str
    characteristics: List[str] = []
    diet_recommendations: List[str] = []
    lifestyle_advice: List[str] = []


class ConstitutionTypeDetail(BaseModel):
    """体质详情"""
    type: str
    name: str
    name_en: str
    description: str
    characteristics: List[str] = []
    diet_advice: str = ""
    tea_advice: str = ""
    exercise_advice: str = ""
    avoid_list: List[str] = []
    diet_recommendations: List[str] = []
    lifestyle_advice: List[str] = []


# ==================== 辅助函数 ====================

def _generate_id() -> str:
    """生成唯一ID"""
    return f"cr_{datetime.now().strftime('%Y%m%d%H%M%S%f')}"


def _calculate_scores(answers: List[AnswerItem]) -> Dict[str, float]:
    """根据用户答案计算9种体质分数"""
    scores = {key: 0.0 for key in CONSTITUTION_KEYS}

    for answer in answers:
        question = next((q for q in QUESTIONS if q["id"] == answer.question_id), None)
        if not question:
            continue
        if answer.option_index < 0 or answer.option_index >= len(question["options"]):
            continue

        option = question["options"][answer.option_index]
        score_map = option.get("score_map", {})
        for constitution_key, score_value in score_map.items():
            if constitution_key in scores:
                scores[constitution_key] += score_value

    return scores


def _determine_levels(scores: Dict[str, float]) -> Dict[str, str]:
    """
    根据分数判定体质偏颇程度
    normal: 正常（转化分<30）, tendency: 倾向（30-39）, obvious: 偏颇（>=40）
    原始分满分为该体质题目的5分之和，约60-75分
    转化分 = (原始分 - 题目数) / (题目数 × 4) × 100
    简化处理：直接按原始分判定
    """
    levels = {}
    for key, score in scores.items():
        # 简化判定阈值
        if score >= 40:
            levels[key] = "obvious"
        elif score >= 25:
            levels[key] = "tendency"
        else:
            levels[key] = "normal"
    return levels


def _get_primary_and_secondary(scores: Dict[str, float], levels: Dict[str, str]) -> tuple:
    """
    判断主导体质和倾向体质
    主导体质：最高分的偏颇体质（排除平和质如果其他有更高分）
    倾向体质：其他偏颇体质中分数>=25的
    """
    # 排除平和质，找偏颇体质
    biased_scores = {k: v for k, v in scores.items() if k != "pinghe"}

    if not biased_scores:
        return "pinghe", [], {}

    # 主导体质：最高分的偏颇体质
    sorted_biased = sorted(biased_scores.items(), key=lambda x: x[1], reverse=True)
    primary = sorted_biased[0][0]

    # 如果平和质分最高且其他都不高，则主为平和
    if scores["pinghe"] >= sorted_biased[0][1]:
        primary = "pinghe"

    # 倾向体质：除主导外分数>=25的偏颇体质
    secondary = [k for k, v in sorted_biased if k != primary and v >= 25]

    return primary, secondary


def _generate_advice(primary: str, secondary: List[str], levels: Dict[str, str]) -> str:
    """生成养生建议"""
    if primary == "pinghe":
        base = CONSTITUTION_TYPES["pinghe"]
        advice = f"您属于{base['name']}，体质较好。{base['diet_advice']}。继续保持良好的生活习惯。"
        if secondary:
            names = [CONSTITUTION_TYPES[s]["name"] for s in secondary[:2]]
            advice += f"\n\n有轻微的{'+'.join(names)}倾向，建议适当注意："
            for s in secondary[:2]:
                t = CONSTITUTION_TYPES[s]
                advice += f"\n- {t['name']}：{t['diet_advice']}"
        return advice

    primary_info = CONSTITUTION_TYPES[primary]
    advice = f"您的主导体质为【{primary_info['name']}】。\n\n"
    advice += f"**体质特点：** {primary_info['description']}\n\n"
    advice += f"**饮食建议：** {primary_info['diet_advice']}\n\n"
    advice += f"**茶饮推荐：** {primary_info['tea_advice']}\n\n"
    advice += f"**运动建议：** {primary_info['exercise_advice']}\n\n"
    advice += f"**注意事项：** {'、'.join(primary_info['avoid_list'])}"

    if secondary:
        names = [CONSTITUTION_TYPES[s]["name"] for s in secondary[:2]]
        advice += f"\n\n同时有{'+'.join(names)}倾向，建议兼顾调理。"

    return advice


# ==================== API 端点 ====================

def _ensure_user(db, user_id: str):
    """确保用户存在，不存在则自动创建（免费用户）"""
    existing = db.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
    if not existing:
        db.execute(
            """INSERT INTO users (id, name, password_hash, created_at, updated_at)
               VALUES (?, '用户', '', datetime('now'), datetime('now'))""",
            (user_id,)
        )
        db.commit()


@router.get("/questions", response_model=List[QuestionItem])
async def get_questions(
    version: str = Query("v1", description="问卷版本")
):
    """获取问卷题目"""
    # 预留版本控制，目前只有一个版本
    result = []
    for q in QUESTIONS:
        result.append(QuestionItem(
            id=q["id"],
            question=q["question"],
            options=[opt["text"] for opt in q["options"]],
        ))
    return result


@router.post("/submit", response_model=SubmitResponse)
async def submit_questionnaire(request: SubmitRequest):
    """
    提交问卷答案，计算体质评估结果

    算法说明：
    1. 根据用户选择的选项，累加各体质的原始分数
    2. 根据分数判定各体质的偏颇程度（正常/倾向/偏颇）
    3. 确定主导体质和倾向体质
    4. 生成个性化养生建议
    """
    # 验证答案数量
    if len(request.answers) == 0:
        raise HTTPException(status_code=400, detail="请至少回答1道题目")

    # 验证答案有效性
    question_ids = {q["id"] for q in QUESTIONS}
    for ans in request.answers:
        if ans.question_id not in question_ids:
            raise HTTPException(
                status_code=400,
                detail=f"无效的题目ID: {ans.question_id}"
            )
        q = next(q for q in QUESTIONS if q["id"] == ans.question_id)
        if ans.option_index < 0 or ans.option_index >= len(q["options"]):
            raise HTTPException(
                status_code=400,
                detail=f"题目{ans.question_id}的选项索引无效: {ans.option_index}"
            )

    # 计算分数
    raw_scores = _calculate_scores(request.answers)
    levels = _determine_levels(raw_scores)
    primary, secondary = _get_primary_and_secondary(raw_scores, levels)
    advice = _generate_advice(primary, secondary, levels)

    # 构建分数列表
    score_items = []
    for key in CONSTITUTION_KEYS:
        info = CONSTITUTION_TYPES[key]
        score_items.append(ScoreItem(
            type=key,
            name=info["name"],
            score=raw_scores[key],
            level=levels[key],
        ))

    # 存储到数据库
    db = get_db()
    result_id = _generate_id()
    try:
        _ensure_user(db, request.user_id)
        db.execute(
            """INSERT INTO constitution_results
               (id, user_id, answers, scores, primary_type, secondary_types, advice)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                result_id,
                request.user_id,
                str([a.model_dump() for a in request.answers]),
                str(raw_scores),
                primary,
                str(secondary),
                advice,
            )
        )
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"保存评估结果失败: {str(e)}")

    return SubmitResponse(
        result_id=result_id,
        user_id=request.user_id,
        primary_type=primary,
        primary_name=CONSTITUTION_TYPES[primary]["name"],
        secondary_types=[CONSTITUTION_TYPES[s]["name"] for s in secondary],
        scores=score_items,
        advice=advice,
    )


@router.get("/result/{user_id}", response_model=ResultResponse)
async def get_result(user_id: str):
    """获取用户最近一次体质评估结果"""
    db = get_db()
    row = db.execute(
        """SELECT id, user_id, version, primary_type, secondary_types, scores, advice, created_at
           FROM constitution_results
           WHERE user_id = ?
           ORDER BY created_at DESC
           LIMIT 1""",
        (user_id,)
    ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="未找到该用户的体质评估结果")

    return ResultResponse(
        result_id=row["id"],
        user_id=row["user_id"],
        version=row["version"],
        primary_type=row["primary_type"],
        primary_name=CONSTITUTION_TYPES[row["primary_type"]]["name"],
        secondary_types=eval(row["secondary_types"]),
        scores=eval(row["scores"]),
        advice=row["advice"],
        created_at=row["created_at"],
    )


@router.get("/types", response_model=List[ConstitutionTypeSummary])
async def get_constitution_types():
    """获取9种体质定义列表（从数据库读取）"""
    try:
        from app.db.database import Session
        db = Session()
        try:
            result = db.execute(text("""
                SELECT code, name_cn, name_en, description,
                       characteristics, diet_recommendations, lifestyle_advice
                FROM constitution_types ORDER BY id
            """))
            rows = result.fetchall()
            if rows:
                return [
                    ConstitutionTypeSummary(
                        type=r[0],
                        name=r[1],
                        name_en=r[2] or "",
                        description=r[3] or "",
                        characteristics=r[4] if isinstance(r[4], list) else (eval(r[4]) if r[4] else []),
                        diet_recommendations=r[5] if isinstance(r[5], list) else (eval(r[5]) if r[5] else []),
                        lifestyle_advice=r[6] if isinstance(r[6], list) else (eval(r[6]) if r[6] else []),
                    )
                    for r in rows
                ]
        finally:
            db.close()
    except Exception:
        pass

    # Fallback to in-memory data
    result = []
    for key in CONSTITUTION_KEYS:
        info = CONSTITUTION_TYPES[key]
        result.append(ConstitutionTypeSummary(
            type=key,
            name=info["name"],
            name_en=info["name_en"],
            description=info["description"],
        ))
    return result


@router.get("/types/{name}", response_model=ConstitutionTypeDetail)
async def get_constitution_detail(name: str):
    """获取单个体质详情（含饮食/茶饮/运动建议，从数据库读取）"""
    try:
        from app.db.database import Session
        db = Session()
        try:
            row = db.execute(text("""
                SELECT code, name_cn, name_en, description,
                       characteristics, diet_recommendations, lifestyle_advice,
                       exercise_recommendations, tea_recommendations,
                       diet_restrictions, common_diseases, seasonal_advice
                FROM constitution_types WHERE code = :name
            """), {"name": name}).fetchone()

            if row:
                def parse_json(val):
                    if val is None: return []
                    if isinstance(val, list): return val
                    try: return eval(val)
                    except: return []

                diet_advice = ""
                tea_advice = ""
                exercise_advice = ""
                avoid_list = []

                diet_recs = parse_json(row[5]) if row[5] else []
                lifestyle = parse_json(row[6]) if row[6] else []
                exercise = parse_json(row[7]) if row[7] else []
                tea = parse_json(row[8]) if row[8] else []
                restrictions = parse_json(row[9]) if row[9] else []

                return ConstitutionTypeDetail(
                    type=row[0],
                    name=row[1],
                    name_en=row[2] or "",
                    description=row[3] or "",
                    characteristics=parse_json(row[4]) if row[4] else [],
                    diet_advice="; ".join(diet_recs) if diet_recs else "",
                    tea_advice="; ".join(tea) if tea else "",
                    exercise_advice="; ".join(exercise) if exercise else "",
                    avoid_list=restrictions,
                    diet_recommendations=diet_recs,
                    lifestyle_advice=lifestyle,
                )
        finally:
            db.close()
    except Exception:
        pass

    # Fallback to in-memory data
    if name not in CONSTITUTION_TYPES:
        raise HTTPException(
            status_code=404,
            detail=f"未找到体质类型: {name}，可选: {', '.join(CONSTITUTION_KEYS)}"
        )

    info = CONSTITUTION_TYPES[name]
    return ConstitutionTypeDetail(
        type=name,
        name=info["name"],
        name_en=info["name_en"],
        description=info["description"],
        characteristics=info["characteristics"],
        diet_advice=info["diet_advice"],
        tea_advice=info["tea_advice"],
        exercise_advice=info["exercise_advice"],
        avoid_list=info["avoid_list"],
    )
