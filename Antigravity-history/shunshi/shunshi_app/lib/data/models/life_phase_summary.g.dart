// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'life_phase_summary.dart';

LifePhaseSummary _$LifePhaseSummaryFromJson(Map<String, dynamic> json) =>
    LifePhaseSummary(
      phase: json['phase'] as String,
      summary: json['summary'] as String,
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$LifePhaseSummaryToJson(LifePhaseSummary instance) =>
    <String, dynamic>{
      'phase': instance.phase,
      'summary': instance.summary,
      'keywords': instance.keywords,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
