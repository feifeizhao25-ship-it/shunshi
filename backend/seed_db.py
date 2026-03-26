"""Seed the database with initial data."""
import sys
sys.path.insert(0, '/opt/shunshi/backend')

from app.db import Session, engine
from sqlalchemy import text

db = Session()

# ========== 24 Solar Terms ==========
solar_terms_data = [
    {"code": "xiaohan", "name_cn": "小寒", "name_en": "Minor Cold", "sequence": 1, "season": "winter", "organ_focus": "kidney", "diet_principle": "温补肾阳", "sleep_advice": "早睡晚起,保暖防寒", "exercise_advice": "温和运动,避免大汗", "emotion_advice": "静养心神,减少忧虑", "theme_color": "#1a4a6e"},
    {"code": "dahan", "name_cn": "大寒", "name_en": "Major Cold", "sequence": 2, "season": "winter", "organ_focus": "kidney", "diet_principle": "益气养血", "sleep_advice": "保证睡眠,养精蓄锐", "exercise_advice": "室内运动为主", "emotion_advice": "宁神定志", "theme_color": "#1a3a5c"},
    {"code": "lichun", "name_cn": "立春", "name_en": "Spring Begins", "sequence": 3, "season": "spring", "organ_focus": "liver", "diet_principle": "辛甘发散,助阳气", "sleep_advice": "夜卧早起", "exercise_advice": "舒展运动,散步慢跑", "emotion_advice": "疏肝解郁,条达情志", "theme_color": "#7cb342"},
    {"code": "yushui", "name_cn": "雨水", "name_en": "Rain Water", "sequence": 4, "season": "spring", "organ_focus": "liver", "diet_principle": "健脾祛湿", "sleep_advice": "早睡早起", "exercise_advice": "户外活动,踏青郊游", "emotion_advice": "保持心情舒畅", "theme_color": "#8bc34a"},
    {"code": "jingzhe", "name_cn": "惊蛰", "name_en": "Awakening of Insects", "sequence": 5, "season": "spring", "organ_focus": "liver", "diet_principle": "清淡养肝", "sleep_advice": "早起活动", "exercise_advice": "伸展筋骨", "emotion_advice": "放松身心", "theme_color": "#9ccc65"},
    {"code": "chunfen", "name_cn": "春分", "name_en": "Spring Equinox", "sequence": 6, "season": "spring", "organ_focus": "liver", "diet_principle": "平衡阴阳", "sleep_advice": "规律作息", "exercise_advice": "放风筝,郊游", "emotion_advice": "心态平和", "theme_color": "#aed581"},
    {"code": "qingming", "name_cn": "清明", "name_en": "Clear and Bright", "sequence": 7, "season": "spring", "organ_focus": "lung", "diet_principle": "柔肝养肺", "sleep_advice": "早睡早起", "exercise_advice": "扫墓踏青,舒缓运动", "emotion_advice": "抒发情志", "theme_color": "#4caf50"},
    {"code": "guyu", "name_cn": "谷雨", "name_en": "Grain Rain", "sequence": 8, "season": "spring", "organ_focus": "lung", "diet_principle": "祛湿健脾", "sleep_advice": "夜卧早起", "exercise_advice": "户外运动", "emotion_advice": "疏肝健脾", "theme_color": "#66bb6a"},
    {"code": "lixia", "name_cn": "立夏", "name_en": "Summer Begins", "sequence": 9, "season": "summer", "organ_focus": "heart", "diet_principle": "清热养心", "sleep_advice": "晚睡早起", "exercise_advice": "游泳,清凉运动", "emotion_advice": "宁心安神", "theme_color": "#f44336"},
    {"code": "xiaoman", "name_cn": "小满", "name_en": "Grain Buds", "sequence": 10, "season": "summer", "organ_focus": "heart", "diet_principle": "清热祛湿", "sleep_advice": "规律作息", "exercise_advice": "户外晨练", "emotion_advice": "平和心态", "theme_color": "#e57373"},
    {"code": "mangzhong", "name_cn": "芒种", "name_en": "Grain in Ear", "sequence": 11, "season": "summer", "organ_focus": "heart", "diet_principle": "祛暑益气", "sleep_advice": "午睡养心", "exercise_advice": "清凉运动,早晚锻炼", "emotion_advice": "静心养神", "theme_color": "#ef5350"},
    {"code": "xiazhi", "name_cn": "夏至", "name_en": "Summer Solstice", "sequence": 12, "season": "summer", "organ_focus": "heart", "diet_principle": "清心泻火", "sleep_advice": "晚睡早起,午休", "exercise_advice": "游泳避暑", "emotion_advice": "心平气和", "theme_color": "#e53935"},
    {"code": "xiaoshu", "name_cn": "小暑", "name_en": "Minor Heat", "sequence": 13, "season": "summer", "organ_focus": "spleen", "diet_principle": "清热解暑", "sleep_advice": "规律作息", "exercise_advice": "室内清凉运动", "emotion_advice": "平和宁静", "theme_color": "#ff7043"},
    {"code": "dashu", "name_cn": "大暑", "name_en": "Major Heat", "sequence": 14, "season": "summer", "organ_focus": "spleen", "diet_principle": "清热解暑,益气养阴", "sleep_advice": "夜睡午休", "exercise_advice": "避暑运动", "emotion_advice": "心静自然凉", "theme_color": "#ff5722"},
    {"code": "liqiu", "name_cn": "立秋", "name_en": "Autumn Begins", "sequence": 15, "season": "autumn", "organ_focus": "lung", "diet_principle": "滋阴润燥", "sleep_advice": "早睡早起", "exercise_advice": "舒缓运动,登高", "emotion_advice": "收敛神气", "theme_color": "#ff9800"},
    {"code": "chushu", "name_cn": "处暑", "name_en": "End of Heat", "sequence": 16, "season": "autumn", "organ_focus": "lung", "diet_principle": "滋阴润肺", "sleep_advice": "早睡早起", "exercise_advice": "户外运动", "emotion_advice": "平和收敛", "theme_color": "#ffa726"},
    {"code": "bailu", "name_cn": "白露", "name_en": "White Dew", "sequence": 17, "season": "autumn", "organ_focus": "lung", "diet_principle": "润肺生津", "sleep_advice": "早睡养阴", "exercise_advice": "户外散步", "emotion_advice": "宁神定志", "theme_color": "#ffcc02"},
    {"code": "qiufen", "name_cn": "秋分", "name_en": "Autumn Equinox", "sequence": 18, "season": "autumn", "organ_focus": "lung", "diet_principle": "阴阳平衡", "sleep_advice": "早睡养阴", "exercise_advice": "登高赏秋", "emotion_advice": "神志安宁", "theme_color": "#fdd835"},
    {"code": "hanlu", "name_cn": "寒露", "name_en": "Cold Dew", "sequence": 19, "season": "autumn", "organ_focus": "spleen", "diet_principle": "滋阴润燥", "sleep_advice": "早睡早起", "exercise_advice": "户外活动", "emotion_advice": "收敛神气", "theme_color": "#f9a825"},
    {"code": "shuangjiang", "name_cn": "霜降", "name_en": "Frost's Descent", "sequence": 20, "season": "autumn", "organ_focus": "spleen", "diet_principle": "补益肝肾", "sleep_advice": "早睡养阴", "exercise_advice": "保暖防寒", "emotion_advice": "宁神平和", "theme_color": "#f57f17"},
    {"code": "lidong", "name_cn": "立冬", "name_en": "Winter Begins", "sequence": 21, "season": "winter", "organ_focus": "kidney", "diet_principle": "温补肾气", "sleep_advice": "早睡晚起", "exercise_advice": "室内运动为主", "emotion_advice": "藏神养心", "theme_color": "#5c6bc0"},
    {"code": "xiaoxue", "name_cn": "小雪", "name_en": "Minor Snow", "sequence": 22, "season": "winter", "organ_focus": "kidney", "diet_principle": "温肾益精", "sleep_advice": "早睡晚起", "exercise_advice": "保暖运动", "emotion_advice": "静养心神", "theme_color": "#3949ab"},
    {"code": "daxue", "name_cn": "大雪", "name_en": "Major Snow", "sequence": 23, "season": "winter", "organ_focus": "kidney", "diet_principle": "温补助阳", "sleep_advice": "早睡晚起", "exercise_advice": "避寒保暖", "emotion_advice": "养藏固精", "theme_color": "#303f9f"},
    {"code": "dongzhi", "name_cn": "冬至", "name_en": "Winter Solstice", "sequence": 24, "season": "winter", "organ_focus": "kidney", "diet_principle": "补肾藏精", "sleep_advice": "早睡晚起,子午觉", "exercise_advice": "太极八段锦", "emotion_advice": "静心养神", "theme_color": "#1a237e"},
]

