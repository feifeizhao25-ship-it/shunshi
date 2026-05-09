/// SEASONS Home Hub — wired to real API
/// English: "Digital Sanctuary" brand, calm minimal
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../data/storage/storage_manager.dart';
import '../../../design_system/theme.dart';
import '../solar/widgets/solar_wellness_card.dart';
import '../../../core/theme/app_localizations.dart';

class SeasonsHomeV2 extends StatefulWidget {
  const SeasonsHomeV2({super.key});

  @override
  State<SeasonsHomeV2> createState() => _SeasonsHomeV2State();
}

class _SeasonsHomeV2State extends State<SeasonsHomeV2> {
  static const _baseUrl = 'http://116.62.32.43:4000';
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  ));

  String _greeting = 'Good Morning';
  String _season = 'Spring';
  String _timeOfDay = '';
  String _wisdomTitle = 'Nurturing Renewal';
  String _wisdomBody = 'Focus on light, bitter greens and mindful movement to align with the awakening earth.';
  String _companionTip = 'Welcome to SEASONS. How are you feeling today?';
  List<Map<String, dynamic>> _libraryItems = [];
  Map<String, dynamic> _followUp = {};
  bool _hasFollowUp = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _dio.get('/api/v1/intl/greeting'),
        _dio.get('/api/v1/intl/home/dashboard'),
        _dio.get('/api/v1/intl/contents/recommend', queryParameters: {'limit': 3}),
        _dio.get('/api/v1/followup/due', queryParameters: {'user_id': StorageManager.user.getUserId() ?? 'guest', 'limit': 1}),
      ]);

      if (!mounted) return;

      // Greeting
      final greetingData = results[0].data;
      if (greetingData is Map) {
        _greeting = greetingData['greeting'] ?? _greeting;
        _season = greetingData['season'] ?? _season;
      }

      // Dashboard
      final dashData = results[1].data;
      if (dashData is Map && dashData['data'] is Map) {
        final d = dashData['data'] is Map ? dashData['data'] as Map : (dashData.containsKey('daily_ritual') ? dashData : {});
        if (dashData.containsKey('greeting')) {
          _greeting = dashData['greeting']?.toString() ?? _greeting;
        }
        _wisdomTitle = d['theme']?.toString() ?? dashData['theme']?.toString() ?? _wisdomTitle;
        _wisdomBody = d['daily_insight']?.toString() ?? dashData['daily_insight']?.toString() ?? _wisdomBody;
        final ritual = d['daily_ritual'] is Map ? d['daily_ritual'] : dashData['daily_ritual'];
        if (ritual is Map && ritual['nutrition_tip'] != null) {
          _companionTip = ritual['nutrition_tip'].toString();
        } else {
          _companionTip = d['daily_tip']?.toString() ?? dashData['daily_insight']?.toString() ?? _companionTip;
        }
        if (dashData['time_of_day'] != null) _timeOfDay = dashData['time_of_day'].toString();
        _season = dashData['season']?.toString() ?? _season;
      }

      // Contents
      final contentData = results[2].data;
      if (contentData is Map && contentData['data'] is List) {
        _libraryItems = (contentData['data'] as List).cast<Map<String, dynamic>>();
      }

      // Follow-up
      if (results.length > 3) {
        final followupRes = results[3].data;
        if (followupRes is Map && followupRes['due_followups'] is List) {
          final due = (followupRes['due_followups'] as List);
          if (due.isNotEmpty) {
            _followUp = Map<String, dynamic>.from(due.first);
            _hasFollowUp = true;
          }
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  IconData _iconForCategory(String? category) {
    switch (category) {
      case 'sleep': return Icons.bedtime;
      case 'nutrition': return Icons.restaurant;
      case 'movement': return Icons.self_improvement;
      case 'mindfulness': return Icons.spa;
      case 'seasonal': return Icons.eco;
      default: return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF533afd)))
          : RefreshIndicator(
              color: const Color(0xFF533afd),
              onRefresh: _fetchData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(children: [
                          const Icon(Icons.menu, color: Color(0xFF533afd)),
                          const Spacer(),
                          Text('SEASONS', style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF533afd),
                          )),
                          const Spacer(),
                          const SizedBox(width: 24),
                        ]),
                      ),
                    ),
                  ),

                  // Greeting
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(AppLocalizations.of(context).t('home_todays_rhythm'), style: TextStyle(
                          fontSize: 14, color: ShunShiColors.textTertiary, fontWeight: FontWeight.w500,
                        )),
                        const SizedBox(height: 4),
                        Text(_greeting, style: TextStyle(
                          fontFamily: ShunShiTypography.serifFamily,
                          fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
                        )),
                        Text("It's ${_seasonDisplayName(_season)}.", style: TextStyle(
                          fontSize: 16, color: ShunShiColors.textSecondary,
                        )),
                      ]),
                    ),
                  ),

                  // Seasonal Wisdom Card
                  SliverToBoxAdapter(
                    child: SolarWellnessCard(),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(AppLocalizations.of(context).t('home_seasonal_wisdom'), style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text(_wisdomTitle, style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                          )),
                          const SizedBox(height: 6),
                          Text(_wisdomBody,
                            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Text(AppLocalizations.of(context).t('home_explore_principle'), style: TextStyle(fontSize: 13, color: Color(0xFFE4C285), fontWeight: FontWeight.w500)),
                            Icon(Icons.arrow_forward, size: 14, color: Color(0xFFE4C285)),
                          ]),
                        ]),
                      ),
                    ),
                  ),

                  // Follow-up reminder
                  if (_hasFollowUp) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF533afd).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: const Color(0xFF533afd).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.notifications_active, color: Color(0xFF533afd), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(AppLocalizations.of(context).t('home_gentle_reminder'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF533afd))),
                              const SizedBox(height: 2),
                              Text(_followUp['title']?.toString() ?? _followUp['description']?.toString() ?? '', style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ])),
                            Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
                          ]),
                        ),
                      ),
                    ),
                  ],

                  // SEASONS Companion
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ShunShiColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF533afd).withOpacity(0.15)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: const Color(0xFF533afd).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.auto_awesome, color: Color(0xFF533afd), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(AppLocalizations.of(context).t('home_seasons_companion'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                            Text('"$_companionTip"',
                              style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary, height: 1.4)),
                          ])),
                        ]),
                      ),
                    ),
                  ),

                  // Quick Rituals
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Text(AppLocalizations.of(context).t('home_quick_rituals'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                      child: Row(children: [
                        Expanded(child: _buildRitualCard(Icons.edit_note, 'Daily Reflection', 'Journaling')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildRitualCard(Icons.self_improvement, 'Current Practice', 'Morning Yoga \u00b7 15m')),
                      ]),
                    ),
                  ),

                  // Seasonal Library
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(children: [
                        Text(AppLocalizations.of(context).t('home_seasonal_library'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                        const Spacer(),
                        Text(AppLocalizations.of(context).t('home_see_all'), style: TextStyle(fontSize: 13, color: const Color(0xFF533afd), fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                      child: _libraryItems.isEmpty
                          ? _buildLibraryItem('Explore seasonal content', 'Wellness Library', Icons.explore)
                          : Column(
                              children: _libraryItems.map((item) => _buildLibraryItem(
                                item['title'] ?? 'Untitled',
                                item['category'] ?? 'General',
                                _iconForCategory(item['category']),
                              )).toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _seasonDisplayName(String season) {
    const names = {
      'spring': 'Mid-Spring', 'summer': 'Summer', 'autumn': 'Autumn', 'winter': 'Winter',
    };
    return names[season.toLowerCase()] ?? season;
  }

  Widget _buildRitualCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF533afd), size: 22),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
        Text(subtitle, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
      ]),
    );
  }

  Widget _buildLibraryItem(String title, String category, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFF533afd).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF533afd), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary)),
            Text(category, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
          ])),
          Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
        ]),
      ),
    );
  }
}
