# 人群养生知识库 + 个性化推荐 API
# 按年龄阶段、职业群体、特殊人群分类的养生方案

from fastapi import APIRouter, Query
from datetime import datetime
import hashlib
import random
from typing import Optional

from app.database.db import get_db, row_to_dict

router = APIRouter(prefix="/api/v1/crowd", tags=["人群养生"])

# ═══════════════════════════════════════════════════════════
# 人群养生知识库（按年龄 × 职业 × 特殊人群）
# ═══════════════════════════════════════════════════════════

CROWD_KNOWLEDGE = [
    # ═══ 20-30岁 活力期 ═══
    {
        "id": "crowd_young_001",
        "title": "熬夜修仙族的补救指南",
        "age_group": "young", "life_stage": "20-30岁",
        "occupations": ["程序员", "设计师", "互联网", "自由职业", "学生"],
        "tags": ["熬夜", "护眼", "养肝", "补气血"],
        "symptoms": ["黑眼圈", "皮肤暗沉", "脱发", "记忆力下降"],
        "icon": "🖥️",
        "summary": "年轻人熬夜多，重点在护肝明目、补气血、防脱发",
        "recommendations": {
            "diet": [
                {"title": "枸杞菊花决明子茶", "desc": "清肝明目，适合长时间看屏幕", "frequency": "每日1-2杯", "difficulty": "简单"},
                {"title": "黑芝麻核桃糊", "desc": "补肾养发，改善发质", "frequency": "每周3次", "difficulty": "简单"},
                {"title": "红枣桂圆小米粥", "desc": "补气血，改善面色", "frequency": "每周2-3次", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "颈椎操（10分钟）", "desc": "缓解久坐颈椎僵硬", "frequency": "每2小时1次", "difficulty": "简单"},
                {"title": "八段锦·两手托天理三焦", "desc": "拉伸脊柱，疏通三焦经", "frequency": "每日晨起", "difficulty": "简单"},
                {"title": "户外慢跑30分钟", "desc": "增强心肺，释放压力", "frequency": "每周3次", "difficulty": "中等"},
            ],
            "sleep": [
                {"title": "23:00前入睡（子时养胆）", "desc": "23-1点胆经当令，此时入睡最养肝", "frequency": "每日", "difficulty": "难"},
                {"title": "睡前远离屏幕30分钟", "desc": "蓝光抑制褪黑素分泌", "frequency": "每日", "difficulty": "中等"},
                {"title": "薰衣草精油助眠", "desc": "滴1-2滴枕边，安神助眠", "frequency": "每晚", "difficulty": "简单"},
            ],
            "key_points": [
                "子时（23点）前入睡，养肝胆之气",
                "久坐每2小时起身活动5分钟",
                "减少冷饮寒食，保护脾胃阳气",
                "补肾养发：黑芝麻、核桃、黑豆",
            ]
        }
    },
    {
        "id": "crowd_young_002",
        "title": "外卖党营养自救手册",
        "age_group": "young", "life_stage": "20-30岁",
        "occupations": ["上班族", "白领", "销售", "学生", "程序员"],
        "tags": ["外卖", "营养", "脾胃", "消化"],
        "symptoms": ["胃胀", "消化不良", "长痘", "体重波动"],
        "icon": "🍱",
        "summary": "长期吃外卖伤脾胃，重点在健脾养胃、均衡营养",
        "recommendations": {
            "diet": [
                {"title": "饭前一碗汤（养胃）", "desc": "先喝汤再吃饭，给胃一个缓冲", "frequency": "每餐", "difficulty": "简单"},
                {"title": "饭后山楂水助消化", "desc": "消食化积，防止胃胀", "frequency": "饭后", "difficulty": "简单"},
                {"title": "山药薏米粥（周末自制）", "desc": "健脾祛湿，修复脾胃", "frequency": "每周2次", "difficulty": "简单"},
                {"title": "每天一个苹果", "desc": "富含果胶，促进肠道蠕动", "frequency": "每日", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "饭后散步15分钟", "desc": "促进消化，不宜剧烈运动", "frequency": "每日午餐后", "difficulty": "简单"},
            ],
            "sleep": [],
            "key_points": [
                "外卖油腻多盐，饭前喝汤保护胃黏膜",
                "每周至少3顿自己做饭",
                "少吃夜宵，给脾胃休息时间",
                "便秘者每天早起一杯温蜂蜜水",
            ]
        }
    },
    {
        "id": "crowd_young_003",
        "title": "考试季/加班季抗压养生",
        "age_group": "young", "life_stage": "20-30岁",
        "occupations": ["学生", "程序员", "金融", "律师", "医生"],
        "tags": ["压力", "焦虑", "失眠", "记忆力"],
        "symptoms": ["焦虑", "失眠", "头痛", "注意力下降"],
        "icon": "📚",
        "summary": "高压环境下保持专注力和精力的养生方案",
        "recommendations": {
            "diet": [
                {"title": "核桃杏仁奶", "desc": "补脑益智，缓解用脑疲劳", "frequency": "每日1杯", "difficulty": "简单"},
                {"title": "香蕉燕麦早餐", "desc": "富含钾和镁，稳定情绪", "frequency": "每日早餐", "difficulty": "简单"},
                {"title": "百合莲子羹", "desc": "养心安神，缓解焦虑", "frequency": "每周3次", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "4-7-8呼吸法", "desc": "吸气4秒→屏气7秒→呼气8秒，快速降压", "frequency": "焦虑时立即做", "difficulty": "简单"},
                {"title": "课间/工间拉伸5分钟", "desc": "肩颈+腰部拉伸，缓解久坐", "frequency": "每90分钟", "difficulty": "简单"},
            ],
            "sleep": [
                {"title": "睡前写下3件感恩的事", "desc": "缓解焦虑，改善睡眠质量", "frequency": "每晚", "difficulty": "简单"},
            ],
            "key_points": [
                "压力时身体消耗B族维生素，注意补充",
                "25分钟番茄工作法：工作25分钟+休息5分钟",
                "睡前不要复习/加班，给大脑1小时缓冲",
                "焦虑时深呼吸比任何药物都有效",
            ]
        }
    },

    # ═══ 30-40岁 平衡期 ═══
    {
        "id": "crowd_mid_001",
        "title": "中年职场人的养肝护肝方案",
        "age_group": "middle", "life_stage": "30-40岁",
        "occupations": ["上班族", "白领", "管理", "销售", "金融"],
        "tags": ["养肝", "应酬", "疲劳", "脂肪肝"],
        "symptoms": ["容易疲劳", "口苦口干", "眼睛干涩", "肝区不适"],
        "icon": "💼",
        "summary": "应酬多、压力大，重点养护肝脏，预防脂肪肝",
        "recommendations": {
            "diet": [
                {"title": "葛根枳椇子解酒茶", "desc": "酒后饮用，保护肝脏", "frequency": "应酬后", "difficulty": "简单"},
                {"title": "决明子菊花茶", "desc": "清肝明目，适合长期用眼", "frequency": "每日1-2杯", "difficulty": "简单"},
                {"title": "芹菜炒百合", "desc": "平肝清热，降脂降压", "frequency": "每周2次", "difficulty": "简单"},
                {"title": "晚餐七分饱", "desc": "减轻肝脏负担，预防脂肪肝", "frequency": "每日", "difficulty": "中等"},
            ],
            "exercise": [
                {"title": "快走/慢跑30分钟", "desc": "中等强度有氧，促进肝脏血液循环", "frequency": "每周5次", "difficulty": "中等"},
                {"title": "太极拳", "desc": "疏肝理气，调节情志", "frequency": "每周3次", "difficulty": "中等"},
            ],
            "sleep": [
                {"title": "23:00前入睡", "desc": "丑时（1-3点）肝经当令，深度睡眠养肝", "frequency": "每日", "difficulty": "中等"},
            ],
            "key_points": [
                "应酬饮酒后补充维生素B和维生素C",
                "每年做一次肝功能检查",
                "少吃油炸和加工食品，减轻肝脏负担",
                "保持情绪舒畅，怒伤肝",
                "晨起空腹一杯温水，促进肝脏排毒",
            ]
        }
    },
    {
        "id": "crowd_mid_002",
        "title": "二胎/三胎妈妈的养生课",
        "age_group": "middle", "life_stage": "30-40岁",
        "occupations": ["全职妈妈", "教师", "上班族"],
        "tags": ["产后", "气血", "疲劳", "腰痛"],
        "symptoms": ["产后脱发", "腰酸背痛", "面色萎黄", "情绪低落"],
        "icon": "👶",
        "summary": "产后和育儿期妈妈的补气血和身体恢复方案",
        "recommendations": {
            "diet": [
                {"title": "黄芪当归乌鸡汤", "desc": "补气养血，改善面色和脱发", "frequency": "每周2次", "difficulty": "中等"},
                {"title": "黑豆红枣粥", "desc": "补肾养血，富含植物雌激素", "frequency": "每周3次", "difficulty": "简单"},
                {"title": "核桃芝麻糊", "desc": "补肾固发，改善产后脱发", "frequency": "每周3次", "difficulty": "简单"},
                {"title": "山药排骨汤", "desc": "健脾益气，增强免疫力", "frequency": "每周2次", "difficulty": "中等"},
            ],
            "exercise": [
                {"title": "凯格尔运动", "desc": "产后盆底肌恢复，预防漏尿", "frequency": "每日3组", "difficulty": "简单"},
                {"title": "产后瑜伽（6周后开始）", "desc": "恢复核心力量，缓解腰背痛", "frequency": "每周3次", "difficulty": "中等"},
            ],
            "sleep": [
                {"title": "跟着宝宝睡，抓住碎片时间", "desc": "与其强求完整睡眠，不如见缝插针", "frequency": "每日", "difficulty": "中等"},
                {"title": "宝宝睡后做5分钟冥想", "desc": "快速恢复精力，缓解焦虑", "frequency": "每日", "difficulty": "简单"},
            ],
            "key_points": [
                "产后42天内不要剧烈运动",
                "产后1年内是身体恢复黄金期",
                "补气血是产后恢复的核心",
                "允许自己不完美，心理休息同样重要",
                "每天晒太阳15分钟，补充维生素D",
            ]
        }
    },
    {
        "id": "crowd_mid_003",
        "title": "久坐办公室颈椎腰椎保养",
        "age_group": "middle", "life_stage": "30-40岁",
        "occupations": ["程序员", "设计师", "白领", "司机", "会计"],
        "tags": ["颈椎", "腰椎", "久坐", "肩周"],
        "symptoms": ["颈椎僵硬", "腰酸", "肩周疼痛", "手指发麻"],
        "icon": "🪑",
        "summary": "久坐导致的颈肩腰问题，重点在疏通经络、加强核心",
        "recommendations": {
            "diet": [
                {"title": "牛膝杜仲猪腰汤", "desc": "补肾强腰，改善腰椎不适", "frequency": "每周1次", "difficulty": "中等"},
                {"title": "葛根茶", "desc": "解肌发表，缓解颈椎僵硬", "frequency": "每日1杯", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "米字操（颈椎）", "desc": "头部画米字，360度活动颈椎", "frequency": "每2小时", "difficulty": "简单"},
                {"title": "靠墙站立5分钟", "desc": "矫正体态，放松肩颈", "frequency": "午休时", "difficulty": "简单"},
                {"title": "小燕飞（腰椎）", "desc": "俯卧抬头挺胸，锻炼腰背肌", "frequency": "每日10个×3组", "difficulty": "简单"},
                {"title": "平板支撑", "desc": "强化核心，保护腰椎", "frequency": "每日30秒×3组", "difficulty": "中等"},
            ],
            "sleep": [
                {"title": "选择合适高度的枕头", "desc": "仰卧拳头高，侧卧肩宽高", "frequency": "长期", "difficulty": "简单"},
            ],
            "key_points": [
                "椅子调到肘部90度、大腿平行地面",
                "显示器上缘与眼睛平齐",
                "每坐45分钟必须起身活动",
                "腰椎问题早期干预效果最好",
                "每年拍一次颈椎/腰椎X光片",
            ]
        }
    },

    # ═══ 40-50岁 调理期 ═══
    {
        "id": "crowd_40_001",
        "title": "更年期前后养生指南",
        "age_group": "40s", "life_stage": "40-50岁",
        "occupations": ["上班族", "教师", "管理", "全职妈妈"],
        "tags": ["更年期", "潮热", "失眠", "骨质疏松"],
        "symptoms": ["潮热出汗", "月经紊乱", "失眠多梦", "情绪波动", "骨关节痛"],
        "icon": "🌸",
        "summary": "更年期前后女性的全面调理，滋阴养血、安神助眠",
        "recommendations": {
            "diet": [
                {"title": "百合银耳莲子羹", "desc": "滋阴润肺，安神助眠，改善潮热", "frequency": "每周3次", "difficulty": "简单"},
                {"title": "黑豆豆浆", "desc": "富含植物雌激素，缓解更年期症状", "frequency": "每日1杯", "difficulty": "简单"},
                {"title": "阿胶红枣粥", "desc": "补血养颜，改善面色萎黄", "frequency": "每周2次", "difficulty": "中等"},
                {"title": "补钙食物：芝麻酱、牛奶、豆腐", "desc": "预防骨质疏松", "frequency": "每日", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "瑜伽（阴瑜伽）", "desc": "舒缓拉伸，调节内分泌", "frequency": "每周3次", "difficulty": "中等"},
                {"title": "快走+晒太阳", "desc": "有氧运动+维生素D，预防骨质疏松", "frequency": "每周5次×30分钟", "difficulty": "简单"},
            ],
            "sleep": [
                {"title": "酸枣仁茶", "desc": "养心安神，改善更年期失眠", "frequency": "睡前1小时", "difficulty": "简单"},
                {"title": "卧室温度18-22°C", "desc": "减少潮热引起的夜间觉醒", "frequency": "长期", "difficulty": "简单"},
            ],
            "key_points": [
                "更年期是正常的生理过渡，不必恐惧",
                "保持规律运动是最有效的调理方式",
                "豆制品每天适量摄入（豆浆/豆腐）",
                "情绪波动时深呼吸或散步调节",
                "建议每年做一次骨密度检查",
            ]
        }
    },
    {
        "id": "crowd_40_002",
        "title": "中年男性养生重点",
        "age_group": "40s", "life_stage": "40-50岁",
        "occupations": ["管理", "上班族", "销售", "企业家"],
        "tags": ["补肾", "前列腺", "疲劳", "三高"],
        "symptoms": ["精力下降", "尿频", "腰酸", "体重增加", "血压偏高"],
        "icon": "💪",
        "summary": "中年男性重点补肾固本、预防三高、保护前列腺",
        "recommendations": {
            "diet": [
                {"title": "山药枸杞羊肉汤", "desc": "温补肾阳，增强精力", "frequency": "秋冬每周2次", "difficulty": "中等"},
                {"title": "番茄炒蛋", "desc": "番茄红素保护前列腺", "frequency": "每周3次", "difficulty": "简单"},
                {"title": "黑木耳拌洋葱", "desc": "降血脂、降血压、抗血栓", "frequency": "每周2次", "difficulty": "简单"},
                {"title": "减少红肉，增加鱼类", "desc": "深海鱼富含Omega-3，保护心血管", "frequency": "长期", "difficulty": "中等"},
            ],
            "exercise": [
                {"title": "深蹲（保护前列腺）", "desc": "增强盆底肌，促进前列腺血液循环", "frequency": "每日30个×2组", "difficulty": "简单"},
                {"title": "游泳", "desc": "全身有氧运动，关节友好", "frequency": "每周3次×40分钟", "difficulty": "中等"},
            ],
            "sleep": [
                {"title": "睡前热水泡脚", "desc": "引火归元，改善睡眠，温补肾阳", "frequency": "每晚", "difficulty": "简单"},
            ],
            "key_points": [
                "40岁后每年做一次全面体检",
                "戒烟限酒是保护心血管的第一步",
                "控制腰围（男性<90cm），预防代谢综合征",
                "减少应酬，健康比面子重要",
                "适当负重训练，预防肌肉流失",
            ]
        }
    },

    # ═══ 50-60岁 保养期 ═══
    {
        "id": "crowd_50_001",
        "title": "退休过渡期养生方案",
        "age_group": "50s", "life_stage": "50-60岁",
        "occupations": ["退休", "即将退休", "教师", "公务员"],
        "tags": ["退休", "心理适应", "关节", "血压"],
        "symptoms": ["失眠", "关节僵硬", "血压波动", "孤独感"],
        "icon": "🏡",
        "summary": "退休后生活节奏改变，重点在心理调适、关节保养、慢病管理",
        "recommendations": {
            "diet": [
                {"title": "低盐低脂饮食", "desc": "每日盐<6g，少油炸，多吃蒸煮", "frequency": "长期", "difficulty": "中等"},
                {"title": "每天500g蔬菜+200g水果", "desc": "补充膳食纤维和维生素", "frequency": "每日", "difficulty": "简单"},
                {"title": "丹参山楂茶", "desc": "活血化瘀，保护心血管", "frequency": "每日1杯", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "太极拳24式", "desc": "最适合中老年人的运动，调心养气", "frequency": "每日30分钟", "difficulty": "简单"},
                {"title": "散步（每日6000-8000步）", "desc": "不强求万步，量力而行", "frequency": "每日", "difficulty": "简单"},
                {"title": "关节保健操", "desc": "活动肩、膝、髋关节，防止僵硬", "frequency": "每日晨起", "difficulty": "简单"},
            ],
            "sleep": [
                {"title": "午睡20-30分钟", "desc": "养心气，不过长以免影响夜间睡眠", "frequency": "每日午间", "difficulty": "简单"},
                {"title": "睡前足三里穴位按摩", "desc": "健脾和胃，安神助眠", "frequency": "每晚", "difficulty": "简单"},
            ],
            "key_points": [
                "退休是新的开始，培养1-2个兴趣爱好",
                "保持社交活动，预防心理孤独",
                "按时服药，定期复查慢病指标",
                "运动量力而行，不要攀比",
                "每年体检，重点关注心血管和肿瘤筛查",
            ]
        }
    },

    # ═══ 60岁以上 颐养期 ═══
    {
        "id": "crowd_elder_001",
        "title": "银发族的四季养生",
        "age_group": "elder", "life_stage": "60岁以上",
        "occupations": ["退休"],
        "tags": ["养生", "慢病", "防跌倒", "饮食"],
        "symptoms": ["腿脚不便", "记忆力减退", "睡眠浅", "消化减弱"],
        "icon": "👴",
        "summary": "老年人四季养生，重在温补脾肾、防寒保暖、适度运动",
        "recommendations": {
            "diet": [
                {"title": "山药小米粥", "desc": "健脾养胃，容易消化", "frequency": "每日早餐", "difficulty": "简单"},
                {"title": "芝麻核桃粉", "desc": "补肾健脑，改善记忆力", "frequency": "每日1勺", "difficulty": "简单"},
                {"title": "鱼汤/鸡汤", "desc": "优质蛋白，增强免疫力", "frequency": "每周3次", "difficulty": "简单"},
                {"title": "食物煮烂煮软", "desc": "减轻胃肠负担，促进消化吸收", "frequency": "长期", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "散步（每日4000-6000步）", "desc": "量力而行，雨天室内活动", "frequency": "每日", "difficulty": "简单"},
                {"title": "拍打经络（八虚穴）", "desc": "肘窝、腋窝、腹股沟、腘窝，疏通气血", "frequency": "每日晨起", "difficulty": "简单"},
                {"title": "坐姿拉伸", "desc": "坐着就能做的关节活动操", "frequency": "每日", "difficulty": "简单"},
            ],
            "sleep": [
                {"title": "热水泡脚（40°C，20分钟）", "desc": "温经散寒，安神助眠", "frequency": "每晚", "difficulty": "简单"},
                {"title": "午睡不超过1小时", "desc": "避免影响夜间睡眠", "frequency": "每日午间", "difficulty": "简单"},
            ],
            "key_points": [
                "春捂秋冻，老人春不急减衣",
                "冬季早晚不出门，防寒保暖",
                "少食多餐，每餐七分饱",
                "家中防跌倒：卫生间装扶手、地面防滑",
                "定期体检，关注血压、血糖、骨密度",
                "保持大脑活跃：阅读、下棋、聊天",
            ]
        }
    },
    {
        "id": "crowd_elder_002",
        "title": "老年常见慢病食疗调养",
        "age_group": "elder", "life_stage": "60岁以上",
        "occupations": ["退休"],
        "tags": ["高血压", "糖尿病", "高血脂", "食疗"],
        "symptoms": ["高血压", "血糖偏高", "血脂异常", "便秘"],
        "icon": "💊",
        "summary": "常见慢病的食疗辅助方案，不能替代药物治疗",
        "recommendations": {
            "diet": [
                {"title": "芹菜汁（降压）", "desc": "富含钾，辅助降压", "frequency": "每日1杯", "difficulty": "简单"},
                {"title": "苦瓜炒蛋（降糖）", "desc": "苦瓜皂苷有降血糖作用", "frequency": "每周3次", "difficulty": "简单"},
                {"title": "燕麦粥（降脂）", "desc": "β-葡聚糖降低胆固醇", "frequency": "每日早餐", "difficulty": "简单"},
                {"title": "火麻仁蜂蜜水（通便）", "desc": "润肠通便，温和不刺激", "frequency": "晨起空腹", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "量力而行，不勉强", "desc": "听身体的信号，累了就休息", "frequency": "每日", "difficulty": "简单"},
            ],
            "sleep": [],
            "key_points": [
                "食疗是辅助，不能替代药物治疗",
                "按时服药，不要自行停药减药",
                "定期监测血压/血糖，记录数据",
                "出现不适及时就医，不要硬扛",
            ]
        }
    },

    # ═══ 特殊人群 ═══
    {
        "id": "crowd_pregnant_001",
        "title": "孕期各阶段养生重点",
        "age_group": "special", "life_stage": "孕期",
        "occupations": [],
        "tags": ["孕期", "叶酸", "安胎", "水肿"],
        "symptoms": ["孕吐", "水肿", "腰酸", "失眠", "便秘"],
        "icon": "🤰",
        "summary": "孕期三个阶段的养生调理方案",
        "recommendations": {
            "diet": [
                {"title": "孕早期：生姜陈皮水止吐", "desc": "缓解孕吐恶心", "frequency": "孕吐时", "difficulty": "简单"},
                {"title": "孕中期：补铁食物（猪肝/菠菜）", "desc": "预防孕期贫血", "frequency": "每周3次", "difficulty": "简单"},
                {"title": "孕晚期：冬瓜鲫鱼汤", "desc": "利水消肿，补充蛋白质", "frequency": "每周2次", "difficulty": "中等"},
                {"title": "全孕期：叶酸+DHA", "desc": "按医嘱补充，不可过量", "frequency": "每日", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "孕中期（14-28周）：孕妇瑜伽", "desc": "缓解腰背痛，帮助分娩", "frequency": "每周3次", "difficulty": "中等"},
                {"title": "散步（最安全的孕期运动）", "desc": "每天30分钟，避免空腹", "frequency": "每日", "difficulty": "简单"},
            ],
            "sleep": [
                {"title": "左侧卧位", "desc": "孕中晚期推荐，改善子宫血流", "frequency": "长期", "difficulty": "中等"},
                {"title": "孕妇枕支撑腹部", "desc": "减轻腰部压力，提高睡眠质量", "frequency": "长期", "difficulty": "简单"},
            ],
            "key_points": [
                "按医嘱定期产检，不可遗漏",
                "禁食生冷、生鱼片、未经巴氏消毒的奶制品",
                "避免接触有害化学物质",
                "保持心情愉悦，孕妇情绪影响胎儿发育",
            ]
        }
    },
    {
        "id": "crowd_student_001",
        "title": "学生党用眼护脑养生",
        "age_group": "young", "life_stage": "学生",
        "occupations": ["学生"],
        "tags": ["学生", "护眼", "记忆力", "长高"],
        "symptoms": ["近视加深", "记忆力下降", "上课犯困", "脊柱侧弯"],
        "icon": "🎓",
        "summary": "学生阶段的用眼保护、记忆力提升和生长发育方案",
        "recommendations": {
            "diet": [
                {"title": "蓝莓/桑葚（护眼）", "desc": "富含花青素，保护视力", "frequency": "每日一小把", "difficulty": "简单"},
                {"title": "鸡蛋+牛奶早餐", "desc": "优质蛋白+胆碱，提升记忆力", "frequency": "每日早餐", "difficulty": "简单"},
                {"title": "牛奶/豆腐（补钙长高）", "desc": "青春期补钙关键期", "frequency": "每日", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "20-20-20护眼法则", "desc": "每20分钟看20英尺外20秒", "frequency": "学习时", "difficulty": "简单"},
                {"title": "跳绳（促进长高）", "desc": "纵向刺激骨骺板", "frequency": "每日500个", "difficulty": "简单"},
                {"title": "课间跑跳运动", "desc": "户外阳光+运动，促进生长激素分泌", "frequency": "每日", "difficulty": "简单"},
            ],
            "sleep": [
                {"title": "小学生9-10小时，中学生8-9小时", "desc": "生长激素在深睡眠时大量分泌", "frequency": "每日", "difficulty": "中等"},
            ],
            "key_points": [
                "坐姿端正，预防近视和脊柱侧弯",
                "少吃零食和含糖饮料",
                "保证每天户外活动1小时以上",
                "晚上不要熬夜学习，效率不如充足睡眠",
            ]
        }
    },
    {
        "id": "crowd_driver_001",
        "title": "司机/长途驾驶养生",
        "age_group": "special", "life_stage": "职业",
        "occupations": ["司机", "外卖", "快递"],
        "tags": ["司机", "腰椎", "疲劳", "胃病"],
        "symptoms": ["腰椎间盘突出", "胃病", "前列腺问题", "疲劳"],
        "icon": "🚗",
        "summary": "长时间驾驶人员的腰椎保护、胃肠调理方案",
        "recommendations": {
            "diet": [
                {"title": "定时进餐，不要饿肚子开车", "desc": "保护胃黏膜，避免胃病", "frequency": "每4小时", "difficulty": "中等"},
                {"title": "车上常备温水、苏打饼干", "desc": "中和胃酸，缓解饥饿", "frequency": "长期", "difficulty": "简单"},
            ],
            "exercise": [
                {"title": "每开2小时停车休息15分钟", "desc": "下车走动，活动腰腿", "frequency": "每2小时", "difficulty": "中等"},
                {"title": "车内做颈部环绕运动", "desc": "等红绿灯时转动头部", "frequency": "等红灯时", "difficulty": "简单"},
            ],
            "sleep": [
                {"title": "避免疲劳驾驶", "desc": "犯困时立即停车休息", "frequency": "有困意时", "difficulty": "中等"},
            ],
            "key_points": [
                "腰托/靠垫保护腰椎",
                "车内保持良好通风，减少CO危害",
                "长途驾驶前保证充足睡眠",
                "定期体检，关注腰椎和心血管",
            ]
        }
    },
]


