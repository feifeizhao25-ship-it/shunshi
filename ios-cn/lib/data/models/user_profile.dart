// 用户生命周期识别服务
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 用户生命周期阶段
enum LifeStage {
  /// 探索期 (18-25岁)
  exploration,
  
  /// 压力期 (25-40岁)
  pressure,
  
  /// 健康期 (40-60岁)
  health,
  
  /// 陪伴期 (60岁以上)
  companionship,
}

/// 用户信息
class UserProfile {
  final String name;
  final int age;
  final LifeStage lifeStage;
  final DateTime birthday;
  final String gender;
  
  const UserProfile({
    required this.name,
    required this.age,
    required this.lifeStage,
    required this.birthday,
    this.gender = 'unknown',
  });
  
  factory UserProfile.fromAge(int age) {
    return UserProfile(
      name: '用户',
      age: age,
      lifeStage: LifeStageHelper.fromAge(age),
      birthday: DateTime.now().subtract(Duration(days: age * 365)),
    );
  }
  
  factory UserProfile.fromBirthday(DateTime birthday) {
    final age = LifeStageHelper.calculateAge(birthday);
    return UserProfile(
      name: '用户',
      age: age,
      lifeStage: LifeStageHelper.fromAge(age),
      birthday: birthday,
    );
  }
  
  UserProfile copyWith({
    String? name,
    int? age,
    LifeStage? lifeStage,
    DateTime? birthday,
    String? gender,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      lifeStage: lifeStage ?? this.lifeStage,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
    );
  }
  
  /// 获取阶段名称
  String get stageName => LifeStageHelper.getName(lifeStage);
  
  /// 获取阶段描述
  String get stageDescription => LifeStageHelper.getDescription(lifeStage);
  
  /// 获取首页模块
  List<String> get homeModules => LifeStageHelper.getHomeModules(lifeStage);
}

/// 生命周期阶段辅助类
class LifeStageHelper {
  /// 从年龄获取阶段
  static LifeStage fromAge(int age) {
    if (age < 25) return LifeStage.exploration;
    if (age < 40) return LifeStage.pressure;
    if (age < 60) return LifeStage.health;
    return LifeStage.companionship;
  }
  
  /// 计算年龄
  static int calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || 
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }
  
  /// 获取阶段名称
  static String getName(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return '探索期';
      case LifeStage.pressure:
        return '压力期';
      case LifeStage.health:
        return '健康期';
      case LifeStage.companionship:
        return '陪伴期';
    }
  }
  
  /// 获取阶段描述
  static String getDescription(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return '生活节律与情绪陪伴';
      case LifeStage.pressure:
        return '压力与健康管理';
      case LifeStage.health:
        return '养生与体质调理';
      case LifeStage.companionship:
        return '生活陪伴';
    }
  }
  
  /// 获取首页模块
  static List<String> getHomeModules(LifeStage stage) {
    switch (stage) {
      case LifeStage.exploration:
        return ['今日节律', 'AI聊天', '睡眠建议'];
      case LifeStage.pressure:
        return ['今日洞察', '三件小事', '跟进提醒'];
      case LifeStage.health:
        return ['节气养生', '今日养生', '体质调理'];
      case LifeStage.companionship:
        return ['今日一句', '语音聊天', '今日建议'];
    }
  }
}

/// 用户配置 Provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null);
  
  /// 设置用户生日
  void setBirthday(DateTime birthday) {
    final profile = UserProfile.fromBirthday(birthday);
    state = profile;
  }
  
  /// 设置年龄
  void setAge(int age) {
    final profile = UserProfile.fromAge(age);
    state = profile;
  }
  
  /// 更新用户资料
  void updateProfile({
    String? name,
    DateTime? birthday,
    String? gender,
  }) {
    if (state == null) {
      if (birthday != null) {
        state = UserProfile.fromBirthday(birthday).copyWith(
          name: name,
          gender: gender,
        );
      } else if (name != null) {
        state = UserProfile.fromAge(25).copyWith(
          name: name,
          gender: gender,
        );
      }
    } else {
      final age = birthday != null 
          ? LifeStageHelper.calculateAge(birthday)
          : state!.age;
      state = state!.copyWith(
        name: name,
        birthday: birthday,
        age: age,
        lifeStage: LifeStageHelper.fromAge(age),
        gender: gender,
      );
    }
  }
  
  /// 清除资料
  void clear() {
    state = null;
  }
}
