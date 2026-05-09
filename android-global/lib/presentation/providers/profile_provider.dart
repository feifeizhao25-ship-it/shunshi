import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/user.dart';
import '../../../data/storage/storage_manager.dart';

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
        id: 'guest',
        email: '',
        name: 'Guest',
        subscription: SubscriptionTier.free,
      ),
    ),
  ) {
    loadProfile();
  }
  
  /// Load profile from local storage first, then optionally refresh from API
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // 1. Try to load from StorageManager (saved during login)
      final userInfo = StorageManager.user.getUserInfo();
      if (userInfo != null) {
        final user = _userFromStorage(userInfo);
        state = state.copyWith(
          user: user,
          isLoading: false,
        );
        return;
      }
      
      // 2. Check if logged in — if so, try /auth/me
      if (StorageManager.user.isLoggedIn()) {
        // Will be refreshed via API when the user navigates to profile
        // For now, use stored data or defaults
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? 'guest';
        state = state.copyWith(
          user: User(
            id: userId,
            email: '',
            name: 'User',
            subscription: SubscriptionTier.free,
          ),
          isLoading: false,
        );
        return;
      }
      
      // 3. Not logged in — show guest
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile',
      );
    }
  }
  
  User _userFromStorage(Map<String, dynamic> info) {
    SubscriptionTier tier = SubscriptionTier.free;
    final plan = info['subscription_plan'] ?? info['subscription'] ?? 'free';
    switch (plan.toString().toLowerCase()) {
      case 'serenity':
      case 'premium':
        tier = SubscriptionTier.serenity;
        break;
      case 'harmony':
        tier = SubscriptionTier.harmony;
        break;
      case 'family':
        tier = SubscriptionTier.family;
        break;
    }
    
    return User(
      id: info['id']?.toString() ?? 'guest',
      email: info['email']?.toString() ?? '',
      name: info['name']?.toString() ?? info['displayName']?.toString(),
      avatarUrl: info['avatar_url']?.toString() ?? info['photoUrl']?.toString(),
      country: info['country']?.toString(),
      subscription: tier,
      createdAt: info['created_at'] != null 
          ? DateTime.tryParse(info['created_at'].toString()) 
          : null,
    );
  }
  
  void updateName(String name) {
    state = state.copyWith(
      user: state.user.copyWith(name: name),
    );
  }
  
  /// Update profile from API response
  void updateFromApi(Map<String, dynamic> data) {
    final user = _userFromStorage(data);
    state = state.copyWith(user: user);
  }
  
  Future<void> refreshProfile() async {
    await loadProfile();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