# ═══════════════════════════════════════════════════════════
# 年龄段映射
# ═══════════════════════════════════════════════════════════

AGE_GROUP_MAP = {
    "young": {"range": "20-30岁", "label": "活力期", "icon": "🌱"},
    "middle": {"range": "30-40岁", "label": "平衡期", "icon": "⚡"},
    "40s": {"range": "40-50岁", "label": "调理期", "icon": "🍂"},
    "50s": {"range": "50-60岁", "label": "保养期", "icon": "🏡"},
    "elder": {"range": "60岁以上", "label": "颐养期", "icon": "👴"},
}

OCCUPATION_LIST = [
    {"id": "office", "label": "上班族", "icon": "💻", "match": ["上班族", "白领", "互联网"]},
    {"id": "tech", "label": "程序员/IT", "icon": "🖥️", "match": ["程序员", "IT", "设计师"]},
    {"id": "teacher", "label": "教师", "icon": "📚", "match": ["教师", "老师"]},
    {"id": "medical", "label": "医护", "icon": "🏥", "match": ["医生", "护士", "医护"]},
    {"id": "management", "label": "管理/创业", "icon": "👔", "match": ["管理", "企业家", "老板"]},
    {"id": "sales", "label": "销售/业务", "icon": "🤝", "match": ["销售", "业务"]},
    {"id": "freelance", "label": "自由职业", "icon": "🎨", "match": ["自由职业", "自由"]},
    {"id": "homemaker", "label": "全职妈妈", "icon": "🏠", "match": ["全职妈妈", "家庭"]},
    {"id": "student", "label": "学生", "icon": "🎓", "match": ["学生"]},
    {"id": "driver", "label": "司机/运输", "icon": "🚗", "match": ["司机", "运输"]},
    {"id": "retired", "label": "退休", "icon": "🏡", "match": ["退休"]},
]


