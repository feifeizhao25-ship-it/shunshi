"""
体质分析模块
根据问卷答案分析九种体质类型，结合知识库给出个性化建议
"""
from typing import Optional
from .retriever import retrieve


# 九种体质定义（精简版）
CONSTITUTION_TYPES = {
    "pinghe": {"cn": "平和质", "gl": "Balanced Constitution"},
    "qixu": {"cn": "气虚质", "gl": "Qi Deficiency"},
    "yangxu": {"cn": "阳虚质", "gl": "Yang Deficiency"},
    "yinxu": {"cn": "阴虚质", "gl": "Yin Deficiency"},
    "tanshi": {"cn": "痰湿质", "gl": "Phlegm-Dampness"},
    "shire": {"cn": "湿热质", "gl": "Damp-Heat"},
    "xueyu": {"cn": "血瘀质", "gl": "Blood Stasis"},
    "qiyu": {"cn": "气郁质", "gl": "Qi Stagnation"},
    "tebing": {"cn": "特禀质", "gl": "Special Constitution"},
}

# 每道题对应的体质维度
# answers[i] = 该题答案（0-4: 从没有/很少 → 总是/非常）
# 前5题 → 平和, 6-10 → 气虚, 11-15 → 阳虚, etc.
_QUESTION_DIMENSIONS = {
    # (start_idx, end_idx): constitution_key
    (0, 4): "pinghe",
    (5, 9): "qixu",
    (10, 14): "yangxu",
    (15, 19): "yinxu",
    (20, 24): "tanshi",
    (25, 29): "shire",
    (30, 34): "xueyu",
    (35, 39): "qiyu",
    (40, 44): "tebing",
}


def analyze_constitution(answers: list[int], lang: str = "cn") -> dict:
    """
    分析体质测试答案，返回体质类型和建议

    Args:
        answers: 答案列表，每项 0-4
        lang: 语言 "cn" | "gl"

    Returns:
        {
            constitution_type: str,
            constitution_key: str,
            scores: {constitution_key: score},
            description: str,
            recommendations: dict
        }
    """
    # 计算各维度分数
    scores = {}
    for (start, end), key in _QUESTION_DIMENSIONS.items():
        if end < len(answers):
            dimension_answers = answers[start:end + 1]
            scores[key] = sum(dimension_answers) / len(dimension_answers)
        else:
            scores[key] = 0.0

    # 找到最高分（排除平和质 → 如果平和质最高，再看其他维度是否也高）
    primary = max(scores, key=lambda k: scores[k])

    # 如果平和质不是最高，或非平和质分数也很高，说明是偏颇体质
    if primary != "pinghe" and scores[primary] > 1.0:
        constitution_key = primary
    elif scores["pinghe"] >= 2.5:
        constitution_key = "pinghe"
    else:
        # 找次高的偏颇体质
        sorted_types = sorted(
            [(k, v) for k, v in scores.items() if k != "pinghe"],
            key=lambda x: x[1], reverse=True
        )
        constitution_key = sorted_types[0][0] if sorted_types and sorted_types[0][1] > 0.5 else "pinghe"

    const_info = CONSTITUTION_TYPES.get(constitution_key, {"cn": "未知", "gl": "Unknown"})
    const_name = const_info["cn"] if lang == "cn" else const_info["gl"]

    # 从知识库检索相关建议
    if lang == "cn":
        query = f"{const_name}体质调养方法"
    else:
        query = f"{const_name} constitution wellness advice"

    chunks = retrieve(query, lang=lang, top_k=3)

    # 格式化描述
    description = _get_constitution_description(constitution_key, lang)

    # 构建推荐
    recommendations = {
        "diet": "",
        "exercise": "",
        "tea": "",
        "lifestyle": "",
        "knowledge_chunks": [
            {
                "content": c["content"][:300],
                "heading": c["heading_path"][-1] if c["heading_path"] else "",
                "score": c["score"],
            }
            for c in chunks
        ],
    }

    # 从检索到的 chunks 中提取分类建议
    for chunk in chunks:
        content = chunk["content"]
        heading = " ".join(chunk["heading_path"])
        if lang == "cn":
            if "饮食" in heading or "宜食" in content or "食谱" in content:
                recommendations["diet"] += content[:200] + "\n"
            if "运动" in heading or "锻炼" in content:
                recommendations["exercise"] += content[:200] + "\n"
            if "茶" in heading or "茶饮" in content:
                recommendations["tea"] += content[:200] + "\n"
            if "起居" in heading or "作息" in content or "睡眠" in content:
                recommendations["lifestyle"] += content[:200] + "\n"
        else:
            if "Nutrition" in heading or "food" in content.lower() or "meal" in content.lower():
                recommendations["diet"] += content[:200] + "\n"
            if "Movement" in heading or "exercise" in content.lower():
                recommendations["exercise"] += content[:200] + "\n"
            if "Tea" in heading or "tea" in content.lower():
                recommendations["tea"] += content[:200] + "\n"
            if "Sleep" in heading or "Rest" in heading or "sleep" in content.lower():
                recommendations["lifestyle"] += content[:200] + "\n"

    # 清理空值（仅清理字符串值）
    cleaned = {}
    for k, v in recommendations.items():
        if isinstance(v, str):
            cleaned[k] = v.strip() if v.strip() else ""
        else:
            cleaned[k] = v
    recommendations = cleaned

    return {
        "constitution_type": const_name,
        "constitution_key": constitution_key,
        "scores": {k: round(v, 2) for k, v in scores.items()},
        "description": description,
        "recommendations": recommendations,
    }


