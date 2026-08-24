"""
顺时国际版 — 中西医概念融合桥接引擎
帮助西方用户理解 TCM 概念，连接中医和现代医学/功能医学框架。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional

router = APIRouter(prefix="/api/v1/bridge", tags=["western_wellness_bridge"])

# ─────────────────────────────────────────────────────────────────────────────
# 中西医概念桥接
# ─────────────────────────────────────────────────────────────────────────────

CONCEPT_BRIDGES = {
    "liver_qi_stagnation": {
        "concept_id": "liver_qi_stagnation",
        "tcm_concept": "肝气郁结",
        "tcm_description_cn": "肝气运行不利，情志受阻，导致气机郁滞。",
        "western_equivalent": [
            "Stress-related hepatic tension",
            "Emotional stress affecting digestion",
            "Functional dyspepsia",
            "Irritable bowel syndrome (IBS-like)",
        ],
        "western_explanation": "Stagnation of liver function due to emotional stress, manifesting as digestive complaints, mood swings, and tension.",
        "functional_medicine_parallel": "Dysregulated HPA axis (hypothalamic-pituitary-adrenal) affecting digestive secretion and autonomic function.",
        "dietary_connection": "Avoid: alcohol, fatty/greasy foods, caffeine. Include: bitter greens, fermented foods, citrus.",
        "research_note": "Studies show stress-induced changes in bile secretion and intestinal motility align with Liver Qi stagnation patterns.",
        "symptom_overlap": ["mood_swings", "PMS", "bloating", "indigestion", "tension_headaches", "sighing"],
    },
    "damp_heat_constitution": {
        "concept_id": "damp_heat_constitution",
        "tcm_concept": "湿热体质",
        "tcm_description_cn": "湿热蕴结体内，导致炎症倾向、肥胖、皮肤问题。",
        "western_equivalent": [
            "Inflammatory constitution",
            "Pro-inflammatory state",
            "Metabolic syndrome",
            "Insulin resistance",
        ],
        "western_explanation": "A state of chronic low-grade inflammation with impaired glucose metabolism and metabolic dysfunction.",
        "functional_medicine_parallel": "Elevated inflammatory markers (CRP, IL-6); dysbiotic microbiome; intestinal permeability.",
        "dietary_connection": "Avoid: processed foods, sugar, alcohol, heavy oils. Include: anti-inflammatory foods (turmeric, ginger, leafy greens).",
        "research_note": "Damp-heat patterns show correlation with elevated TNF-alpha and IL-1 beta; similar to metabolic endotoxemia.",
        "symptom_overlap": ["acne", "eczema", "body_odor", "sluggishness", "weight_gain", "poor_digestion"],
    },
    "qi_deficiency": {
        "concept_id": "qi_deficiency",
        "tcm_concept": "气虚",
        "tcm_description_cn": "正气不足，脏腑功能减退，精力不足。",
        "western_equivalent": [
            "Low vital energy",
            "Fatigue syndrome",
            "Adrenal fatigue",
            "Chronic fatigue syndrome (CFS)",
        ],
        "western_explanation": "Functional energy depletion affecting metabolic rate, immune function, and cellular regeneration.",
        "functional_medicine_parallel": "Mitochondrial dysfunction; low NAD+ and ATP production; impaired stress response.",
        "dietary_connection": "Include: ginseng, astragalus, nutrient-dense soups, whole grains. Avoid: extreme exercise, overwork.",
        "research_note": "Qi-deficient patients show lower VO2 max and reduced mitochondrial enzyme activity.",
        "symptom_overlap": ["persistent_fatigue", "weak_immunity", "shortness_of_breath", "poor_appetite", "loose_stools"],
    },
    "yin_deficiency": {
        "concept_id": "yin_deficiency",
        "tcm_concept": "阴虚",
        "tcm_description_cn": "阴液不足，虚热内生，身体失去滋润。",
        "western_equivalent": [
            "Dehydration tendency",
            "Yin deficiency",
            "Parasympathetic underactivity",
            "Hypermetabolic state",
        ],
        "western_explanation": "Insufficient nourishing resources with relative excess heat; chronic dehydration at cellular level.",
        "functional_medicine_parallel": "Elevated cortisol; sympathetic dominance; impaired parasympathetic recovery; cellular dehydration.",
        "dietary_connection": "Include: bone broth, sesame, lily bulb, moistening foods. Avoid: spicy, fried, alcohol, excessive heat.",
        "research_note": "Yin-deficiency patterns show high melatonin-to-cortisol ratios and reduced HRV.",
        "symptom_overlap": ["night_sweats", "dry_mouth", "insomnia", "hot_flashes", "rapid_aging"],
    },
    "yang_deficiency": {
        "concept_id": "yang_deficiency",
        "tcm_concept": "阳虚",
        "tcm_description_cn": "阳气衰微，温阳功能减退，代谢缓慢。",
        "western_equivalent": [
            "Hypothyroid-like pattern",
            "Cold constitution",
            "Low metabolic rate",
            "Metabolic underactivity",
        ],
        "western_explanation": "Insufficient warming and activating function; slow metabolism and poor heat generation.",
        "functional_medicine_parallel": "Low thyroid function; reduced thermogenesis; mitochondrial downregulation; poor glucose utilization.",
        "dietary_connection": "Include: warming herbs (cinnamon, ginger), warming proteins, bone broth. Avoid: cold foods, iced drinks.",
        "research_note": "Yang-deficient patients show lower body temperature, reduced T3 levels, and impaired thermogenic response.",
        "symptom_overlap": ["cold_intolerance", "poor_digestion", "low_energy", "pale_complexion", "slow_metabolism"],
    },
    "blood_stasis": {
        "concept_id": "blood_stasis",
        "tcm_concept": "血瘀",
        "tcm_description_cn": "血液运行不畅，微循环障碍，易痛易瘀。",
        "western_equivalent": [
            "Poor microcirculation",
            "Hypercoagulable tendency",
            "Endothelial dysfunction",
            "Microvascular disease",
        ],
        "western_explanation": "Sluggish blood flow and impaired microcirculation; tendency toward clotting and inflammation.",
        "functional_medicine_parallel": "Elevated fibrinogen, von Willebrand factor; endothelial dysfunction; thrombotic tendency.",
        "dietary_connection": "Include: turmeric, ginger, dark leafy greens, fish oils. Avoid: cold foods, saturated fats.",
        "research_note": "Blood stasis patterns show elevated D-dimer and impaired fibrinolysis; improved with anticoagulant herbs.",
        "symptom_overlap": ["chronic_pain", "dark_complexion", "enlarged_veins", "purple_tongue", "amenorrhea"],
    },
    "phlegm_dampness": {
        "concept_id": "phlegm_dampness",
        "tcm_concept": "痰湿",
        "tcm_description_cn": "脾失健运，湿聚成痰，代谢障碍。",
        "western_equivalent": [
            "Metabolic syndrome tendency",
            "Phlegm-dampness",
            "Obesity with sluggishness",
            "Impaired lipid metabolism",
        ],
        "western_explanation": "Metabolic congestion with accumulation of body fluids and lipids; sluggish digestion and weight gain.",
        "functional_medicine_parallel": "Dysbiotic microbiome; impaired digestion; elevated triglycerides; reduced glucose sensitivity.",
        "dietary_connection": "Avoid: dairy, sugar, processed foods. Include: ginger, green tea, coix seeds, light foods.",
        "research_note": "Phlegm-dampness shows altered Firmicutes/Bacteroidetes ratio; responds to diet modification.",
        "symptom_overlap": ["obesity", "fatigue", "brain_fog", "sluggish_digestion", "dizziness"],
    },
    "heart_spirit_unease": {
        "concept_id": "heart_spirit_unease",
        "tcm_concept": "心神不安",
        "tcm_description_cn": "心神失守，精神不宁，入睡困难。",
        "western_equivalent": [
            "Sleep-onset insomnia",
            "Anxiety disorder (mild)",
            "Racing thoughts",
            "Autonomic dysregulation",
        ],
        "western_explanation": "Inability to transition into parasympathetic state at night; hypervigilance and mental racing.",
        "functional_medicine_parallel": "Elevated nighttime cortisol; poor HRV; sympathetic dominance; low GABA/glutamate ratio.",
        "dietary_connection": "Include: passionflower, lavender tea, magnesium-rich foods, L-theanine. Avoid: caffeine, stimulants.",
        "research_note": "Spirit unease correlates with elevated salivary cortisol at bedtime and reduced heart rate variability.",
        "symptom_overlap": ["insomnia", "anxiety", "palpitations", "restlessness", "poor_concentration"],
    },
    "kidney_essence_depletion": {
        "concept_id": "kidney_essence_depletion",
        "tcm_concept": "肾精不足",
        "tcm_description_cn": "先天禀赋不足或后天消耗过度，导致衰老加速。",
        "western_equivalent": [
            "Aging acceleration",
            "Hormonal decline",
            "Telomere shortening",
            "Mitochondrial aging",
        ],
        "western_explanation": "Depletion of constitutional reserves; accelerated aging and decline in all organ systems.",
        "functional_medicine_parallel": "Shortened telomeres; elevated senescent cells; hormonal decline (sex steroids, growth hormone).",
        "dietary_connection": "Include: sesame, walnuts, bone marrow, high-quality protein. Avoid: overwork, excessive heat.",
        "research_note": "Kidney essence depletion shows correlation with telomerase activity and biological age markers.",
        "symptom_overlap": ["premature_aging", "low_libido", "poor_bone_health", "hearing_loss", "weak_lower_back"],
    },
    "spleen_qi_deficiency": {
        "concept_id": "spleen_qi_deficiency",
        "tcm_concept": "脾虚",
        "tcm_description_cn": "脾失健运，消化吸收能力下降，营养不良。",
        "western_equivalent": [
            "Poor digestive enzyme production",
            "Leaky gut tendency",
            "Intestinal permeability",
            "Malabsorption syndrome",
        ],
        "western_explanation": "Impaired digestive secretion and intestinal barrier integrity; nutrient malabsorption.",
        "functional_medicine_parallel": "Reduced pancreatic enzyme output; increased zonulin; dysbiotic microbiome; bacterial overgrowth.",
        "dietary_connection": "Include: warming soups, easily digestible foods, digestive enzymes. Avoid: cold raw foods, excessive sugar.",
        "research_note": "Spleen deficiency correlates with reduced pancreatic amylase and impaired tight junction protein expression.",
        "symptom_overlap": ["bloating", "loose_stools", "poor_appetite", "fatigue", "nutrient_deficiencies"],
    },
    "liver_blood_deficiency": {
        "concept_id": "liver_blood_deficiency",
        "tcm_concept": "肝血不足",
        "tcm_description_cn": "血液生成或储存不足，目光晦暗，筋脉失养。",
        "western_equivalent": [
            "Anemia or pre-anemia state",
            "Iron deficiency",
            "Nutritional deficiency",
            "Vision problems",
        ],
        "western_explanation": "Insufficient nourishing substances (Iron, B12, folate) affecting blood production and tissue health.",
        "functional_medicine_parallel": "Iron deficiency; B12/folate malabsorption; reduced hemoglobin; impaired methylation.",
        "dietary_connection": "Include: liver, dark leafy greens, red dates, bone broth. Include iron-rich foods and B vitamins.",
        "research_note": "Liver blood deficiency shows strong correlation with iron status and folate metabolism.",
        "symptom_overlap": ["pale_complexion", "dry_eyes", "menstrual_irregularity", "poor_nails", "dizziness"],
    },
    "lung_qi_deficiency": {
        "concept_id": "lung_qi_deficiency",
        "tcm_concept": "肺气虚",
        "tcm_description_cn": "肺失宣降，卫气不足，易感冒，皮肤无光泽。",
        "western_equivalent": [
            "Weak respiratory function",
            "Poor immunity",
            "Impaired skin barrier",
            "Frequent infections",
        ],
        "western_explanation": "Impaired respiratory and immune function; weakened mucosal immunity.",
        "functional_medicine_parallel": "Low IgA levels; reduced Th17 responses; compromised skin barrier; dysbiosis.",
        "dietary_connection": "Include: mushrooms, white foods (pear, lily bulb), protein. Avoid: dairy, sugar that increase phlegm.",
        "research_note": "Lung Qi deficiency shows reduced respiratory epithelial tight junctions and IgA production.",
        "symptom_overlap": ["shortness_of_breath", "weak_voice", "frequent_colds", "pale_skin", "weak_immunity"],
    },
    "kidney_yang_not_warming_spleen": {
        "concept_id": "kidney_yang_not_warming_spleen",
        "tcm_concept": "肾阳不足，温阳脾阳",
        "tcm_description_cn": "肾阳虚弱，脾阳亦虚，导致代谢严重减退。",
        "western_equivalent": [
            "Severe metabolic slowdown",
            "Hypothyroidism-like state",
            "Cold extremities syndrome",
            "Severe digestive impairment",
        ],
        "western_explanation": "Combined functional hypothyroidism with severe digestive weakness; very low metabolic rate.",
        "functional_medicine_parallel": "Low free T3; reduced TSH responsiveness; severe digestive dyskinesia; autonomic dysfunction.",
        "dietary_connection": "Include: warming foods, ginger, cinnamon, warming proteins. Strict avoidance of cold.",
        "research_note": "This combined pattern shows both low T3 and reduced gastric motility; requires integrated warming approach.",
        "symptom_overlap": ["severe_cold_intolerance", "weight_gain", "bloating", "sluggish_digestion", "lower_back_pain"],
    },
    "gallbladder_deficiency": {
        "concept_id": "gallbladder_deficiency",
        "tcm_concept": "胆气虚",
        "tcm_description_cn": "胆功能减退，决断力弱，胆囊郁滞。",
        "western_equivalent": [
            "Biliary dysfunction",
            "Gallbladder dysmotility",
            "Impaired bile secretion",
            "Loss of decisive function",
        ],
        "western_explanation": "Impaired bile secretion and gallbladder contractility; affecting fat digestion and decisive cognition.",
        "functional_medicine_parallel": "Reduced cholecystokinin sensitivity; impaired gallbladder contractility; altered bile acid metabolism.",
        "dietary_connection": "Include: bitter foods, moderate healthy fats. Avoid: heavy oils, stress during meals.",
        "research_note": "Gallbladder deficiency correlates with reduced CCK response and prolonged gallbladder emptying time.",
        "symptom_overlap": ["indecisiveness", "digestive_distress_with_fats", "tinnitus", "bitter_taste", "sighing"],
    },
    "triple_burner_dysfunction": {
        "concept_id": "triple_burner_dysfunction",
        "tcm_concept": "三焦不通",
        "tcm_description_cn": "三焦气机不利，水液代谢障碍，腹胀浮肿。",
        "western_equivalent": [
            "Lymphatic congestion",
            "Impaired fluid transport",
            "Autonomic dysregulation",
            "Edema and bloating",
        ],
        "western_explanation": "Dysfunction of autonomic-mediated fluid distribution and transport; water retention.",
        "functional_medicine_parallel": "Impaired lymphatic drainage; elevated aldosterone; autonomic imbalance affecting vasomotor function.",
        "dietary_connection": "Include: warming diuretics (corn silk tea), ginger, light foods. Avoid: salty, cold, raw.",
        "research_note": "Triple burner dysfunction shows correlation with altered aquaporin expression and lymphatic flow.",
        "symptom_overlap": ["bloating", "edema", "brain_fog", "sluggish_bowels", "poor_circulation"],
    },
    "heart_kidney_discord": {
        "concept_id": "heart_kidney_discord",
        "tcm_concept": "心肾不交",
        "tcm_description_cn": "心火不降，肾水不升，水火失济，失眠多梦。",
        "western_equivalent": [
            "Dysregulated sleep-wake cycle",
            "Central sensitization",
            "Circadian rhythm disorder",
            "Chronic insomnia",
        ],
        "western_explanation": "Disrupted circadian rhythm with sympathetic dominance; failure to transition into sleep parasympathetic state.",
        "functional_medicine_parallel": "Melatonin/cortisol dysrhythmia; elevated nighttime norepinephrine; altered GABA/glutamate balance.",
        "dietary_connection": "Include: bone broth, sesame, lily bulb at dinner. Avoid: caffeine, stimulating foods after 2pm.",
        "research_note": "Heart-kidney discord shows characteristic melatonin peak timing delays and elevated nocturnal sympathetic tone.",
        "symptom_overlap": ["severe_insomnia", "vivid_nightmares", "dry_mouth", "palpitations", "anxiety"],
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/concepts", summary="所有桥接概念")
async def get_concepts():
    """返回所有中西医桥接概念的列表。"""
    concepts = []
    for concept_id, concept_data in CONCEPT_BRIDGES.items():
        concepts.append({
            "concept_id": concept_data["concept_id"],
            "tcm_concept": concept_data["tcm_concept"],
            "western_equivalent": concept_data["western_equivalent"],
        })

    return {
        "success": True,
        "data": {
            "total_concepts": len(concepts),
            "concepts": concepts,
        },
    }


@router.get("/concepts/{concept_id}", summary="概念详细信息")
async def get_concept_detail(concept_id: str):
    """返回某个桥接概念的详细信息。"""
    if concept_id not in CONCEPT_BRIDGES:
        raise HTTPException(status_code=404, detail="概念不存在")

    concept = CONCEPT_BRIDGES[concept_id]
    return {
        "success": True,
        "data": concept,
    }


@router.get("/search", summary="症状搜索")
async def search_by_symptom(symptom: str = Query(..., description="西方症状或关键词")):
    """根据西方症状搜索对应的 TCM 概念。"""
    symptom_lower = symptom.lower()
    results = []

    for concept_id, concept_data in CONCEPT_BRIDGES.items():
        # 搜索症状重叠列表
        symptoms = concept_data.get("symptom_overlap", [])
        if any(symptom_lower in str(s).lower() for s in symptoms):
            results.append({
                "concept_id": concept_data["concept_id"],
                "tcm_concept": concept_data["tcm_concept"],
                "western_explanation": concept_data["western_explanation"],
                "matching_symptoms": [s for s in symptoms if symptom_lower in str(s).lower()],
            })

        # 也搜索西方等价物描述
        if symptom_lower in concept_data.get("western_explanation", "").lower():
            if not any(r["concept_id"] == concept_id for r in results):
                results.append({
                    "concept_id": concept_data["concept_id"],
                    "tcm_concept": concept_data["tcm_concept"],
                    "western_explanation": concept_data["western_explanation"],
                })

    if not results:
        return {
            "success": True,
            "data": {
                "symptom": symptom,
                "found": False,
                "concepts": [],
                "message": "No matching TCM concepts found for this symptom.",
            },
        }

    return {
        "success": True,
        "data": {
            "symptom": symptom,
            "found": True,
            "total_matches": len(results),
            "concepts": results,
        },
    }


@router.get("/constitution", summary="体质查询")
@router.get("/constitution/{western_description}", summary="体质查询（旧路径兼容）")
async def find_constitution_by_western(
    western_description: Optional[str] = None,
    q: Optional[str] = Query(None, description="西方体质或症状描述"),
):
    """用西方描述查找对应的 TCM 体质概念。"""
    q = (q or western_description or "").strip()
    if not q:
        raise HTTPException(status_code=422, detail="请提供查询描述")
    q_lower = q.lower()
    results = []

    for concept_id, concept_data in CONCEPT_BRIDGES.items():
        # 搜索西方等价物
        western_equiv = concept_data.get("western_equivalent", [])
        if any(q_lower in str(w).lower() for w in western_equiv):
            results.append({
                "concept_id": concept_data["concept_id"],
                "tcm_concept": concept_data["tcm_concept"],
                "western_equivalent": concept_data["western_equivalent"],
                "functional_medicine_parallel": concept_data["functional_medicine_parallel"],
            })

    if not results:
        return {
            "success": True,
            "data": {
                "query": q,
                "found": False,
                "constitutions": [],
                "message": "No matching constitutions found.",
            },
        }

    return {
        "success": True,
        "data": {
            "query": q,
            "found": True,
            "total_matches": len(results),
            "constitutions": results,
        },
    }


@router.get("/explain/{tcm_term}", summary="TCM术语解释")
async def explain_tcm_to_western(tcm_term: str):
    """对西方用户详细解释一个 TCM 术语。"""
    # 尝试匹配 concept_id 或 tcm_concept
    found_concept = None
    for concept_id, concept_data in CONCEPT_BRIDGES.items():
        if (concept_id.lower() == tcm_term.lower() or
            concept_data["tcm_concept"].lower() == tcm_term.lower()):
            found_concept = concept_data
            break

    if not found_concept:
        raise HTTPException(status_code=404, detail="TCM概念未找到")

    return {
        "success": True,
        "data": {
            "tcm_concept": found_concept["tcm_concept"],
            "tcm_description_cn": found_concept["tcm_description_cn"],
            "western_explanation": found_concept["western_explanation"],
            "western_equivalent": found_concept["western_equivalent"],
            "functional_medicine_parallel": found_concept["functional_medicine_parallel"],
            "research_note": found_concept["research_note"],
            "symptom_overlap": found_concept["symptom_overlap"],
        },
    }


@router.get("/diet-science/{concept_id}", summary="饮食科学")
async def get_diet_science(concept_id: str):
    """返回该 TCM 概念的现代营养学对应食物和原理。"""
    if concept_id not in CONCEPT_BRIDGES:
        raise HTTPException(status_code=404, detail="概念不存在")

    concept = CONCEPT_BRIDGES[concept_id]

    return {
        "success": True,
        "data": {
            "concept_id": concept_id,
            "tcm_concept": concept["tcm_concept"],
            "western_explanation": concept["western_explanation"],
            "functional_medicine_basis": concept["functional_medicine_parallel"],
            "dietary_recommendations": concept["dietary_connection"],
            "research_background": concept["research_note"],
        },
    }
