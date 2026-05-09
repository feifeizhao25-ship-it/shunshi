import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user.dart';

class ProfileState {
  final User user;
  final int streakDays;
  final int reflectionsCount;
  final bool isLoading;
  final String? error;
  
  const ProfileState({
    required this.user,
    this.streakDays = 0,
    this.reflectionsCount = 0,
    this.isLoading = false,
    this.error,
  });
  
  ProfileState copyWith({
    User? user,
    int? streakDays,
    int? reflectionsCount,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      streakDays: streakDays ?? this.streakDays,
      reflectionsCount: reflectionsCount ?? this.reflectionsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(
    ProfileState(
      user: User(
        id: '1',
        email: 'user@example.com',
        name: 'User',
        subscription: SubscriptionTier.free,
      ),
    ),
  ) {
    loadProfile();
  }
  
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 200));
    
    state = state.copyWith(
      user: state.user.copyWith(
        name: 'Alex',
        country: 'US',
      ),
      streakDays: 7,
      reflectionsCount: 23,
      isLoading: false,
    );
  }
  
  void updateName(String name) {
    state = state.copyWith(
      user: state.user.copyWith(name: name),
    );
  }
  
  Future<void> refreshProfile() async {
    await loadProfile();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
