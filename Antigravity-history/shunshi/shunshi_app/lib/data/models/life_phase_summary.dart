import 'package:json_annotation/json_annotation.dart';

part 'life_phase_summary.g.dart';

/// 生命阶段摘要 - 仅内部使用，不外显
@JsonSerializable()
class LifePhaseSummary {
  final String phase;
  final String summary;
  final List<String> keywords;
  final DateTime updatedAt;

  const LifePhaseSummary({
    required this.phase,
    required this.summary,
    this.keywords = const [],
    required this.updatedAt,
  });

  factory LifePhaseSummary.fromJson(Map<String, dynamic> json) =>
      _$LifePhaseSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$LifePhaseSummaryToJson(this);
}
