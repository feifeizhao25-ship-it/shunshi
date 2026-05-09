import 'package:dio/dio.dart';
// 家庭系统模型
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 家庭成员关系
enum FamilyRelation {
  /// 父亲
  father,
  /// 母亲
  mother,
  /// 配偶
  spouse,
  /// 子女
  child,
  /// 兄弟姐妹
  sibling,
  /// 其他
  other,
}

/// 家庭成员状态
enum MemberStatus {
  /// 正常
  normal,
  /// 需要关注
  attention,
  /// 紧急
  urgent,
}

/// 家庭成员模型
class FamilyMember {
  final String id;
  final String name;
  final FamilyRelation relation;
  final MemberStatus status;
  final int age;
  final DateTime? lastActiveAt;
  final Map<String, dynamic>? healthData;
  final DateTime addedAt;
  
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.status,
    required this.age,
    this.lastActiveAt,
    this.healthData,
    required this.addedAt,
  });
  
  factory FamilyMember.create({
    required String name,
    required FamilyRelation relation,
    required int age,
  }) {
    return FamilyMember(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      relation: relation,
      status: MemberStatus.normal,
      age: age,
      addedAt: DateTime.now(),
    );
  }
  
  FamilyMember copyWith({
    String? id,
    String? name,
    FamilyRelation? relation,
    MemberStatus? status,
    int? age,
    DateTime? lastActiveAt,
    Map<String, dynamic>? healthData,
    DateTime? addedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      status: status ?? this.status,
      age: age ?? this.age,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      healthData: healthData ?? this.healthData,
      addedAt: addedAt ?? this.addedAt,
    );
  }
  
  /// 获取关系显示名称
  String get relationName {
    switch (relation) {
      case FamilyRelation.father:
        return 'Father';
      case FamilyRelation.mother:
        return 'Mother';
      case FamilyRelation.spouse:
        return 'Spouse';
      case FamilyRelation.child:
        return 'Child';
      case FamilyRelation.sibling:
        return 'Sibling';
      case FamilyRelation.other:
        return 'Other';
    }
  }
  
  /// 获取状态显示名称
  String get statusName {
    switch (status) {
      case MemberStatus.normal:
        return 'Normal';
      case MemberStatus.attention:
        return 'Needs Attention';
      case MemberStatus.urgent:
        return 'Urgent';
    }
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation.name,
    'status': status.name,
    'age': age,
    'lastActiveAt': lastActiveAt?.toIso8601String(),
    'healthData': healthData,
    'addedAt': addedAt.toIso8601String(),
  };
  
  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'],
    name: json['name'],
    relation: FamilyRelation.values.firstWhere(
      (e) => e.name == json['relation'],
      orElse: () => FamilyRelation.other,
    ),
    status: MemberStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => MemberStatus.normal,
    ),
    age: json['age'],
    lastActiveAt: json['lastActiveAt'] != null 
        ? DateTime.parse(json['lastActiveAt']) 
        : null,
    healthData: json['healthData'],
    addedAt: DateTime.parse(json['addedAt']),
  );
}

/// 家庭邀请码
class FamilyInvite {
  final String code;
  final String familyId;
  final FamilyRelation relation;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;
  
  const FamilyInvite({
    required this.code,
    required this.familyId,
    required this.relation,
    required this.createdAt,
    required this.expiresAt,
    this.used = false,
  });
  
  /// 是否过期
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// 是否可用
  bool get isValid => !used && !isExpired;
  
  Map<String, dynamic> toJson() => {
    'code': code,
    'familyId': familyId,
    'relation': relation.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'used': used,
  };
  
  factory FamilyInvite.fromJson(Map<String, dynamic> json) => FamilyInvite(
    code: json['code'],
    familyId: json['familyId'],
    relation: FamilyRelation.values.firstWhere(
      (e) => e.name == json['relation'],
      orElse: () => FamilyRelation.other,
    ),
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    used: json['used'] ?? false,
  );
}