print("Seeding solar terms...")
for st in solar_terms_data:
    try:
        db.execute(text("""
            INSERT INTO solar_terms (code, name_cn, name_en, sequence, season, organ_focus, diet_principle, sleep_advice, exercise_advice, emotion_advice, theme_color)
            VALUES (:code, :name_cn, :name_en, :sequence, :season, :organ_focus, :diet_principle, :sleep_advice, :exercise_advice, :emotion_advice, :theme_color)
            ON CONFLICT (code) DO NOTHING
        """), st)
    except Exception as e:
        print(f"  Solar term {st['code']}: {e}")

db.commit()
count = db.execute(text("SELECT count(*) FROM solar_terms")).fetchone()[0]
print(f"Solar terms seeded: {count}/24")

# ========== 9 Constitution Types ==========
constitution_data = [
    {"code": "pinghe", "name_cn": "平和质", "name_en": "Balanced", "description": "阴阳气血调和,体态适中,面色润泽,精力充沛,睡眠良好,二便正常。", "characteristics": '["体态均衡","面色润泽","精力充沛","睡眠良好","适应力强"]', "diet_recommendations": '["饮食均衡","清淡为主","规律进餐"]', "lifestyle_advice": '["规律作息","适度运动","心态平和"]'},
    {"code": "qixu", "name_cn": "气虚质", "name_en": "Qi Deficiency", "description": "元气不足,容易疲乏,气短懒言,语音低弱,容易出汗。", "characteristics": '["容易疲乏","气短懒言","语音低弱","易出汗","抵抗力弱"]', "diet_recommendations": '["补气食物","山药","黄芪","鸡肉","红枣"]', "lifestyle_advice": '["避免劳累","适度休息","轻柔运动"]'},
    {"code": "yangxu", "name_cn": "阳虚质", "name_en": "Yang Deficiency", "description": "阳气不足,畏寒怕冷,手脚冰凉,精神不振。", "characteristics": '["畏寒怕冷","手脚冰凉","精神不振","喜热饮食","尿多清长"]', "diet_recommendations": '["温补食物","羊肉","桂圆","核桃","姜"]', "lifestyle_advice": '["保暖避寒","适度晒太阳","早睡晚起"]'},
    {"code": "yinxu", "name_cn": "阴虚质", "name_en": "Yin Deficiency", "description": "阴液不足,口干咽燥,手足心热,大便干燥。", "characteristics": '["口干咽燥","手足心热","大便干燥","喜冷饮","失眠多梦"]', "diet_recommendations": '["滋阴食物","梨","百合","银耳","蜂蜜"]', "lifestyle_advice": '["避免熬夜","放松心情","适度补水"]'},
    {"code": "tanshi", "name_cn": "痰湿质", "name_en": "Phlegm-Dampness", "description": "痰湿凝聚,体形肥胖,腹部肥满,面部皮肤油脂较多。", "characteristics": '["体形肥胖","腹部肥满","油光满面","痰多粘腻","身重不爽"]', "diet_recommendations": '["清淡食物","冬瓜","薏米","赤小豆","荷叶"]', "lifestyle_advice": '["加强运动","规律作息","远离潮湿"]'},
    {"code": "shire", "name_cn": "湿热质", "name_en": "Damp-Heat", "description": "湿热内蕴,面垢油光,口苦口干,易生痘痘。", "characteristics": '["面垢油光","口苦口干","易生痘痘","大便粘滞","急躁易怒"]', "diet_recommendations": '["清热祛湿","苦瓜","黄瓜","绿豆","莲子"]', "lifestyle_advice": '["避免辛辣","保持干爽","平和心态"]'},
    {"code": "xueyu", "name_cn": "血瘀质", "name_en": "Blood Stasis", "description": "血行不畅,肤色晦暗,容易出现瘀斑,身体某处刺痛。", "characteristics": '["肤色晦暗","瘀斑","身体刺痛","健忘","易烦躁"]', "diet_recommendations": '["活血化瘀","黑木耳","山楂","红糖","洋葱"]', "lifestyle_advice": '["适度运动","心情舒畅","经络按摩"]'},
    {"code": "qiyu", "name_cn": "气郁质", "name_en": "Qi Stagnation", "description": "气机郁滞,神情抑郁,忧虑脆弱,多愁善感。", "characteristics": '["神情抑郁","忧虑脆弱","多愁善感","睡眠不佳","胁肋胀痛"]', "diet_recommendations": '["疏肝解郁","玫瑰花茶","陈皮","山楂","柑橘"]', "lifestyle_advice": '["户外活动","倾诉交流","培养爱好"]'},
    {"code": "tebing", "name_cn": "特禀质", "name_en": "Special Constitution", "description": "先天失常,以生理缺陷、过敏反应等为主要特征。", "characteristics": '["过敏体质","哮喘","鼻炎","荨麻疹","先天缺陷"]', "diet_recommendations": '["避免过敏原","清淡饮食","补充维生素"]', "lifestyle_advice": '["远离过敏原","增强体质","及时就医"]'},
]

