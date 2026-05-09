// Constitution data models and constants

class ConstitutionType {
  final String key;
  final String name;
  final String emoji;
  final String description;
  const ConstitutionType({required this.key, required this.name, required this.emoji, required this.description});
}

class QuestionOption {
  final int score;
  final String text;
  const QuestionOption({required this.score, required this.text});
}

class Question {
  final int id;
  final String text;
  final List<QuestionOption> options;
  const Question({required this.id, required this.text, required this.options});
}

class HealthAdvice {
  final String category;
  final String icon;
  final List<String> items;
  const HealthAdvice({required this.category, this.icon = '', required this.items});
}

class ConstitutionResult {
  final String resultId;
  final String typeKey;
  final String typeName;
  final String emoji;
  final String description;
  final List<String> characteristics;
  final List<HealthAdvice> advice;
  final List<Map<String, dynamic>> scores;
  final String avoidList;
  final bool isPremium;
  const ConstitutionResult({
    required this.resultId, required this.typeKey, required this.typeName,
    required this.emoji, required this.description, required this.characteristics,
    required this.advice, required this.scores, this.avoidList = '', this.isPremium = false,
  });
}

class ConstitutionDetail {
  final String name;
  final String emoji;
  final String description;
  final List<String> characteristics;
  final List<HealthAdvice> advice;
  final String avoidList;
  const ConstitutionDetail({required this.name, required this.emoji, required this.description, required this.characteristics, required this.advice, required this.avoidList});
}

const List<ConstitutionType> kConstitutionTypes = [
  ConstitutionType(key: 'qixu', name: '气虚质', emoji: '😰', description: '元气不足，易疲乏气短'),
  ConstitutionType(key: 'yangxu', name: '阳虚质', emoji: '🥶', description: '阳气不足，畏寒怕冷'),
  ConstitutionType(key: 'yinxu', name: '阴虚质', emoji: '🔥', description: '阴液亏少，口燥咽干'),
  ConstitutionType(key: 'tanshi', name: '痰湿质', emoji: '😪', description: '痰湿凝聚，体形肥胖'),
  ConstitutionType(key: 'shire', name: '湿热质', emoji: '🤢', description: '湿热内蕴，面垢油光'),
  ConstitutionType(key: 'xueyu', name: '血瘀质', emoji: '😣', description: '血行不畅，肤色晦暗'),
  ConstitutionType(key: 'qiyu', name: '气郁质', emoji: '😔', description: '气机郁滞，神情抑郁'),
  ConstitutionType(key: 'tebing', name: '特禀质', emoji: '🤧', description: '先天失常，易过敏'),
  ConstitutionType(key: 'pinghe', name: '平和质', emoji: '😊', description: '阴阳调和，体态适中'),
];

const Map<String, String> kConstitutionEmoji = {
  'pinghe': '😊', 'qixu': '😰', 'yangxu': '🥶', 'yinxu': '🔥',
  'tanshi': '😪', 'shire': '🤢', 'xueyu': '😣', 'qiyu': '😔', 'tebing': '🤧',
};

const Map<String, String> kConstitutionDesc = {
  'pinghe': '阴阳气血调和，体态适中，面色润泽，精力充沛，睡眠良好',
  'qixu': '元气不足，易疲乏，气短懒言，易出汗，易感冒',
  'yangxu': '阳气不足，手脚发凉，畏寒怕冷，精神不振',
  'yinxu': '体内阴液亏少，口燥咽干，手足心热，盗汗',
  'tanshi': '痰湿凝聚，形体肥胖，腹部肥满松软，口黏腻',
  'shire': '湿热内蕴，面垢油光，口苦口干，身重困倦',
  'xueyu': '血行不畅，肤色晦暗，容易出现瘀斑',
  'qiyu': '气机郁滞，神情抑郁，忧虑脆弱',
  'tebing': '先天禀赋不足或过敏体质，易过敏',
};

