import 'care_status.dart';

/// ──────────────────────────────────────────────────
/// SolarTerm — 节气实体
/// 映射自 iOS SolarTerm.swift
/// ──────────────────────────────────────────────────

enum Season {
  spring,
  summer,
  autumn,
  winter;

  String get displayName {
    switch (this) {
      case Season.spring: return '春';
      case Season.summer: return '夏';
      case Season.autumn: return '秋';
      case Season.winter: return '冬';
    }
  }

  factory Season.fromString(String? value) {
    switch (value) {
      case 'spring': return Season.spring;
      case 'summer': return Season.summer;
      case 'autumn': return Season.autumn;
      case 'winter': return Season.winter;
      default: return Season.spring;
    }
  }
}

/// 三候
class SanHou {
  final int index;
  final String name;
  final String description;
  final int startDay;
  final int endDay;
  final bool isCurrent;

  const SanHou({
    required this.index,
    required this.name,
    required this.description,
    required this.startDay,
    required this.endDay,
    this.isCurrent = false,
  });

  factory SanHou.fromJson(Map<String, dynamic> json) => SanHou(
        index: json['index'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        startDay: json['start_day'] as int? ?? 0,
        endDay: json['end_day'] as int? ?? 0,
        isCurrent: json['is_current'] as bool? ?? false,
      );
}

/// 诗词
class Poem {
  final String title;
  final String author;
  final String content;
  final String dynasty;

  const Poem({
    required this.title,
    required this.author,
    required this.content,
    required this.dynasty,
  });

  factory Poem.fromJson(Map<String, dynamic> json) => Poem(
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        content: json['content'] as String? ?? '',
        dynasty: json['dynasty'] as String? ?? '',
      );
}

/// 养生建议
class WellnessAdvice {
  final List<String> diet;
  final List<String> drink;
  final List<String> living;
  final List<String> exercise;
  final List<String> acupoint;
  final List<String> emotion;

  const WellnessAdvice({
    this.diet = const [],
    this.drink = const [],
    this.living = const [],
    this.exercise = const [],
    this.acupoint = const [],
    this.emotion = const [],
  });

  factory WellnessAdvice.fromJson(Map<String, dynamic> json) => WellnessAdvice(
        diet: _toStringList(json['diet']),
        drink: _toStringList(json['drink']),
        living: _toStringList(json['living']),
        exercise: _toStringList(json['exercise']),
        acupoint: _toStringList(json['acupoint']),
        emotion: _toStringList(json['emotion']),
      );

  static List<String> _toStringList(dynamic value) =>
      (value as List?)?.map((e) => e as String).toList() ?? [];
}

/// 节气主实体
class SolarTerm {
  final String id;
  final String name;
  final String nameEn;
  final String namePinyin;
  final int index;
  final int year;
  final Season season;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final List<SanHou> sanHou;
  final String? healthPrinciple;
  final List<String> keywords;
  final List<String> yi;  // 宜
  final List<String> ji;  // 忌
  final Poem? poem;
  final List<String> customs;
  final WellnessAdvice? wellnessAdvice;
  final String? iconName;
  final String? colorHex;