print("Seeding constitution types...")
for ct in constitution_data:
    try:
        db.execute(text("""
            INSERT INTO constitution_types (code, name_cn, name_en, description, characteristics, diet_recommendations, lifestyle_advice)
            VALUES (:code, :name_cn, :name_en, :description, :characteristics, :diet_recommendations, :lifestyle_advice)
            ON CONFLICT (code) DO NOTHING
        """), ct)
    except Exception as e:
        print(f"  Constitution {ct['code']}: {e}")

db.commit()
count = db.execute(text("SELECT count(*) FROM constitution_types")).fetchone()[0]
print(f"Constitution types seeded: {count}/9")

# ========== Sample Recipes ==========
recipes_data = [
    {"title": "山药红枣粥", "subtitle": "补气养血,健脾益肺", "category": "meal", "functions": '["补气","养血","健脾"]', "suitable_constitutions": '["qixu","yangxu","pinghe"]', "prep_time": 15, "cook_time": 40, "difficulty": 1, "ingredients": '[{"name":"山药","amount":"100g","unit":"克"},{"name":"红枣","amount":"10颗","unit":"个"},{"name":"大米","amount":"50g","unit":"克"}]', "steps": '[{"step_number":1,"description":"山药去皮切块,红枣去核"},{"step_number":2,"description":"大米洗净,与山药红枣同煮"},{"step_number":3,"description":"小火熬40分钟至粥稠"}]', "tips": "山药去皮时戴手套避免手痒"},
    {"title": "枸杞菊花茶", "subtitle": "清肝明目,养阴润燥", "category": "tea", "functions": '["清肝","明目","养阴"]', "suitable_constitutions": '["yinxu","shire","qiyu"]', "prep_time": 5, "cook_time": 5, "difficulty": 1, "ingredients": '[{"name":"枸杞","amount":"10g","unit":"克"},{"name":"菊花","amount":"5g","unit":"克"}]', "steps": '[{"step_number":1,"description":"枸杞菊花放入杯中"},{"step_number":2,"description":"90度开水冲泡5分钟"},{"step_number":3,"description":"代茶饮用,每日2杯"}]', "tips": "菊花选用杭白菊效果更佳"},
    {"title": "八段锦", "subtitle": "传统养生功法,调理气血", "category": "exercise", "functions": '["调理气血","舒筋活络","强身健体"]', "suitable_constitutions": '["qixu","xueyu","pinghe"]', "total_duration": 20, "difficulty": 1, "steps": '[{"step_number":1,"title":"双手托天理三焦","description":"双手上托,自然呼吸,重复8次"},{"step_number":2,"title":"左右开弓似射雕","description":"马步开弓,左右各4次"},{"step_number":3,"title":"调理脾胃须单举","description":"单手上举,交替各8次"}]', "tips": "每日清晨练习效果最佳"},
]