def _age_to_group(age: int) -> str:
    """年龄转年龄段"""
    if age < 30: return "young"
    if age < 40: return "middle"
    if age < 50: return "40s"
    if age < 60: return "50s"
    return "elder"


def _match_occupation(occupation: str, item: dict) -> bool:
    """匹配职业"""
    if not occupation or not item.get("occupations"):
        return False
    occ_lower = occupation.lower()
    for occ in item["occupations"]:
        if occ in occupation or occupation in occ:
            return True
    return False


def _match_tags(user_tags: list, item: dict) -> int:
    """匹配标签数量"""
    item_tags = item.get("tags", [])
    score = 0
    for tag in user_tags:
        for t in item_tags:
            if tag in t or t in tag:
                score += 1
    return score


def _daily_seed(extra: str = "") -> int:
    today = datetime.now().strftime("%Y-%m-%d")
    return int(hashlib.md5(f"{today}-{extra}".encode()).hexdigest(), 16)


@router.get("/recommend")
async def get_crowd_recommendation(
    age: int = Query(30, ge=10, le=100),
    occupation: str = Query(""),
    constitution: str = Query(""),
    tags: str = Query("", description="逗号分隔的用户标签，如 熬夜,压力,颈椎"),
):
    """
    获取人群养生推荐

    综合年龄、职业、体质、用户标签，推荐最匹配的养生方案
    """
    age_group = _age_to_group(age)
    user_tags = [t.strip() for t in tags.split(",") if t.strip()] if tags else []

    # 评分匹配
    scored = []
    for item in CROWD_KNOWLEDGE:
        score = 0

        # 年龄匹配 (权重40)
        if item["age_group"] == age_group:
            score += 40
        elif _age_to_group(age - 10) == item["age_group"] or _age_to_group(age + 10) == item["age_group"]:
            score += 20

        # 职业匹配 (权重30)
        if _match_occupation(occupation, item):
            score += 30

        # 标签匹配 (权重20)
        tag_score = _match_tags(user_tags, item)
        score += tag_score * 5

        # 体质匹配 (权重10) — 通过tags间接匹配
        if constitution:
            const_tags = {
                "qixu": ["疲劳", "气虚", "补气"],
                "yangxu": ["畏寒", "阳虚", "温阳"],
                "yinxu": ["阴虚", "盗汗", "滋阴"],
                "tanshi": ["湿气", "痰湿", "祛湿"],
                "shire": ["湿热", "清热"],
                "xueyu": ["血瘀", "活血"],
                "qiyu": ["压力", "焦虑", "疏肝"],
            }
            ct = constitution.lower()
            if ct in const_tags:
                for ct_tag in const_tags[ct]:
                    for t in item.get("tags", []):
                        if ct_tag in t:
                            score += 10
                            break

        if score > 0:
            scored.append({**item, "match_score": score})

    # 排序
    scored.sort(key=lambda x: x["match_score"], reverse=True)

    # 确定性选1个主推荐（每天轮换）
    seed = _daily_seed(f"{age}-{occupation}-{constitution}")
    rng = random.Random(seed)
    top = scored[:3] if len(scored) >= 3 else scored
    if top:
        primary = rng.choice(top)
    else:
        primary = CROWD_KNOWLEDGE[0]

    # 取其他推荐
    others = [s for s in scored if s["id"] != primary["id"]][:4]

    return {
        "success": True,
        "data": {
            "user_profile": {
                "age": age,
                "age_group": AGE_GROUP_MAP.get(age_group, {}),
                "occupation": occupation,
                "constitution": constitution,
            },
            "primary": {
                "id": primary["id"],
                "title": primary["title"],
                "icon": primary["icon"],
                "summary": primary["summary"],
                "symptoms": primary.get("symptoms", []),
                "match_score": primary.get("match_score", 0),
                "recommendations": primary["recommendations"],
                "key_points": primary.get("key_points", []),
            },
            "others": [
                {
                    "id": o["id"],
                    "title": o["title"],
                    "icon": o["icon"],
                    "summary": o["summary"],
                    "match_score": o.get("match_score", 0),
                } for o in others
            ],
        }
    }