  const SolarTerm({
    required this.id,
    required this.name,
    required this.nameEn,
    this.namePinyin = '',
    required this.index,
    required this.year,
    required this.season,
    required this.startDate,
    required this.endDate,
    this.description = '',
    this.sanHou = const [],
    this.healthPrinciple,
    this.keywords = const [],
    this.yi = const [],
    this.ji = const [],
    this.poem,
    this.customs = const [],
    this.wellnessAdvice,
    this.iconName,
    this.colorHex,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  SanHou? get currentSanHou =>
      sanHou.where((s) => s.isCurrent).firstOrNull;

  factory SolarTerm.fromJson(Map<String, dynamic> json) => SolarTerm(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        namePinyin: json['name_pinyin'] as String? ?? '',
        index: json['index'] as int? ?? 0,
        year: json['year'] as int? ?? DateTime.now().year,
        season: Season.fromString(json['season'] as String?),
        startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ??
            DateTime.now(),
        endDate: DateTime.tryParse(json['end_date'] as String? ?? '') ??
            DateTime.now(),
        description: json['description'] as String? ?? '',
        sanHou: (json['san_hou'] as List?)
                ?.map((e) => SanHou.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        healthPrinciple: json['health_principle'] as String?,
        keywords: (json['keywords'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        yi: (json['yi'] as List?)?.map((e) => e as String).toList() ?? [],
        ji: (json['ji'] as List?)?.map((e) => e as String).toList() ?? [],
        poem: json['poem'] != null
            ? Poem.fromJson(json['poem'] as Map<String, dynamic>)
            : null,
        customs: (json['customs'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        wellnessAdvice: json['wellness_advice'] != null
            ? WellnessAdvice.fromJson(
                json['wellness_advice'] as Map<String, dynamic>)
            : null,
        iconName: json['icon_name'] as String?,
        colorHex: json['color_hex'] as String?,
      );
}

/// DailyPlan — 今日计划
class DailyPlan {
  final String planDate;
  final String greeting;
  final List<DailyPlanStep> steps;
  final CareStatus careStatus;
  final String tone;
  final SafetyFlag safetyFlag;

  const DailyPlan({
    required this.planDate,
    required this.greeting,
    this.steps = const [],
    this.careStatus = CareStatus.stable,
    this.tone = 'warm',
    this.safetyFlag = SafetyFlag.green,
  });

  /// 降级 fallback
  factory DailyPlan.fallback() => DailyPlan(
        planDate: DateTime.now().toIso8601String().substring(0, 10),
        greeting: '今天也要好好照顾自己哦。',
        steps: [
          const DailyPlanStep(
            id: 'fallback_1',
            title: '晨起润肠',
            detail: '一杯温水，开启美好的一天',
            time: '07:00',
            dimension: 'diet',
          ),
          const DailyPlanStep(
            id: 'fallback_2',
            title: '午间舒展',
            detail: '起身活动5分钟，放松肩颈',
            time: '12:00',
            dimension: 'exercise',
          ),
          const DailyPlanStep(
            id: 'fallback_3',
            title: '晚间放松',
            detail: '温水泡脚15分钟，安心入睡',
            time: '21:00',
            dimension: 'living',
          ),
        ],
      );

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
        planDate: json['plan_date'] as String? ?? '',
        greeting: json['greeting'] as String? ?? '',
        steps: (json['steps'] as List?)
                ?.map(
                    (e) => DailyPlanStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        careStatus:
            CareStatus.fromString(json['care_status'] as String?),
        tone: json['tone'] as String? ?? 'warm',
        safetyFlag: SafetyFlag.fromString(json['safety_flag'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'plan_date': planDate,
        'greeting': greeting,
        'steps': steps.map((e) => e.toJson()).toList(),
        'care_status': careStatus.toJson(),
        'tone': tone,
        'safety_flag': safetyFlag.toJson(),
      };
}

class DailyPlanStep {
  final String id;
  final String title;
  final String detail;
  final String? time;
  final String? dimension; // diet / exercise / living / emotion / acupoint
  final String? action;
  final bool isCompleted;

  const DailyPlanStep({
    required this.id,
    required this.title,
    required this.detail,
    this.time,
    this.dimension,
    this.action,
    this.isCompleted = false,
  });

  DailyPlanStep copyWith({bool? isCompleted}) => DailyPlanStep(
        id: id,
        title: title,
        detail: detail,
        time: time,
        dimension: dimension,
        action: action,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  factory DailyPlanStep.fromJson(Map<String, dynamic> json) => DailyPlanStep(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        time: json['time'] as String?,
        dimension: json['dimension'] as String?,
        action: json['action'] as String?,
        isCompleted: json['is_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'time': time,
        'dimension': dimension,
        'action': action,
        'is_completed': isCompleted,
      };
}

