// 个性化数据服务 — 聚合后端个性化推荐 API
// 并行请求，单个失败不阻塞其他数据
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class PersonalizedData {
  final String? constitutionType;
  final String? constitutionName;
  final String? constitutionSummary;
  final String? aiDailyInsight;
  final String? dailyRecommendation;
  final String? todayTea;
  final String? todayExercise;
  final String? todayAcupoint;
  final String? todayFood;
  final String? solarWellnessAdvice;
  final List<PersonalizedAction> personalActions;
  final List<ConstitutionFood>? constitutionFoods;
  final List<ConstitutionExercise>? constitutionExercises;

  const PersonalizedData({
    this.constitutionType,
    this.constitutionName,
    this.constitutionSummary,
    this.aiDailyInsight,
    this.dailyRecommendation,
    this.todayTea,
    this.todayExercise,
    this.todayAcupoint,
    this.todayFood,
    this.solarWellnessAdvice,
    this.personalActions = const [],
    this.constitutionFoods,
    this.constitutionExercises,
  });
}

class PersonalizedAction {
  final String title;
  final String description;
  final String? iconHint;
  const PersonalizedAction({
    required this.title,
    required this.description,
    this.iconHint,
  });
}

class ConstitutionFood {
  final String name;
  final String? category;
  final String? reason;
  const ConstitutionFood({required this.name, this.category, this.reason});
}

class ConstitutionExercise {
  final String name;
  final String? description;
  const ConstitutionExercise({required this.name, this.description});
}

class PersonalizationService {
  static final String _baseUrl = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');

