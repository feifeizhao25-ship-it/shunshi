"""
顺时 — 微信社交分享生成器 API
生成节气海报文案、体质卡片、打卡文案、月报总结等分享素材。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from datetime import datetime
import random

router = APIRouter(prefix="/api/v1/wechat", tags=["wechat_social"])

# ─────────────────────────────────────────────────────────────────────────────
# 节气海报模板库（24个节气）
# ─────────────────────────────────────────────────────────────────────────────
SOLAR_TERM_POSTERS = {
    "lichun": {
        "name": "立春",
        "date": "2月3-5日",
        "title": "春风十里，不如养生一步",
        "content": "立春是二十四节气之首，阳气开始升发。此时应\"春生\"，宜早睡早起，散步舒缓，疏肝理气。忌讳过度劳累，节制房事，让身体随春风复苏。",
        "golden_sentence": "一年之计在于春，一日之计在于晨。春季养生，从调理肝气开始。",
        "emoji_combo": "🌱 🌿 ☀️ 💚 🌸",
    },
    "yushui": {
        "name": "雨水",
        "date": "2月18-20日",
        "title": "春雨润物，湿气入体需防范",
        "content": "雨水时节，降水增加，湿气加重。此时养生要点：祛湿健脾，避免过度进补，少食油腻。推荐食材：薏米、赤豆、山药，配合温阳茶饮，驱赶初春湿气。",
        "golden_sentence": "春雨贵如油，但湿气也随之而来。及时祛湿，才能迎接春天的生机。",
        "emoji_combo": "🌧️ 💧 🍵 🥗 ☘️",
    },
    "jingzhe": {
        "name": "惊蛰",
        "date": "3月5-7日",
        "title": "春雷一声，生机苏醒时刻到",
        "content": "惊蛰时万物复苏，病菌也活跃。此时应注重疏肝理气，因为春季主肝。饮食清淡，避免过度辛辣刺激。可多食春笋、香椿等春菜，增强抵抗力。",
        "golden_sentence": "一声春雷唤醒了大地，也唤醒了我们体内的阳气。让我们与春天一起复苏。",
        "emoji_combo": "⛈️ 🌱 🍃 💪 🌲",
    },
    "chunfen": {
        "name": "春分",
        "date": "3月20-22日",
        "title": "昼夜均分，规律作息正当时",
        "content": "春分前后昼夜接近等长，可借季节变化重新建立规律睡眠、均衡饮食和适量运动习惯。天气仍有波动，按实际气温增减衣物。",
        "golden_sentence": "春分昼夜均，生活也宜有张有弛。",
        "emoji_combo": "🌗 🌱 🌤️ 🚶 🍵",
    },
    "qingming": {
        "name": "清明",
        "date": "4月4-6日",
        "title": "清明时节，春游养心最相宜",
        "content": "清明春光明媚，适合户外活动。此时养生重在调理情志，春游散心可舒缓肝气郁结。饮食清淡，少油腻，多食新鲜蔬菜。避免扫墓过度悲伤，以免损伤阳气。",
        "golden_sentence": "清明时节，乍暖还寒。最好的养生，是与春天一起踏青，让心情也明亮起来。",
        "emoji_combo": "🏞️ 🚴 💚 🌳 😊",
    },
    "guyu": {
        "name": "谷雨",
        "date": "4月19-21日",
        "title": "春雨润谷，是时候祛湿了",
        "content": "谷雨是春季最后一个节气，雨量充沛，湿气最重。此时应加强祛湿健脾，食用薏米粥、冬瓜汤等。避免长期处于潮湿环境，居住要通风。春季最后的调理机会，莫要错过。",
        "golden_sentence": "春天的最后一场雨，正是祛湿的最好时机。抓住春末，为夏季做准备。",
        "emoji_combo": "🌧️ 🍲 🌬️ 💚 ☀️",
    },
    "lixia": {
        "name": "立夏",
        "date": "5月5-7日",
        "title": "夏至未至，春夏交替最养心",
        "content": "立夏时心火开始旺盛，但天气还未极热。此时应清心、养心，少食辛辣厚腻。推荐绿茶、莲心茶等清心降火。适度运动，避免过度劳累，保证睡眠。\"冬病夏治\"的准备期也开始了。",
        "golden_sentence": "立夏一声雷，春风不复来。季节变更之际，最需要静心调息。",
        "emoji_combo": "☀️ 🫖 💚 🧘 😌",
    },
    "xiaoman": {
        "name": "小满",
        "date": "5月20-22日",
        "title": "小满麦渐黄，人体湿热需关注",
        "content": "小满时湿热开始困扰，皮肤易长痘、口苦、便溏。此时应清热利湿，食用苦瓜、冬瓜、薏米等。避免过度进补，少食油腻厚腻食物。配合适度运动，加强新陈代谢。",
        "golden_sentence": "小满时节，人体湿热如麦子未熟。及时清热，才能顺利度过夏季。",
        "emoji_combo": "🌾 🥒 💚 💦 🏃",
    },
    "mangzhong": {
        "name": "芒种",
        "date": "6月5-7日",
        "title": "芒种忙而有序，炎热时节注意补水",
        "content": "芒种后气温和湿度常升高，户外劳作或运动应避开高温时段、及时补水并保证睡眠。饮食保持清淡多样，出现中暑症状应立即降温并及时就医。",
        "golden_sentence": "芒种虽忙，也要给身体留出休息和补水的时间。",
        "emoji_combo": "🌾 💧 ☀️ 🥗 😴",
    },
    "xiazhi": {
        "name": "夏至",
        "date": "6月20-22日",
        "title": "夏至已至，\"冬病夏治\"三伏灸开始",
        "content": "夏至是一年中最热的时期。此时阳气最盛，是\"冬病夏治\"三伏灸的关键时期。应清心安神，少食冰冷刺激。可食用冬瓜、绿豆等清热食材。避免过度贪凉，脾阳损伤后冬季难受。",
        "golden_sentence": "夏至一阴生，此时虽热，也要防秋冬的寒湿。\"冬病夏治\"的智慧，就在这一时刻。",
        "emoji_combo": "☀️ 🧊 💚 🩹 🏥",
    },
    "xiaoshu": {
        "name": "小暑",
        "date": "7月6-8日",
        "title": "小暑大暑，防暑防湿是关键",
        "content": "小暑时开始进入三伏天的中伏，闷热潮湿最难受。此时应加强祛湿，避免过度吹空调造成\"阴暑\"。食用薏米粥、冬瓜汤，配合温阳茶饮调理脾胃。保证充足睡眠，避免过度劳累。",
        "golden_sentence": "小暑不算热，大暑三伏天。躲过三伏的湿热困扰，秋冬就能健康度过。",
        "emoji_combo": "😰 💦 🏥 🧊 🌾",
    },
    "dashu": {
        "name": "大暑",
        "date": "7月22-24日",
        "title": "三伏末期，最后灸疗不可缺",
        "content": "大暑是夏季最热的时期，也是三伏灸的最后时机。此时应坚持艾灸，温阳扶正，为秋冬储备阳气。饮食清淡，配合清热祛湿的食材。避免过度冷饮，损伤脾阳。大暑过后，秋天就要来临。",
        "golden_sentence": "大暑三伏最后的时刻，不要浪费这个温阳的机会。冬病夏治，就看这一刻。",
        "emoji_combo": "🔥 🩹 ☀️ 💪 🍵",
    },
    "liqiu": {
        "name": "立秋",
        "date": "8月7-9日",
        "title": "秋来燥气伤肺，滋阴润肺是要务",
        "content": "立秋时秋燥开始显现，皮肤干、口干、咳嗽。此时应滋阴润肺，多食蜂蜜、银耳、梨等润肺食材。避免过度进补，以免秋燥加重。配合温阳的食材，不可过度滋阴。秋季养生的关键就在立秋。",
        "golden_sentence": "一叶知秋，秋来燥气伤人。及时调理，才能让秋天的干燥不伤身体。",
        "emoji_combo": "🍂 🍐 💧 💚 🧴",
    },
    "chushu": {
        "name": "处暑",
        "date": "8月22-24日",
        "title": "处暑过后凉意来，贴秋膘要适度",
        "content": "处暑时夏日余热未消，秋凉开始出现。此时应继续滋阴润肺，同时开始温阳健脾为冬季做准备。\"贴秋膘\"要适度，不可过度进补。配合运动，增强脾胃功能。秋季调理的黄金期已经开启。",
        "golden_sentence": "处暑过后，凉意渐浓。既要润肺，也要为冬季的温阳做准备。这是秋季养生最关键的时刻。",
        "emoji_combo": "🍂 🥘 💪 🧘 ☀️",
    },
    "bailu": {
        "name": "白露",
        "date": "9月7-9日",
        "title": "白露秋分夜，秋燥咳嗽多发期",
        "content": "白露时秋燥加重，咳嗽、皮肤干多发。此时应加强滋阴润肺，食用玉竹、麦冬、银耳等。避免熬夜，保证睡眠以滋阴。可开始进行温阳健脾的调理，为冬季准备。秋季最容易损伤肺阴，需格外关注。",
        "golden_sentence": "白露降，秋意深。这个季节的干燥，最容易伤害肺和皮肤。及时滋阴，才是上策。",
        "emoji_combo": "💧 🫖 🍵 🧴 😷",
    },
    "qiufen": {
        "name": "秋分",
        "date": "9月22-24日",
        "title": "秋分阴阳均，调理脾胃最关键",
        "content": "秋分时昼夜平分，阴阳平衡。此时应调理脾胃，为冬季储备能量。食用山药、薏米、红枣等健脾食材。开始增加温阳的食物，如生姜、羊肉等。秋分是从秋燥向冬阳过渡的关键时刻。",
        "golden_sentence": "秋分一刻值千金，阴阳平衡的时刻，最适合调理脾胃。为冬季储备能量，就从秋分开始。",
        "emoji_combo": "⚖️ 🥘 💪 🍵 🌰",
    },
    "hanlu": {
        "name": "寒露",
        "date": "10月8-9日",
        "title": "寒露已深，进补前的最后调理",
        "content": "寒露时天气转凉，\"春捂秋冻\"要适度。此时应温阳健脾，为冬季进补做准备。食用羊肉、黄芪、大枣等温阳食材。开始艾灸足三里、三阴交等穴位。避免过度进补，要先调理脾胃消化能力。",
        "golden_sentence": "寒露时节，冬天已经不远。做好秋季的最后调理，才能为冬季的进补做好准备。",
        "emoji_combo": "🍂 🥘 🔥 🩹 💪",
    },
    "shuangjiang": {
        "name": "霜降",
        "date": "10月23-24日",
        "title": "霜降进补，冬季少生病",
        "content": "霜降是秋冬交接，也是进补的开始。此时应温阳健脾，为冬季储备阳气。羊肉、黄芪、红枣、栗子等温阳食材最适合。配合艾灸，效果更佳。\"冬吃羊肉赛人参，不劳医生开药方\"。霜降开始进补，冬季就能少生病。",
        "golden_sentence": "霜降到，进补早。一冬的健康，就从霜降的进补开始。",
        "emoji_combo": "🐑 🥘 🔥 🏥 💪",
    },
    "lidong": {
        "name": "立冬",
        "date": "11月7-8日",
        "title": "立冬进补，冬季少生病的秘诀",
        "content": "立冬时冬季正式开始，进补的黄金期。此时应温阳扶正，储备阳气。黄芪、红枣、羊肉、栗子等温阳食材最佳。配合三九灸准备，一冬无病痛。避免过度进补，以免内热。\"冬季进补，春天生龙活虎\"。",
        "golden_sentence": "立冬一日，贺冬百倍。冬季的进补，决定了整个冬天的健康。抓住立冬，别浪费这个机会。",
        "emoji_combo": "❄️ 🥘 🔥 🩹 💪",
    },
    "xiaoxue": {
        "name": "小雪",
        "date": "11月22-23日",
        "title": "小雪时节，三九灸即将开始",
        "content": "小雪时冬季进入阳虚最盛的阶段。此时应继续温阳进补，为即将到来的三九灸做准备。食用温阳食材，配合温阳茶饮。避免过度进补导致消化不良。小雪过后，三九灸就要开始，冬季养生进入高潮期。",
        "golden_sentence": "小雪飘飘，冬季更寒。这个时候的温阳进补，最能化解冬季的寒冷。",
        "emoji_combo": "❄️ 🥘 🔥 🏥 ☀️",
    },
    "daxue": {
        "name": "大雪",
        "date": "12月6-8日",
        "title": "大雪三九灸，扶阳大业不可误",
        "content": "大雪时是三九灸的开始季节（12月下旬开始）。此时应大温阳、扶正气。坚持艾灸足三里、三阴交、关元等穴位。食用黄芪、羊肉、栗子等温阳食材。三九灸是全年扶阳最重要的时刻，冬病夏治全靠这一期。",
        "golden_sentence": "大雪纷飞，三九灸即将开始。这是全年温阳扶正的最重要时刻，一定不要错过。",
        "emoji_combo": "❄️ 🩹 🔥 ☀️ 💪",
    },
    "dongzhi": {
        "name": "冬至",
        "date": "12月21-23日",
        "title": "冬至到，三九灸最火时刻",
        "content": "冬至是三九灸的初九时期，也是冬季最冷的时刻。此时应继续坚持三九灸，温阳扶正达到最高效率。\"冬至大如年\"，此时饺子配艾灸，效果最佳。食用温阳食材，保证充足睡眠。冬至过后，白天就开始变长，阳气也开始生发。",
        "golden_sentence": "冬至一阳生，从此天地回春。但在此之前，最后的三九灸温阳，决定了整个冬季的效果。",
        "emoji_combo": "❄️ 🩹 ☀️ 🥟 💪",
    },
    "xiaohan": {
        "name": "小寒",
        "date": "1月5-7日",
        "title": "小寒三九中，坚持灸疗到底",
        "content": "小寒是三九灸的二九时期，冬季还要继续。此时应坚持艾灸，温阳扶正。避免过度劳累，保证充足睡眠以养阳气。食用温阳食材，配合温阳茶饮。小寒过后，春天就不远了。坚持到底，冬季的投入就会在春天收获。",
        "golden_sentence": "小寒三九中，坚持最重要。再有一个多月就春天了，千万别在最后放弃。",
        "emoji_combo": "❄️ 🩹 ☀️ 🫖 💪",
    },
    "dahan": {
        "name": "大寒",
        "date": "1月20-21日",
        "title": "大寒三九末，春天就要来",
        "content": "大寒是三九灸的最后时期，也是冬季的最后时刻。此时应坚持艾灸到底，温阳扶正的成果在这一刻。继续食用温阳食材，配合艾灸效果最佳。大寒过后，立春就要来临。冬季的坚持，就要在春天看到回报。",
        "golden_sentence": "大寒过后，春在咫尺。冬季的所有坚持，都在为春天的生机做准备。",
        "emoji_combo": "❄️ ☀️ 🌱 🫖 💪",
    },
}

SOLAR_TERM_ALIASES = {
    "duanwu": "mangzhong",
    "autumnequinox": "qiufen",
    "hengshan": "hanlu",
    "xiaoXue": "xiaoxue",
}

# ─────────────────────────────────────────────────────────────────────────────
# 体质分享卡片模板库（9种体质）
# ─────────────────────────────────────────────────────────────────────────────
CONSTITUTION_CARDS = {
    "qi_deficiency": {
        "name": "气虚质",
        "tagline": "形体消瘦，容易疲劳，气短声低",
        "core_feature": "气虚体质的人最容易疲劳和感冒，脸色也容易淡白。",
        "adjustment_points": "补气为先，黄芪红枣茶是好帮手；配合艾灸足三里，温阳扶正；运动要温和，散步最合适。",
        "color_suggestion": "黄色、金色（象征温阳的生命力）",
        "emoji": "😴",
    },
    "yang_deficiency": {
        "name": "阳虚质",
        "tagline": "手脚冰凉，怕冷喜暖，容易腹泻",
        "core_feature": "阳虚体质怕冷是最突出的特点，手脚冰凉连冬天都要穿厚厚的衣服。",
        "adjustment_points": "温阳补肾是关键，羊肉、黄芪、生姜不能少；三九灸是冬季的黄金方案；要避免吹空调和冷饮。",
        "color_suggestion": "红色、橙色（象征温阳和热力）",
        "emoji": "❄️",
    },
    "yin_deficiency": {
        "name": "阴虚质",
        "tagline": "口干皮干，易急躁，手脚心热",
        "core_feature": "阴虚体质就像身体内缺水的沙漠，需要滋养才能平衡。",
        "adjustment_points": "滋阴为主，银耳、蜂蜜、玉竹最适合；冬天不要过度温阳，以免加重内热；秋季是调理的黄金期。",
        "color_suggestion": "蓝色、绿色（象征滋阴和清凉）",
        "emoji": "🔥",
    },
    "blood_deficiency": {
        "name": "血虚质",
        "tagline": "面色淡白，容易头晕，唇色淡",
        "core_feature": "血虚体质的女性最为常见，气色不好、容易疲劳是最大困扰。",
        "adjustment_points": "补血为先，红枣、黑芝麻、黑木耳是好帮手；配合足三里艾灸效果更佳；要避免过度熬夜。",
        "color_suggestion": "红色、粉色（象征补血和活力）",
        "emoji": "🩸",
    },
    "damp": {
        "name": "痰湿质",
        "tagline": "形体肥胖，腹部松软，容易疲劳",
        "core_feature": "痰湿体质的人最容易被\"湿气\"困扰，体重难以下降，舌苔厚腻。",
        "adjustment_points": "祛湿健脾是核心，薏米、冬瓜、黑木耳最有效；配合运动，出汗是祛湿最好的方式；避免甜腻食物。",
        "color_suggestion": "绿色、白色（象征祛湿和清爽）",
        "emoji": "💧",
    },
    "damp_heat": {
        "name": "湿热质",
        "tagline": "面部油腻，容易长痘，口苦便溏",
        "core_feature": "湿热体质既有湿气的困扰，又有热气的烦恼，夏季最难受。",
        "adjustment_points": "清热利湿是关键，苦瓜、冬瓜、绿豆最合适；配合适度运动，加强代谢；避免辛辣油腻食物。",
        "color_suggestion": "绿色、黄色（象征清热和健脾）",
        "emoji": "🌶️",
    },
    "qi_stagnation": {
        "name": "气郁质",
        "tagline": "情绪不畅，胸闷容易烦躁，面色晦暗",
        "core_feature": "气郁体质的人往往是情绪敏感、压力大的人群，需要心理调理。",
        "adjustment_points": "疏肝理气是重点，玫瑰花茶、玫瑰山楂茶最合适；春季常见，需要多参加户外活动；舒缓音乐和瑜伽有帮助。",
        "color_suggestion": "粉色、紫色（象征疏泄和舒缓）",
        "emoji": "😔",
    },
    "blood_stasis": {
        "name": "血瘀质",
        "tagline": "面色晦暗，容易长斑，舌质暗",
        "core_feature": "血瘀体质的人气血运行不畅，容易疼痛、长斑、衰老加速。",
        "adjustment_points": "活血化瘀是要点，黑木耳、山楂、红糖是好帮手；配合足三里和三阴交艾灸效果最佳；避免久坐不动。",
        "color_suggestion": "红色、深红色（象征活血和活力）",
        "emoji": "🩹",
    },
    "balanced": {
        "name": "平和质",
        "tagline": "面色润泽，精力充沛，睡眠良好",
        "core_feature": "平和体质的人是最健康的体质，需要坚持养生来维持。",
        "adjustment_points": "四季调理，顺应自然；定期艾灸足三里和关元来保健；饮食清淡均衡，避免过度进补。",
        "color_suggestion": "绿色、金色（象征健康和平衡）",
        "emoji": "😊",
    },
}

# ─────────────────────────────────────────────────────────────────────────────
# 每日打卡文案库（按季节）
# ─────────────────────────────────────────────────────────────────────────────
CHECKIN_CAPTIONS = {
    "spring": [
        "春风十里，我的晨跑也十里 🏃 #春季养生 #疏肝理气",
        "春来喝茶，玫瑰山楂茶疏肝理气 🫖 #体质茶饮 #春季保健",
        "早睡早起赶上春天，从今天开始 🌱 #春季养生 #健康打卡",
        "春天适合散步，绿树成荫就是最好的养生馆 🌿 #春游 #健康生活",
        "春笋、香椿、蛋黄酥，春菜正当时 🥗 #季节食材 #清淡饮食",
        "疏肝理气靠自己，春季运动不能少 💪 #春季运动 #养生打卡",
        "春季最适合清理肠胃，今天只吃清淡的 🥦 #清淡饮食 #养生",
        "坚持艾灸足三里，为夏季储备阳气 🩹 #艾灸保健 #养生打卡",
        "春天的第一杯茶，是最好的春季养生 🫖 #新茶上市 #春季保健",
        "春来心情好，晨跑20分钟，舒适感爆表 🌞 #春季运动 #心情养生",
    ],
    "summer": [
        "三伏天第一天，艾灸不能停 🩹 #三伏灸 #冬病夏治",
        "绿茶配莲心，清心降火一杯足 🫖 #夏季茶饮 #清热祛湿",
        "冬瓜薏米粥，祛湿健脾最适合 🥘 #夏季食疗 #祛湿",
        "夏季不贪凉，避免吹空调直吹 ❄️ #夏季养生 #避免阴暑",
        "晨泳30分钟，阳气最盛时运动效果最好 🏊 #夏季运动 #养生打卡",
        "苦瓜凉瓜汤，清热又祛湿，夏季最爱 🥒 #清热食材 #夏季养生",
        "三伏灸中伏，坚持温阳扶正 🩹 #冬病夏治 #养生打卡",
        "夏至已至，开始防秋冬的寒湿了 ☀️ #节气养生 #远见养生",
        "避免过度贪凉，一杯温和的生姜红糖水最舒服 🫖 #温阳 #夏季养生",
        "虽然很热，但不敢停艾灸，冬天会感谢现在的我 🔥 #坚持养生 #三伏灸",
    ],
    "autumn": [
        "秋燥咳嗽多发期，银耳蜂蜜最解救 🍯 #滋阴润肺 #秋季养生",
        "玉竹麦冬茶，滋阴润肺秋季必备 🫖 #秋季茶饮 #养生打卡",
        "梨、百合、银耳，秋季三宝不能少 🍐 #润肺食材 #秋季保健",
        "立秋进补前，先调理脾胃消化能力 🥘 #秋季进补 #脾胃调理",
        "秋夜漫步，散步赏月是最好的情志调理 🌙 #秋季运动 #心情养生",
        "霜降进补，羊肉黄芪大枣汤最实惠 🐑 #秋季进补 #温阳补气",
        "秋分艾灸，调理脾胃为冬季储备能量 🩹 #秋季艾灸 #养生打卡",
        "避免秋冻过头，早晚加件外套很重要 🧥 #秋季养生 #温阳护阳",
        "坚持滋阴润肺，冬季呼吸道问题就少了 💪 #滋阴 #秋季保健",
        "秋季是从秋燥向冬阳过渡的关键，不能懈怠 ⚖️ #季节交替 #养生打卡",
    ],
    "winter": [
        "小寒大寒时期，三九灸坚持到底 🩹 #三九灸 #冬季养生",
        "冬至一阳生，从此白昼变长，阳气也开始回升 ☀️ #冬至养生 #节气",
        "羊肉汤配艾灸，冬季温阳的黄金组合 🐑 #冬季进补 #养生打卡",
        "黄芪红枣茶，补气扶阳冬季最适合 🫖 #冬季茶饮 #补气",
        "冬季要早睡，养护阳气就靠充足睡眠 😴 #冬季保健 #养生打卡",
        "立冬进补，春天生龙活虎的秘诀就在这 💪 #冬季进补 #养生投资",
        "栗子、大枣、核桃，冬季坚果最养生 🌰 #冬季食材 #坚果进补",
        "冬天虽然冷，也要坚持散步30分钟 🏃 #冬季运动 #阳气生发",
        "三九灸初九，冬季温阳的黄金时刻 🩹 #三九灸 #冬病夏治准备",
        "大寒过后，春天就要来了，坚持到底就是胜利 🌱 #冬季坚持 #春天在即",
    ],
}

# ─────────────────────────────────────────────────────────────────────────────
# 辅助函数
# ─────────────────────────────────────────────────────────────────────────────

def _get_current_season():
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


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/poster/{solar_term_code}", summary="节气朋友圈海报文案")
async def get_solar_term_poster(solar_term_code: str):
    """获取指定节气的朋友圈海报文案。"""
    solar_term_code = SOLAR_TERM_ALIASES.get(solar_term_code, solar_term_code)
    if solar_term_code not in SOLAR_TERM_POSTERS:
        raise HTTPException(status_code=404, detail=f"Solar term '{solar_term_code}' not found")

    poster = SOLAR_TERM_POSTERS[solar_term_code]
    return {
        "success": True,
        "data": poster,
    }


@router.get("/constitution-card/{constitution_type}", summary="体质分享卡片")
async def get_constitution_card(constitution_type: str):
    """获取指定体质的分享卡片内容。"""
    if constitution_type not in CONSTITUTION_CARDS:
        raise HTTPException(status_code=404, detail=f"Constitution type '{constitution_type}' not found")

    card = CONSTITUTION_CARDS[constitution_type]
    return {
        "success": True,
        "data": card,
    }


@router.get("/checkin-caption", summary="今日打卡文案")
async def get_daily_checkin_caption(mood: Optional[str] = Query(None, description="心情: happy/calm/tired")):
    """获取今日打卡文案（随机返回当季一条）。"""
    season = _get_current_season()
    captions = CHECKIN_CAPTIONS.get(season, [])

    if not captions:
        raise HTTPException(status_code=500, detail="No captions available for current season")

    # 如果指定了心情，可以根据心情筛选（简单实现）
    caption = random.choice(captions)

    return {
        "success": True,
        "data": {
            "caption": caption,
            "season": season,
            "mood": mood,
            "timestamp": datetime.now().isoformat(),
        },
    }


@router.post("/monthly-report", summary="月报分享内容生成")
async def generate_monthly_report(body: dict):
    """生成月报分享内容。"""
    user_name = body.get("user_name", "用户").strip()
    month = body.get("month", datetime.now().month)
    checkin_days = body.get("checkin_days", 0)
    avg_mood = body.get("avg_mood", "neutral")
    top_wellness_action = body.get("top_wellness_action", "坚持养生")

    month_names = {
        1: "1月", 2: "2月", 3: "3月", 4: "4月", 5: "5月", 6: "6月",
        7: "7月", 8: "8月", 9: "9月", 10: "10月", 11: "11月", 12: "12月",
    }

    month_name = month_names.get(month, "本月")

    report_text = f"""