const Map<String, List<String>> kConstitutionChars = {
  'pinghe': ['体形匀称健壮', '面色润泽红润', '精力充沛', '睡眠良好', '食欲正常', '二便调畅'],
  'qixu': ['容易疲乏', '气短懒言', '容易出汗', '容易感冒', '声音低弱', '舌淡红，舌体胖大'],
  'yangxu': ['手足不温', '畏寒怕冷', '精神不振', '面色柔白', '喜热饮食', '舌淡胖嫩'],
  'yinxu': ['口燥咽干', '手足心热', '鼻微干', '喜冷饮', '大便干燥', '面色潮红'],
  'tanshi': ['体形肥胖', '面部油脂较多', '多汗且黏', '口黏腻', '身重不爽', '嗜食肥甘'],
  'shire': ['面垢油光', '易生痤疮', '口苦口干', '身重困倦', '大便黏滞不畅', '小便短黄'],
  'xueyu': ['肤色晦暗', '色素沉着', '容易出现瘀斑', '口唇暗淡', '眼眶暗黑', '舌暗有瘀点'],
  'qiyu': ['神情抑郁', '情感脆弱', '烦闷不乐', '多愁善感', '胸胁胀满', '善太息'],
  'tebing': ['过敏体质', '易患哮喘', '容易打喷嚏', '鼻塞流涕', '皮肤易起荨麻疹'],
};

const Map<String, Map<String, String>> kConstitutionAdvice = {
  'pinghe': {'饮食': '饮食有节，不偏食偏嗜，粗细搭配，荤素均衡', '茶饮': '四季均可饮用绿茶、菊花茶等平和茶饮', '运动': '适度运动，散步、太极拳、游泳均可'},
  'qixu': {'饮食': '多食益气健脾食物：黄芪、人参、山药、大枣、小米、糯米、扁豆', '茶饮': '黄芪红枣茶、人参茶、党参茶', '运动': '舒缓运动为主：散步、太极拳、八段锦，避免剧烈运动'},
  'yangxu': {'饮食': '多食温阳散寒食物：羊肉、生姜、桂圆、韭菜、核桃、栗子、红枣', '茶饮': '姜枣茶、桂圆红茶、肉桂茶', '运动': '多晒太阳，适合户外运动，太极拳、艾灸足三里'},
  'yinxu': {'饮食': '多食滋阴润燥食物：银耳、百合、雪梨、枸杞、黑芝麻、鸭肉、甲鱼', '茶饮': '百合银耳茶、枸杞菊花茶、麦冬茶', '运动': '中小强度运动，游泳、瑜伽、慢跑，避免大汗'},
  'tanshi': {'饮食': '少食肥甘厚腻，多食健脾利湿食物：薏米、赤小豆、冬瓜、荷叶、陈皮', '茶饮': '荷叶茶、薏米红豆茶、陈皮茶、山楂茶', '运动': '加强有氧运动，快走、慢跑、游泳，控制体重'},
  'shire': {'饮食': '多食清热利湿食物：绿豆、苦瓜、冬瓜、黄瓜、薏米、莲藕', '茶饮': '金银花茶、菊花茶、荷叶茶、绿豆汤', '运动': '中等强度有氧运动，游泳最佳，适合夏季户外活动'},
  'xueyu': {'饮食': '多食活血化瘀食物：山楂、红花、玫瑰花、黑豆、醋、黑木耳', '茶饮': '玫瑰花茶、山楂茶、红花茶、三七茶', '运动': '适当运动促进气血运行，太极拳、瑜伽、舞蹈'},
  'qiyu': {'饮食': '多食疏肝理气食物：玫瑰花、佛手、柑橘、萝卜、荞麦、金针菇', '茶饮': '玫瑰花茶、茉莉花茶、佛手茶、合欢花茶', '运动': '多参加户外运动和社交活动，跑步、登山、唱歌、舞蹈'},
  'tebing': {'饮食': '饮食清淡，避免过敏源。多食益气固表食物：黄芪、大枣、山药、灵芝', '茶饮': '黄芪红枣茶、灵芝茶、防风茶', '运动': '适度运动增强体质，游泳、散步、太极拳'},
};

const Map<String, List<String>> kConstitutionAvoid = {
  'pinghe': [], 'qixu': ['过度劳累', '大汗淋漓', '生冷食物', '熬夜', '剧烈运动'],
  'yangxu': ['生冷食物', '寒凉环境', '过度吹空调', '冰饮', '寒性水果'],
  'yinxu': ['辛辣食物', '煎炸食物', '熬夜', '过度运动', '羊肉等温热食物'],
  'tanshi': ['肥甘厚腻', '甜食', '酒类', '久坐不动', '生冷食物'],
  'shire': ['辛辣食物', '油腻食物', '酒类', '煎炸食物', '熬夜'],
  'xueyu': ['久坐不动', '寒凉环境', '情绪压抑', '过度安逸'],
  'qiyu': ['长期压抑情绪', '过度思虑', '久坐不动', '独处寡言'],
  'tebing': ['已知过敏食物', '花粉环境', '冷空气', '新装修环境', '宠物毛发'],
};