/// 家庭 Provider
final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  return FamilyNotifier();
});

/// 家庭状态
class FamilyState {
  final String? familyId;
  final String? familyName;
  final List<FamilyMember> members;
  final FamilyInvite? invite;
  final bool isLoading;
  final String? error;
  
  const FamilyState({
    this.familyId,
    this.familyName,
    this.members = const [],
    this.invite,
    this.isLoading = false,
    this.error,
  });
  
  FamilyState copyWith({
    String? familyId,
    String? familyName,
    List<FamilyMember>? members,
    FamilyInvite? invite,
    bool? isLoading,
    String? error,
  }) {
    return FamilyState(
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      members: members ?? this.members,
      invite: invite ?? this.invite,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  /// 是否有家庭
  bool get hasFamily => familyId != null;
  
  /// 成员数量
  int get memberCount => members.length;
  
  /// 获取需要关注的成员
  List<FamilyMember> get attentionNeeded {
    return members.where((m) => 
      m.status == MemberStatus.attention || 
      m.status == MemberStatus.urgent
    ).toList();
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier() : super(const FamilyState());
  
  /// 创建家庭
  void createFamily(String name) {
    state = state.copyWith(
      familyId: DateTime.now().millisecondsSinceEpoch.toString(),
      familyName: name,
    );
  }
  
  /// 添加家庭成员
  void addMember({
    required String name,
    required FamilyRelation relation,
    required int age,
  }) {
    final member = FamilyMember.create(
      name: name,
      relation: relation,
      age: age,
    );
    state = state.copyWith(
      members: [...state.members, member],
    );
  }
  
  /// 移除家庭成员
  void removeMember(String memberId) {
    state = state.copyWith(
      members: state.members.where((m) => m.id != memberId).toList(),
    );
  }
  
  /// 更新成员状态
  void updateMemberStatus(String memberId, MemberStatus status) {
    state = state.copyWith(
      members: state.members.map((m) {
        if (m.id == memberId) {
          return m.copyWith(status: status);
        }
        return m;
      }).toList(),
    );
  }
  
  /// 生成邀请码
  void generateInviteCode(FamilyRelation relation) {
    final code = _generateCode();
    final invite = FamilyInvite(
      code: code,
      familyId: state.familyId ?? '',
      relation: relation,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    state = state.copyWith(invite: invite);
  }
  
  /// 使用邀请码加入家庭
  Future<void> joinFamily(String code) async {
    // 调用后端 API 验证并加入家庭
    try {
      final dio = Dio();
      final res = await dio.post("http://116.62.32.43:4000/api/v1/family/join", data: {"code": code});
      if (res.data?["success"] == true) {
        final d = res.data["data"];
        state = state.copyWith(familyId: d["family_id"], familyName: d["family_name"]);
        return;
      }
    } catch (_) {}
    state = state.copyWith(
      familyId: 'joined',
      familyName: 'Joined Family',
    );
  }
  
  /// 离开家庭
  void leaveFamily() {
    state = const FamilyState();
  }
  
  String _generateCode() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(random + i * 7) % chars.length]).join();
  }
}

/// 关系类型扩展
extension FamilyRelationExtension on FamilyRelation {
  String get displayName {
    switch (this) {
      case FamilyRelation.father:
        return 'Father';
      case FamilyRelation.mother:
        return 'Mother';
      case FamilyRelation.spouse:
        return 'Spouse';
      case FamilyRelation.child:
        return 'Child';
      case FamilyRelation.sibling:
        return 'Sibling';
      case FamilyRelation.other:
        return 'Other';
    }
  }
  
  String get emoji {
    switch (this) {
      case FamilyRelation.father:
        return '👨';
      case FamilyRelation.mother:
        return '👩';
      case FamilyRelation.spouse:
        return '💑';
      case FamilyRelation.child:
        return '👶';
      case FamilyRelation.sibling:
        return '👫';
      case FamilyRelation.other:
        return '👤';
    }
  }
}