【{user_name}的{month_name}健康报告】

恭喜 {user_name}！本月打卡 {checkin_days} 天 🎉

心情指数: {avg_mood}
最坚持的养生方式: {top_wellness_action}

💪 这一个月，你的坚持就是最好的投资！
让我们继续在养生的道路上同行 🌿

✨ 分享你的健康故事，激励更多人加入养生行列！
"""

    return {
        "success": True,
        "data": {
            "user_name": user_name,
            "month": month_name,
            "checkin_days": checkin_days,
            "avg_mood": avg_mood,
            "top_wellness_action": top_wellness_action,
            "report_content": report_text.strip(),
            "share_emoji": "🌿 💪 ✨",
        },
    }


@router.get("/templates", summary="所有可用模板列表")
async def list_templates():
    """列出所有可用的分享模板类型。"""
    return {
        "success": True,
        "data": {
            "templates": {
                "solar_term_poster": {
                    "description": "24个节气的朋友圈海报文案",
                    "count": len(SOLAR_TERM_POSTERS),
                    "available_codes": list(SOLAR_TERM_POSTERS.keys()),
                },
                "constitution_card": {
                    "description": "9种体质的分享卡片",
                    "count": len(CONSTITUTION_CARDS),
                    "available_types": list(CONSTITUTION_CARDS.keys()),
                },
                "daily_checkin": {
                    "description": "每日打卡文案（按季节随机）",
                    "seasons": list(CHECKIN_CAPTIONS.keys()),
                },
                "monthly_report": {
                    "description": "月报分享内容生成（自定义参数）",
                    "parameters": ["user_name", "month", "checkin_days", "avg_mood", "top_wellness_action"],
                },
            },
            "tip": "使用对应的端点获取具体内容",
        },
    }


@router.get("/solar-term-wishes/{solar_term_code}", summary="节气祝福语")
async def get_solar_term_wishes(solar_term_code: str):
    """获取节气祝福语（发给亲友）。"""
    solar_term_code = SOLAR_TERM_ALIASES.get(solar_term_code, solar_term_code)
    if solar_term_code not in SOLAR_TERM_POSTERS:
        raise HTTPException(status_code=404, detail=f"Solar term '{solar_term_code}' not found")

    term = SOLAR_TERM_POSTERS[solar_term_code]
    term_name = term["name"]

    wishes = [
        f"{term_name}将至，愿你春风常驻，气色红润。记得早睡早起，疏肝理气，让阳气伴随你。❤️",
        f"节气{term_name}提醒我们，自然有其道，身体有其节。顺应自然，养护己身，才是最好的养生。🌿",
        f"{term_name}时节，最好的礼物就是提醒你：该养生了！一起喝茶、艾灸、散步，健康过{term_name}。💪",
    ]

    return {
        "success": True,
        "data": {
            "solar_term": term_name,
            "solar_term_code": solar_term_code,
            "wishes": wishes,
            "tip": "选择任一条发给亲友，既是关心也是提醒",
        },
    }