print("Seeding recipes...")
for r in recipes_data:
    try:
        db.execute(text("""
            INSERT INTO recipes (title, subtitle, category, functions, suitable_constitutions, prep_time, cook_time, difficulty, ingredients, steps, tips)
            VALUES (:title, :subtitle, :category, :functions, :suitable_constitutions, :prep_time, :cook_time, :difficulty, :ingredients, :steps, :tips)
        """), r)
    except Exception as e:
        print(f"  Recipe {r['title']}: {e}")

db.commit()
count = db.execute(text("SELECT count(*) FROM recipes")).fetchone()[0]
print(f"Recipes seeded: {count}")

# ========== Sample Acupoints ==========
acupoints_data = [
    {"name_cn": "足三里", "name_pinyin": "Zusanli", "name_en": "Zusanli (ST36)", "meridian": "足阳明胃经", "location_description": "犊鼻下3寸,胫骨前缘旁开一横指", "functions": '["调理脾胃","增强免疫","延缓衰老"]', "indications": '["消化不良","胃痛","体虚"]', "massage_method": "用拇指按揉,力度适中,每次3-5分钟,顺时针方向", "massage_duration": 5, "related_constitutions": '["qixu","qiyu"]'},
    {"name_cn": "涌泉穴", "name_pinyin": "Yongquan", "name_en": "Yongquan (KI1)", "meridian": "足少阴肾经", "location_description": "足底前部凹陷处,约第二、三趾缝纹头端与足跟连线的前1/3处", "functions": '["滋阴补肾","宁心安神","开窍醒神"]', "indications": '["失眠","头痛","眩晕","急救"]', "massage_method": "用手掌鱼际或拇指按压,力度由轻到重,每次3-5分钟", "massage_duration": 3, "related_constitutions": '["yinxu","yangxu","qiyu"]'},
    {"name_cn": "太冲穴", "name_pinyin": "Taichong", "name_en": "Taichong (LR3)", "meridian": "足厥阴肝经", "location_description": "足背第一、二趾间凹陷处,拇趾与次趾的夹缝往上约一横指", "functions": '["疏肝解郁","平肝潜阳","调理气血"]', "indications": '["头痛","眩晕","情绪抑郁","月经不调"]', "massage_method": "拇指按揉或点按,力度适中,每次2-3分钟", "massage_duration": 3, "related_constitutions": '["qiyu","shire","xueyu"]'},
    {"name_cn": "关元穴", "name_pinyin": "Guanyuan", "name_en": "Guanyuan (CV4)", "meridian": "任脉", "location_description": "下腹部前正中线上,脐下3寸处", "functions": '["补肾固本","温阳散寒","调理冲任"]', "indications": '["腹痛","腹泻","阳痿","月经不调","遗精"]', "massage_method": "手掌根部按揉或艾灸,温热为度,每次10-15分钟", "massage_duration": 10, "related_constitutions": '["yangxu","qixu","pinghe"]'},
    {"name_cn": "内关穴", "name_pinyin": "Neiguan", "name_en": "Neiguan (PC6)", "meridian": "手厥阴心包经", "location_description": "前臂掌侧,腕横纹上2寸,掌长肌腱与桡侧腕屈肌腱之间", "functions": '["宽胸理气","和胃降逆","宁心安神"]', "indications": '["心悸","失眠","胃痛","晕车","孕吐"]', "massage_method": "拇指按压,力度适中,每次3-5分钟", "massage_duration": 3, "related_constitutions": '["qiyu","yinxu","qixu"]'},
    {"name_cn": "三阴交", "name_pinyin": "Sanyinjiao", "name_en": "Sanyinjiao (SP6)", "meridian": "足太阴脾经", "location_description": "内踝尖上3寸,胫骨内侧后缘", "functions": '["健脾养血","调补肝肾","调理妇科"]', "indications": '["月经不调","痛经","失眠","消化不良"]', "massage_method": "拇指按揉,早晚各一次,每次5-10分钟", "massage_duration": 5, "related_constitutions": '["yinxu","xueyu","qixu"]'},
    {"name_cn": "百会穴", "name_pinyin": "Baihui", "name_en": "Baihui (GV20)", "meridian": "督脉", "location_description": "头顶正中线,两耳尖连线的中点", "functions": '["醒脑开窍","平肝熄风","升阳固脱"]', "indications": '["头痛","眩晕","失眠","脱肛","高血压"]', "massage_method": "掌心轻按或敲打,力度轻柔,每次3-5分钟", "massage_duration": 3, "related_constitutions": '["yangxu","qiyu","yinxu"]'},
    {"name_cn": "合谷穴", "name_pinyin": "Hegu", "name_en": "Hegu (LI4)", "meridian": "手阳明大肠经", "location_description": "手背第一、二掌骨之间,第二掌骨中点,拇指侧凹陷处", "functions": '["通经活络","疏风解表","镇痛"]', "indications": '["头痛","牙痛","感冒","月经痛","面部麻痹"]', "massage_method": "拇指按压,力度由轻到重,每次3分钟", "massage_duration": 3, "related_constitutions": '["qiyu","shire","pinghe"]'},
]

print("Seeding acupoints...")
for a in acupoints_data:
    try:
        db.execute(text("""
            INSERT INTO acupoints (name_cn, name_pinyin, name_en, meridian, location_description, functions, indications, massage_method, massage_duration, related_constitutions)
            VALUES (:name_cn, :name_pinyin, :name_en, :meridian, :location_description, :functions, :indications, :massage_method, :massage_duration, :related_constitutions)
        """), a)
    except Exception as e:
        print(f"  Acupoint {a['name_cn']}: {e}")

db.commit()
count = db.execute(text("SELECT count(*) FROM acupoints")).fetchone()[0]
print(f"Acupoints seeded: {count}")

db.close()
print("=== Database seeding complete! ===")
