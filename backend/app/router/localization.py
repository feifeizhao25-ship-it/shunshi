"""
顺时国际版 — 多语言本地化引擎
支持 TCM 术语多语言词典、语言配置、日期格式本地化。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/localization", tags=["localization"])

# ─────────────────────────────────────────────────────────────────────────────
# TCM 术语多语言词典
# ─────────────────────────────────────────────────────────────────────────────

TCM_TERMS = {
    "qi": {
        "term_id": "qi",
        "chinese": "气",
        "pinyin": "qì",
        "english": "Qi (Vital Energy)",
        "japanese": "気",
        "korean": "기",
        "spanish": "Qi (Energía Vital)",
        "french": "Qi (Énergie Vitale)",
        "german": "Qi (Lebensenergie)",
        "definition_en": "The fundamental life force and energy that flows through the body according to TCM philosophy, essential for all bodily functions.",
        "cultural_context": "Core concept in Chinese medicine for over 2000 years, representing the animating force of life.",
        "common_misconception_en": "Qi is not a physical substance but a functional property of physiological processes.",
    },
    "yin_yang": {
        "term_id": "yin_yang",
        "chinese": "阴阳",
        "pinyin": "yīn yáng",
        "english": "Yin and Yang",
        "japanese": "陰陽",
        "korean": "음양",
        "spanish": "Yin y Yang",
        "french": "Yin et Yang",
        "german": "Yin und Yang",
        "definition_en": "The complementary and interconnected forces of TCM; Yin represents rest, coolness, and substance; Yang represents activity, warmth, and function.",
        "cultural_context": "Ancient Daoist philosophy principle adopted by TCM as fundamental framework for health and disease.",
        "common_misconception_en": "Yin and Yang are not absolute opposites but relative, interdependent, and constantly transforming.",
    },
    "constitution": {
        "term_id": "constitution",
        "chinese": "体质",
        "pinyin": "tǐ zhì",
        "english": "Constitution (Body Constitution Type)",
        "japanese": "体質",
        "korean": "체질",
        "spanish": "Constitución",
        "french": "Constitution",
        "german": "Konstitution",
        "definition_en": "An individual's inherent physical and physiological characteristics that determine predisposition to certain health patterns and diseases.",
        "cultural_context": "TCM recognizes 9 main constitution types (平和质, 气虚质, 阳虚质, 阴虚质, 痰湿质, 湿热质, 血瘀质, 气郁质, 特禀质).",
        "common_misconception_en": "Constitution is not fixed; it can be adjusted through appropriate lifestyle, diet, and treatment.",
    },
    "meridian": {
        "term_id": "meridian",
        "chinese": "经络",
        "pinyin": "jīng luò",
        "english": "Meridian (Channel)",
        "japanese": "経絡",
        "korean": "경락",
        "spanish": "Meridiano",
        "french": "Méridien",
        "german": "Meridian",
        "definition_en": "Pathways of Qi flow throughout the body connecting organs, tissues, and acupoints; fundamental to acupuncture and moxibustion therapy.",
        "cultural_context": "Mapped in great detail in classical texts like the Huangdi Neijing (Yellow Emperor's Classic of Internal Medicine).",
        "common_misconception_en": "Meridians are not actual anatomical structures visible by dissection, but functional energy pathways.",
    },
    "liver_qi": {
        "term_id": "liver_qi",
        "chinese": "肝气",
        "pinyin": "gān qì",
        "english": "Liver Qi",
        "japanese": "肝気",
        "korean": "간기",
        "spanish": "Qi del Hígado",
        "french": "Qi du Foie",
        "german": "Leber-Qi",
        "definition_en": "The functional activity of the Liver system in TCM, responsible for smooth flow of Qi and blood, emotional regulation, and menstrual function.",
        "cultural_context": "Dysfunction of Liver Qi is one of the most common patterns in modern TCM practice.",
        "common_misconception_en": "Liver Qi refers to the energetic function of the Liver system, not just the physical organ.",
    },
    "dampness": {
        "term_id": "dampness",
        "chinese": "湿气",
        "pinyin": "shī qì",
        "english": "Dampness (Moisture)",
        "japanese": "湿気",
        "korean": "습기",
        "spanish": "Humedad",
        "french": "Humidité",
        "german": "Feuchtigkeit",
        "definition_en": "An abnormal accumulation of body fluids and metabolic byproducts; a pathogenic factor that obstructs Qi flow and causes heaviness, sluggishness, and various health issues.",
        "cultural_context": "Dampness is identified as a major causative factor in modern lifestyle diseases including obesity, diabetes, and digestive disorders.",
        "common_misconception_en": "Dampness is not literal water but a pathological condition affecting digestion, metabolism, and fluid regulation.",
    },
    "qi_stagnation": {
        "term_id": "qi_stagnation",
        "chinese": "气滞",
        "pinyin": "qì zhì",
        "english": "Qi Stagnation",
        "japanese": "気滞",
        "korean": "기체",
        "spanish": "Estancamiento de Qi",
        "french": "Stagnation du Qi",
        "german": "Qi-Stagnation",
        "definition_en": "Impaired movement and circulation of Qi resulting in pain, emotional frustration, and structural blockages; often caused by stress and emotional constraint.",
        "cultural_context": "Recognized as a major pattern in stress-related disorders and chronic pain conditions in modern TCM.",
        "common_misconception_en": "Qi stagnation is not a permanent condition; it responds well to treatment and lifestyle modifications.",
    },
    "blood_stasis": {
        "term_id": "blood_stasis",
        "chinese": "血瘀",
        "pinyin": "xuè yū",
        "english": "Blood Stasis",
        "japanese": "血瘀",
        "korean": "혈어",
        "spanish": "Estancamiento de Sangre",
        "french": "Stase Sanguine",
        "german": "Blut-Stase",
        "definition_en": "Sluggish or stagnant blood circulation causing pain, dark complexion, and tissue damage; often accompanied by structural abnormalities.",
        "cultural_context": "Classical pattern that has gained recognition in modern TCM practice for chronic diseases and aging.",
        "common_misconception_en": "Blood stasis involves functional circulation problems, not necessarily structural vascular disease.",
    },
    "yin_deficiency": {
        "term_id": "yin_deficiency",
        "chinese": "阴虚",
        "pinyin": "yīn xū",
        "english": "Yin Deficiency",
        "japanese": "陰虚",
        "korean": "음허",
        "spanish": "Deficiencia de Yin",
        "french": "Déficience du Yin",
        "german": "Yin-Mangel",
        "definition_en": "Insufficient Yin (cooling, nourishing, substantive) resources causing heat symptoms, dryness, night sweats, and rapid aging signs.",
        "cultural_context": "Increasingly common in modern overworked populations; characterized by burnout and resource depletion.",
        "common_misconception_en": "Yin deficiency is not the same as specific nutritional deficiencies but a comprehensive systemic pattern.",
    },
    "yang_deficiency": {
        "term_id": "yang_deficiency",
        "chinese": "阳虚",
        "pinyin": "yáng xū",
        "english": "Yang Deficiency",
        "japanese": "陽虚",
        "korean": "양허",
        "spanish": "Deficiencia de Yang",
        "french": "Déficience du Yang",
        "german": "Yang-Mangel",
        "definition_en": "Insufficient Yang (warming, activating, functional) resources causing cold symptoms, lethargy, poor digestion, and metabolic slowdown.",
        "cultural_context": "Common in individuals with low metabolic rate, chronic illness, or insufficient physical activity.",
        "common_misconception_en": "Yang deficiency is not simple chilliness but a deep constitutional coldness affecting organ function.",
    },
    "spleen_qi": {
        "term_id": "spleen_qi",
        "chinese": "脾气",
        "pinyin": "píng qì",
        "english": "Spleen Qi",
        "japanese": "脾気",
        "korean": "비기",
        "spanish": "Qi del Bazo",
        "french": "Qi de la Rate",
        "german": "Milz-Qi",
        "definition_en": "The functional activity of the Spleen system in TCM, responsible for digestion, nutrient absorption, and transformation of food into usable energy.",
        "cultural_context": "The Spleen is called the 'root of acquired constitution' (后天之本) as it processes food throughout life.",
        "common_misconception_en": "TCM Spleen function encompasses much more than the anatomical spleen organ.",
    },
    "kidney_essence": {
        "term_id": "kidney_essence",
        "chinese": "肾精",
        "pinyin": "shèn jīng",
        "english": "Kidney Essence (Jing)",
        "japanese": "腎精",
        "korean": "신정",
        "spanish": "Esencia del Riñón",
        "french": "Essence du Rein",
        "german": "Nieren-Essenz",
        "definition_en": "The fundamental constitutional essence inherited from parents; represents growth, development, and reproductive potential; depleted through aging and stress.",
        "cultural_context": "Viewed as the deepest resource of the body; its preservation is the goal of Daoist longevity practices.",
        "common_misconception_en": "Kidney essence is not a specific substance but a metaphor for constitutional vitality and genetic potential.",
    },
    "heart_spirit": {
        "term_id": "heart_spirit",
        "chinese": "心神",
        "pinyin": "xīn shén",
        "english": "Heart Spirit (Shen)",
        "japanese": "心神",
        "korean": "심신",
        "spanish": "Espíritu del Corazón",
        "french": "Esprit du Cœur",
        "german": "Herz-Geist",
        "definition_en": "The consciousness, mental clarity, emotional stability, and presence of mind; housed in the Heart according to TCM; manifests in facial complexion and sleep quality.",
        "cultural_context": "The Shen is considered the most refined and spiritual aspect of human existence in Chinese philosophy.",
        "common_misconception_en": "The Heart Spirit is not supernatural but represents integrated neurological and emotional function.",
    },
    "phlegm_dampness": {
        "term_id": "phlegm_dampness",
        "chinese": "痰湿",
        "pinyin": "tán shī",
        "english": "Phlegm-Dampness",
        "japanese": "痰湿",
        "korean": "담습",
        "spanish": "Flema-Humedad",
        "french": "Phlegme-Humidité",
        "german": "Schleim-Nässe",
        "definition_en": "A pathogenic accumulation of thick, turbid fluids and metabolic waste; causes obesity, sluggishness, and blocks clear thinking; results from poor digestion and overnutrition.",
        "cultural_context": "The signature pattern of modern metabolic disease; recognized as a major threat to health in contemporary TCM.",
        "common_misconception_en": "Phlegm is not actual mucus but a functional metabolic congestion affecting circulation and clarity.",
    },
    "damp_heat": {
        "term_id": "damp_heat",
        "chinese": "湿热",
        "pinyin": "shī rè",
        "english": "Damp-Heat",
        "japanese": "湿熱",
        "korean": "습열",
        "spanish": "Humedad-Calor",
        "french": "Humidité-Chaleur",
        "german": "Nässe-Hitze",
        "definition_en": "A combination of pathogenic dampness and heat causing inflammation, skin problems, bitter taste, and sluggish digestion; worsens in humid climates.",
        "cultural_context": "Particularly prevalent in tropical and subtropical regions; increasingly common in modern populations due to processed foods.",
        "common_misconception_en": "Damp-heat is not infection but a pathological metabolic inflammatory state.",
    },
    "qi_and_blood_deficiency": {
        "term_id": "qi_and_blood_deficiency",
        "chinese": "气血虚",
        "pinyin": "qì xiě xū",
        "english": "Qi and Blood Deficiency",
        "japanese": "気血虚",
        "korean": "기혈허",
        "spanish": "Deficiencia de Qi y Sangre",
        "french": "Déficience du Qi et du Sang",
        "german": "Qi- und Blut-Mangel",
        "definition_en": "Simultaneous insufficiency of Qi (functional energy) and Blood (nourishing resources); causes fatigue, pallor, poor wound healing, and weak immunity.",
        "cultural_context": "Common in those with chronic illness, malnutrition, or overwork without adequate recovery.",
        "common_misconception_en": "Qi-blood deficiency is a functional depletion state, not identical to medical anemia or fatigue.",
    },
    "cold_pattern": {
        "term_id": "cold_pattern",
        "chinese": "寒证",
        "pinyin": "hán zhèng",
        "english": "Cold Pattern",
        "japanese": "寒証",
        "korean": "한증",
        "spanish": "Patrón de Frío",
        "french": "Syndrome de Froid",
        "german": "Kälte-Syndrom",
        "definition_en": "A pathological state caused by external or internal cold; manifests as aversion to cold, pale complexion, slow digestion, and clear watery excretions.",
        "cultural_context": "Recognized since ancient times; treatment emphasizes warming herbs and avoidance of cooling foods.",
        "common_misconception_en": "Cold patterns are not caused by ambient temperature alone but by weakness of warming function.",
    },
    "heat_pattern": {
        "term_id": "heat_pattern",
        "chinese": "热证",
        "pinyin": "rè zhèng",
        "english": "Heat Pattern",
        "japanese": "熱証",
        "korean": "열증",
        "spanish": "Patrón de Calor",
        "french": "Syndrome de Chaleur",
        "german": "Hitze-Syndrom",
        "definition_en": "A pathological state of excess heat; manifests as fever, thirst, red face, constipation, and yellow urine; results from infection, inflammation, or constitutional excess.",
        "cultural_context": "Treated with cooling herbs, bitter medicinals, and dietary modifications; prevention through moderation.",
        "common_misconception_en": "Heat patterns are not simple inflammation but complex metabolic and functional excess.",
    },
    "liver_depression": {
        "term_id": "liver_depression",
        "chinese": "肝郁",
        "pinyin": "gān yù",
        "english": "Liver Depression (Liver Qi Stagnation)",
        "japanese": "肝鬱",
        "korean": "간울",
        "spanish": "Depresión Hepática",
        "french": "Dépression Hépatique",
        "german": "Leber-Depression",
        "definition_en": "Stagnation of Liver Qi due to emotional constraint, frustration, or unresolved grievances; causes mood swings, PMS, digestive complaints, and tension.",
        "cultural_context": "The most common pattern in emotionally suppressed modern populations; central to understanding psychosomatic disease.",
        "common_misconception_en": "Liver depression is a functional stagnation pattern, not psychiatric depression, though they can coexist.",
    },
    "five_phases": {
        "term_id": "five_phases",
        "chinese": "五行",
        "pinyin": "wǔ xíng",
        "english": "Five Phases (Wu Xing)",
        "japanese": "五行",
        "korean": "오행",
        "spanish": "Cinco Fases (Wu Xing)",
        "french": "Cinq Phases (Wu Xing)",
        "german": "Fünf Wandlungsphasen (Wu Xing)",
        "definition_en": "A traditional Chinese classification framework using Wood, Fire, Earth, Metal, and Water to describe relationships and cycles.",
        "cultural_context": "The framework appears across classical Chinese philosophy, calendars, music, and traditional medicine.",
        "common_misconception_en": "The phases are historical conceptual categories, not chemical elements or independently verified anatomical mechanisms.",
    },
}

# Supported languages
SUPPORTED_LANGUAGES = {
    "zh-CN": {"name": "Simplified Chinese", "completion": 100},
    "zh-TW": {"name": "Traditional Chinese", "completion": 95},
    "en": {"name": "English", "completion": 100},
    "ja": {"name": "日本語 (Japanese)", "completion": 90},
    "ko": {"name": "한국어 (Korean)", "completion": 85},
    "es": {"name": "Español (Spanish)", "completion": 80},
    "fr": {"name": "Français (French)", "completion": 80},
    "de": {"name": "Deutsch (German)", "completion": 75},
    "th": {"name": "ไทย (Thai)", "completion": 30},
}

# Language-specific localization config
LOCALIZATION_CONFIG = {
    "zh-CN": {
        "lang_code": "zh-CN",
        "language_name": "简体中文",
        "date_format": "YYYY年MM月DD日",
        "time_format": "HH:mm",
        "measurement_system": "metric",
        "temperature_unit": "C",
        "week_start": "Monday",
        "decimal_separator": ".",
        "thousands_separator": ",",
    },
    "zh-TW": {
        "lang_code": "zh-TW",
        "language_name": "繁體中文",
        "date_format": "YYYY年MM月DD日",
        "time_format": "HH:mm",
        "measurement_system": "metric",
        "temperature_unit": "C",
        "week_start": "Monday",
        "decimal_separator": ".",
        "thousands_separator": ",",
    },
    "en": {
        "lang_code": "en",
        "language_name": "English",
        "date_format": "MM/DD/YYYY",
        "time_format": "HH:mm AM/PM",
        "measurement_system": "imperial",
        "temperature_unit": "F",
        "week_start": "Sunday",
        "decimal_separator": ".",
        "thousands_separator": ",",
    },
    "ja": {
        "lang_code": "ja",
        "language_name": "日本語",
        "date_format": "YYYY年MM月DD日",
        "time_format": "HH:mm",
        "measurement_system": "metric",
        "temperature_unit": "C",
        "week_start": "Monday",
        "decimal_separator": ".",
        "thousands_separator": ",",
    },
    "ko": {
        "lang_code": "ko",
        "language_name": "한국어",
        "date_format": "YYYY.MM.DD",
        "time_format": "HH:mm",
        "measurement_system": "metric",
        "temperature_unit": "C",
        "week_start": "Monday",
        "decimal_separator": ".",
        "thousands_separator": ",",
    },
    "es": {
        "lang_code": "es",
        "language_name": "Español",
        "date_format": "DD/MM/YYYY",
        "time_format": "HH:mm",
        "measurement_system": "metric",
        "temperature_unit": "C",
        "week_start": "Monday",
        "decimal_separator": ",",
        "thousands_separator": ".",
    },
    "fr": {
        "lang_code": "fr",
        "language_name": "Français",
        "date_format": "DD/MM/YYYY",
        "time_format": "HH:mm",
        "measurement_system": "metric",
        "temperature_unit": "C",
        "week_start": "Monday",
        "decimal_separator": ",",
        "thousands_separator": " ",
    },
    "de": {
        "lang_code": "de",
        "language_name": "Deutsch",
        "date_format": "DD.MM.YYYY",
        "time_format": "HH:mm",
        "measurement_system": "metric",
        "temperature_unit": "C",
        "week_start": "Monday",
        "decimal_separator": ",",
        "thousands_separator": ".",
    },
    "th": {
        "lang_code": "th",
        "language_name": "ไทย",
        "date_format": "DD/MM/YYYY",
        "time_format": "HH:mm",
        "measurement_system": "metric",
        "temperature_unit": "C",
        "week_start": "Monday",
        "decimal_separator": ".",
        "thousands_separator": ",",
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/terms", summary="TCM术语词典")
async def get_terms(
    lang: str = Query("en", description="语言代码：en, ja, ko, es, fr, de, zh-CN, zh-TW, th"),
    search: Optional[str] = Query(None, description="搜索术语（英文或中文）"),
):
    """返回 TCM 术语词典，支持多语言和搜索。"""
    results = []

    for term_id, term_data in TCM_TERMS.items():
        # 检查搜索条件
        if search:
            search_lower = search.lower()
            matches = (
                search_lower in term_data.get("english", "").lower()
                or search_lower in term_data.get("chinese", "").lower()
                or search_lower in term_data.get("pinyin", "").lower()
            )
            if not matches:
                continue

        lang_key_map = {
            "en": "english",
            "ja": "japanese",
            "ko": "korean",
            "es": "spanish",
            "fr": "french",
            "de": "german",
            "zh-CN": "chinese",
            "zh-TW": "chinese",
            "th": "english",
        }

        target_lang_key = lang_key_map.get(lang, "english")

        results.append({
            "term_id": term_data["term_id"],
            "chinese": term_data["chinese"],
            "pinyin": term_data["pinyin"],
            "translation": term_data.get(target_lang_key, term_data["english"]),
            "definition_en": term_data["definition_en"],
        })

    return {
        "success": True,
        "data": {
            "language": lang,
            "total": len(results),
            "terms": results,
        },
    }


@router.get("/terms/{term_id}", summary="术语完整详情")
async def get_term_detail(term_id: str):
    """返回某个术语的完整多语言详情。"""
    if term_id not in TCM_TERMS:
        raise HTTPException(status_code=404, detail="术语不存在")

    term = TCM_TERMS[term_id]
    return {
        "success": True,
        "data": term,
    }


@router.get("/languages", summary="支持的语言列表")
async def get_languages():
    """返回所有支持的语言及完成度。"""
    languages = []
    for lang_code, info in SUPPORTED_LANGUAGES.items():
        languages.append({
            "lang_code": lang_code,
            "name": info["name"],
            "completion_percentage": info["completion"],
        })

    return {
        "success": True,
        "data": {
            "total_languages": len(languages),
            "languages": languages,
        },
    }


@router.get("/translate", summary="术语翻译")
async def translate_term(
    term: str = Query(..., description="术语名称或ID"),
    to: str = Query(..., description="目标语言代码"),
):
    """简单的术语翻译端点。"""
    # 先尝试通过 term_id 查找
    found_term = None
    for term_id, term_data in TCM_TERMS.items():
        if term_id == term.lower() or term_data.get("english", "").lower() == term.lower():
            found_term = term_data
            break

    if not found_term:
        raise HTTPException(status_code=404, detail="术语未找到")

    lang_key_map = {
        "en": "english",
        "ja": "japanese",
        "ko": "korean",
        "es": "spanish",
        "fr": "french",
        "de": "german",
        "zh-CN": "chinese",
        "zh-TW": "chinese",
        "th": "english",
    }

    if to not in lang_key_map:
        raise HTTPException(status_code=400, detail="不支持的目标语言")

    target_key = lang_key_map[to]
    translation = found_term.get(target_key, "Translation unavailable")

    return {
        "success": True,
        "data": {
            "term": found_term["english"],
            "chinese": found_term["chinese"],
            "source_lang": "en",
            "target_lang": to,
            "translation": translation,
        },
    }


@router.post("/format-date", summary="日期格式化")
async def format_date(request_body: dict):
    """按指定语言格式化日期。"""
    date_str = request_body.get("date")
    lang_code = request_body.get("lang", "en")

    if not date_str:
        raise HTTPException(status_code=400, detail="日期参数缺失")

    if lang_code not in LOCALIZATION_CONFIG:
        raise HTTPException(status_code=404, detail="语言不支持")

    try:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="日期格式无效，应为 YYYY-MM-DD")

    config = LOCALIZATION_CONFIG[lang_code]

    # 简化格式化（实际应用应使用 babel 或 dateutil）
    format_template = config["date_format"]
    formatted = format_template.replace("YYYY", str(date_obj.year))
    formatted = formatted.replace("MM", f"{date_obj.month:02d}")
    formatted = formatted.replace("DD", f"{date_obj.day:02d}")

    return {
        "success": True,
        "data": {
            "original_date": date_str,
            "language": lang_code,
            "formatted_date": formatted,
            "date_format_template": format_template,
        },
    }


@router.get("/config/{lang_code}", summary="语言本地化配置")
async def get_localization_config(lang_code: str):
    """返回某语言的完整本地化配置。"""
    if lang_code not in LOCALIZATION_CONFIG:
        raise HTTPException(status_code=404, detail="语言不支持")

    config = LOCALIZATION_CONFIG[lang_code]
    return {
        "success": True,
        "data": config,
    }