@router.get("/list")
async def get_crowd_list(
    age_group: str = Query("", description="young/middle/40s/50s/elder/special"),
    category: str = Query("", description="分类标签"),
):
    """获取人群养生方案列表（知识库浏览）"""
    items = CROWD_KNOWLEDGE

    if age_group:
        items = [i for i in items if i["age_group"] == age_group]

    if category:
        items = [i for i in items if category in i.get("tags", [])]

    return {
        "success": True,
        "data": {
            "items": [
                {
                    "id": i["id"],
                    "title": i["title"],
                    "icon": i["icon"],
                    "summary": i["summary"],
                    "age_group": i["age_group"],
                    "occupations": i.get("occupations", []),
                    "tags": i.get("tags", []),
                    "symptoms": i.get("symptoms", []),
                } for i in items
            ],
            "total": len(items),
        }
    }


@router.get("/occupations")
async def get_occupation_list():
    """获取职业列表（供 onboarding 使用）"""
    return {
        "success": True,
        "data": OCCUPATION_LIST,
    }


@router.get("/detail/{item_id}")
async def get_crowd_detail(item_id: str):
    """获取人群养生方案详情"""
    for item in CROWD_KNOWLEDGE:
        if item["id"] == item_id:
            return {"success": True, "data": item}
    return {"success": False, "message": "未找到该方案"}