def _get_constitution_description(key: str, lang: str) -> str:
    """获取体质描述"""
    descriptions = {
        "pinghe": {
            "cn": "阴阳气血调和，体态适中，面色润泽，精力充沛，睡眠良好。是最理想的体质状态，患病较少。",
            "gl": "Balanced constitution with harmonized yin-yang and qi-blood. Good energy, healthy complexion, restful sleep. The ideal constitution type with low disease risk.",
        },
        "qixu": {
            "cn": "元气不足，容易疲乏，气短懒言，容易出汗，容易感冒。声音低弱，易精神不振。需要益气健脾。",
            "gl": "Qi deficiency: easily fatigued, shortness of breath, excessive sweating, prone to colds. Needs qi-tonifying and spleen-strengthening care.",
        },
        "yangxu": {
            "cn": "阳气不足，手脚发凉，畏寒怕冷，精神不振。喜热饮食，吃凉的东西容易腹泻。需要温阳散寒。",
            "gl": "Yang deficiency: cold hands and feet, intolerance to cold, low energy. Prefers warm foods and drinks. Needs warming and yang-nourishing care.",
        },
        "yinxu": {
            "cn": "体内阴液亏少，口燥咽干，手足心热，容易盗汗。体形多瘦长，性情急躁。需要滋阴降火。",
            "gl": "Yin deficiency: dry mouth and throat, warm palms and soles, night sweats. Often lean build with restless temperament. Needs yin-nourishing care.",
        },
        "tanshi": {
            "cn": "痰湿凝聚，体形肥胖，腹部肥满松软，面部油脂较多。口黏腻，身重不爽。需要健脾祛湿。",
            "gl": "Phlegm-dampness: tendency toward weight gain, especially abdominal, oily skin, feeling of heaviness. Needs spleen-strengthening and dampness-draining care.",
        },
        "shire": {
            "cn": "湿热内蕴，面部和鼻尖容易出油，容易长痤疮。口苦口干，身重困倦。大便黏滞。需要清热利湿。",
            "gl": "Damp-heat: oily skin prone to acne, bitter taste in mouth, feeling of heaviness. Needs heat-clearing and dampness-draining care.",
        },
        "xueyu": {
            "cn": "血行不畅，肤色晦暗，容易出现色素沉着。口唇颜色偏暗，容易出现瘀斑。需要活血化瘀。",
            "gl": "Blood stasis: dull complexion, tendency toward pigmentation, dark lips. Needs blood-invigorating and stasis-resolving care.",
        },
        "qiyu": {
            "cn": "气机郁滞，神情抑郁，情感脆弱。烦闷不乐，多愁善感。胸胁胀满。需要疏肝理气。",
            "gl": "Qi stagnation: tendency toward melancholy, emotionally sensitive, frequent sighing, chest tightness. Needs liver-soothing and qi-regulating care.",
        },
        "tebing": {
            "cn": "先天禀赋不足或过敏体质，容易对花粉、药物、食物等过敏。体质特殊，对外界刺激敏感。需要益气固表。",
            "gl": "Special constitution: innate sensitivity or allergic tendencies to pollen, medication, or certain foods. Needs immune-strengthening and protective care.",
        },
    }
    return descriptions.get(key, {}).get(lang, "")
