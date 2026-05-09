import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Pages
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/onboarding/wellness_onboarding_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/home/ultimate_home_page.dart';
import '../../presentation/pages/home/daily_checkin_page.dart';
import '../../presentation/pages/home/wellness_dashboard_page.dart';
import '../../presentation/pages/chat_page.dart';
import '../../presentation/pages/discover/discover_page.dart';
import '../../presentation/pages/solar/solar_term_page_v2.dart';
import '../../presentation/pages/solar/solar_term_detail_page.dart';
import '../../presentation/pages/solar/solar_detail_page.dart';
import '../../presentation/pages/profile/profile_page_v2.dart';
import '../../presentation/pages/profile/profile_setup_page.dart';
import '../../presentation/pages/profile/privacy_page.dart';
import '../../presentation/pages/profile/family_invite_page.dart';
import '../../presentation/pages/settings/settings_page_v2.dart';
import '../../presentation/pages/settings/notification_settings_page.dart';
import '../../presentation/pages/constitution/constitution_test_v2.dart';
import '../../presentation/pages/constitution_report/constitution_report_page_v3.dart';
import '../../presentation/pages/wellness/wellness_category_page.dart';
import '../../presentation/pages/wellness/wellness_home_page.dart';
import '../../presentation/pages/wellness/constitution_page.dart';
import '../../presentation/pages/wellness/boundaries_page.dart';
import '../../presentation/pages/records/records_page_v2.dart';
import '../../presentation/pages/subscription/subscription_page_v2.dart';
import '../../presentation/pages/subscription/membership_center_page.dart';
import '../../presentation/pages/reflection/reflection_page.dart';
import '../../presentation/pages/community/community_page_v2.dart';
import '../../presentation/pages/achievement/achievement_page_v2.dart';
import '../../presentation/pages/diet/diet_recommend_page.dart';
import '../../presentation/pages/meridian/meridian_detail_page.dart';
import '../../presentation/pages/content/content_detail_page.dart';
import '../../presentation/pages/favorites/favorites_page.dart';
import '../../presentation/pages/search/global_search_page.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/pages/feedback/feedback_page.dart' as fb;
import '../../presentation/pages/family/family_page_v2.dart';
import '../../presentation/pages/family/family_home_page.dart';
import '../../presentation/pages/family/family_member_detail_page.dart';
import '../../presentation/pages/food/food_detail_page.dart';
import '../../presentation/pages/exercise/exercise_detail_page.dart';
import '../../presentation/pages/diary/diary_page_v2.dart';
import '../../presentation/pages/diary/diary_report_page.dart';
import '../../presentation/pages/diary/sleep_report_page.dart';
import '../../presentation/pages/about/about_page.dart';
import '../../presentation/pages/legal/terms_page.dart';
import '../../presentation/pages/legal/privacy_policy_page.dart';
import '../../presentation/widgets/shell/main_shell.dart';
import '../../presentation/pages/error/error_page.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // Splash handles its own redirect logic
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      GoRoute(path: '/onboarding-wellness', builder: (context, state) => const WellnessOnboardingPage()),

      // 全屏子页面
      GoRoute(path: '/reflection', builder: (context, state) => const ReflectionPage()),
      GoRoute(path: '/subscription', builder: (context, state) => const SubscriptionPageV2()),
      GoRoute(path: '/membership', builder: (context, state) => const MembershipCenterPage()),
      GoRoute(path: '/content/:id', builder: (context, state) {
        return ContentDetailPage(contentId: state.pathParameters['id']!);
      }),
      GoRoute(path: '/records', builder: (context, state) => const RecordsPageV2()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPageV2()),
      GoRoute(path: '/boundaries', builder: (context, state) => const BoundariesPage()),
      GoRoute(path: '/constitution', builder: (context, state) => const ConstitutionPage()),
      GoRoute(path: '/wellness-category/:type', builder: (context, state) {
        return WellnessCategoryPage(type: state.pathParameters['type'] ?? 'food_therapy');
      }),
      GoRoute(path: '/solar-term-detail/:name', builder: (context, state) {
        return SolarTermDetailPage(
          termName: state.pathParameters['name'] ?? '春分',
          season: state.uri.queryParameters['season'],
        );
      }),
      GoRoute(path: '/solar-wellness', builder: (context, state) => const SolarDetailPage()),
      GoRoute(path: '/family', builder: (context, state) => const FamilyPageV2()),
      GoRoute(path: '/food-detail', builder: (context, state) => const FoodDetailPage()),
      GoRoute(path: '/exercise-detail', builder: (context, state) => const ExerciseDetailPage()),
      GoRoute(path: '/constitution-test', builder: (context, state) => const ConstitutionTestV2()),
      GoRoute(path: '/diary', builder: (context, state) => const DiaryPageV2()),
      GoRoute(path: '/diary-report', builder: (context, state) => const DiaryReportPage()),
      GoRoute(path: '/sleep-report', builder: (context, state) => const SleepReportPage()),
      GoRoute(path: '/family-home', builder: (context, state) => const FamilyHomePage()),
      GoRoute(path: '/family-invite', builder: (context, state) => const FamilyInvitePage()),
      GoRoute(path: '/family-member/:id', builder: (context, state) {
        return FamilyMemberDetailPage(memberId: state.pathParameters['id']!);
      }),
      GoRoute(path: '/privacy', builder: (context, state) => const PrivacyPage()),
      GoRoute(path: '/daily-checkin', builder: (context, state) => const DailyCheckinPage()),
      GoRoute(path: '/wellness-dashboard', builder: (context, state) => const WellnessDashboardPage()),
      GoRoute(path: '/community', builder: (context, state) => const CommunityPageV2()),
      GoRoute(path: '/achievement', builder: (context, state) => const AchievementPageV2()),
      GoRoute(path: '/constitution-report', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ConstitutionReportPageV3(
          constitutionType: extra?['constitutionType'] as String?,
          scores: extra?['scores'] as Map<String, double>?,
        );
      }),
      GoRoute(path: '/diet-recommend', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DietRecommendPage(
          constitutionType: extra?['constitutionType'] as String?,
          season: extra?['season'] as String?,
        );
      }),
      GoRoute(path: '/content-detail', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ContentDetailPage(contentId: extra?['contentId'] as String? ?? '');
      }),
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesPage()),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
      GoRoute(path: '/search', builder: (context, state) => const GlobalSearchPage()),
      GoRoute(path: '/feedback', builder: (context, state) => const fb.FeedbackPage()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
      GoRoute(path: '/meridian-detail', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MeridianDetailPage(meridianId: extra?['meridianId'] as String? ?? '');
      }),
      GoRoute(path: '/discover', builder: (context, state) => const DiscoverPage()),
      GoRoute(path: '/notification-settings', builder: (context, state) => const NotificationSettingsPage()),
      GoRoute(path: '/feedback', builder: (context, state) => const fb.FeedbackPage()),
      GoRoute(path: '/terms-and-conditions', builder: (context, state) => const TermsPage()),
      GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyPage()),

      // Main Shell — 5 Tab: 聊天/今日/节气/养生/我的
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/chat', pageBuilder: (context, state) => const NoTransitionPage(child: ChatPage())),
          GoRoute(path: '/today', pageBuilder: (context, state) => const NoTransitionPage(child: UltimateHomePage())),
          GoRoute(path: '/solar', pageBuilder: (context, state) => const NoTransitionPage(child: SolarTermPageV2())),
          GoRoute(path: '/wellness', pageBuilder: (context, state) => const NoTransitionPage(child: WellnessHomePage())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePageV2())),
          // Legacy
          GoRoute(path: '/home', pageBuilder: (context, state) => const NoTransitionPage(child: UltimateHomePage())),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
}