  static final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// 并行获取所有个性化数据
  static Future<PersonalizedData> fetchPersonalizedData(String? userId) async {
    String? constitutionType;
    String? constitutionName;
    String? constitutionSummary;
    String? aiDailyInsight;
    String? dailyRecommendation;
    String? todayTea;
    String? todayExercise;
    String? todayAcupoint;
    String? todayFood;
    String? solarWellnessAdvice;
    List<PersonalizedAction> personalActions = [];
    List<ConstitutionFood>? constitutionFoods;
    List<ConstitutionExercise>? constitutionExercises;

    // --- 1. 并行请求所有独立 API ---
    final results = await Future.wait([
      _safeGet('/api/v1/constitution/result/${userId ?? ''}'),          // 0: 体质
      _safeGet('/api/v1/recommendations/daily'),                         // 1: 每日推荐
      _safeGet('/api/v1/exercise/daily'),                                // 2: 每日运动
      _safeGet('/api/v1/tea/daily'),                                     // 3: 今日茶饮
      _safeGet('/api/v1/food-therapy/recommend'),                        // 4: 食疗推荐
      _safeGet('/api/v1/ai/daily-insight'),                              // 5: AI洞察
      _safeGet('/api/v1/acupoints/daily'),                               // 6: 每日穴位
      _safeGet('/api/v1/solar-wellness/daily-advice'),                   // 7: 时令养生
    ]);

    // --- 2. 解析体质 ---
    final conData = results[0];
    if (conData != null) {
      constitutionType = conData['type']?.toString() ?? conData['constitution_type']?.toString();
      constitutionName = conData['name']?.toString() ?? conData['type_name']?.toString();
      constitutionSummary = conData['summary']?.toString() ?? conData['description']?.toString();
    }

    // --- 3. 每日推荐 → personalActions ---
    final recData = results[1];
    if (recData != null) {
      final items = recData['recommendations'] ?? recData['items'] ?? recData['data'];
      if (items is List) {
        personalActions = items.map<PersonalizedAction?>((e) {
          if (e is! Map) return null;
          return PersonalizedAction(
            title: e['title']?.toString() ?? '',
            description: e['description']?.toString() ?? e['content']?.toString() ?? '',
            iconHint: e['icon']?.toString(),
          );
        }).where((a) => a != null && a.title.isNotEmpty).cast<PersonalizedAction>().toList();
      }
      dailyRecommendation = recData['text']?.toString() ?? recData['summary']?.toString();
    }

    // --- 4. 每日运动 ---
    final exData = results[2];
    if (exData != null) {
      todayExercise = exData['name']?.toString() ??
          exData['title']?.toString() ??
          exData['exercise']?.toString();
      if (todayExercise == null && exData['data'] is Map) {
        final d = exData['data'] as Map;
        todayExercise = d['name']?.toString() ?? d['title']?.toString();
      }
    }

    // --- 5. 今日茶饮 ---
    final teaData = results[3];
    if (teaData != null) {
      todayTea = teaData['name']?.toString() ??
          teaData['title']?.toString() ??
          teaData['tea']?.toString();
      if (todayTea == null && teaData['data'] is Map) {
        final d = teaData['data'] as Map;
        todayTea = d['name']?.toString() ?? d['title']?.toString();
      }
    }

    // --- 6. 食疗推荐 ---
    final foodData = results[4];
    if (foodData != null) {
      todayFood = foodData['name']?.toString() ??
          foodData['title']?.toString() ??
          foodData['food']?.toString();
      if (todayFood == null && foodData['data'] is Map) {
        final d = foodData['data'] as Map;
        todayFood = d['name']?.toString() ?? d['title']?.toString();
      }
    }

    // --- 7. AI 洞察 ---
    final aiData = results[5];
    if (aiData != null) {
      aiDailyInsight = aiData['text']?.toString() ??
          aiData['insight']?.toString() ??
          aiData['content']?.toString();
    }

    // --- 8. 每日穴位 ---
    final acuData = results[6];
    if (acuData != null) {
      todayAcupoint = acuData['name']?.toString() ??
          acuData['title']?.toString() ??
          acuData['acupoint']?.toString();
      if (todayAcupoint == null && acuData['data'] is Map) {
        final d = acuData['data'] as Map;
        todayAcupoint = d['name']?.toString() ?? d['title']?.toString();
      }
    }

    // --- 9. 时令养生 ---
    final solarData = results[7];
    if (solarData != null) {
      solarWellnessAdvice = solarData['advice']?.toString() ??
          solarData['text']?.toString() ??
          solarData['content']?.toString();
    }

    // --- 10. 体质专属食物 & 运动（需要体质类型） ---
    if (constitutionType != null && constitutionType.isNotEmpty) {
      final typeName = constitutionName ?? constitutionType;
      final constResults = await Future.wait([
        _safeGet('/api/v1/constitution/$typeName/foods'),
        _safeGet('/api/v1/constitution/$typeName/exercises'),
      ]);

      final foodsData = constResults[0];
      if (foodsData != null) {
        final items = foodsData['foods'] ?? foodsData['items'] ?? foodsData['data'];
        if (items is List) {
          constitutionFoods = items.map<ConstitutionFood?>((e) {
            if (e is! Map) return null;
            return ConstitutionFood(
              name: e['name']?.toString() ?? '',
              category: e['category']?.toString(),
              reason: e['reason']?.toString() ?? e['description']?.toString(),
            );
          }).where((f) => f != null && f.name.isNotEmpty).cast<ConstitutionFood>().toList();
        }
      }

      final exercisesData = constResults[1];
      if (exercisesData != null) {
        final items = exercisesData['exercises'] ?? exercisesData['items'] ?? exercisesData['data'];
        if (items is List) {
          constitutionExercises = items.map<ConstitutionExercise?>((e) {
            if (e is! Map) return null;
            return ConstitutionExercise(
              name: e['name']?.toString() ?? '',
              description: e['description']?.toString(),
            );
          }).where((e) => e != null && e.name.isNotEmpty).cast<ConstitutionExercise>().toList();
        }
      }
    }

    return PersonalizedData(
      constitutionType: constitutionType,
      constitutionName: constitutionName,
      constitutionSummary: constitutionSummary,
      aiDailyInsight: aiDailyInsight,
      dailyRecommendation: dailyRecommendation,
      todayTea: todayTea,
      todayExercise: todayExercise,
      todayAcupoint: todayAcupoint,
      todayFood: todayFood,
      solarWellnessAdvice: solarWellnessAdvice,
      personalActions: personalActions,
      constitutionFoods: constitutionFoods,
      constitutionExercises: constitutionExercises,
    );
  }

  /// 安全 GET 请求，失败返回 null
  static Future<Map<String, dynamic>?> _safeGet(String path) async {
    try {
      final response = await _dio.get(path);
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }
}
