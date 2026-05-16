import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

/// SEASONS Home — Pixel-level clone of Apple Health + Calm structure.
///
/// STRUCTURE (STRICT):
/// 1. Greeting — dynamic, personal
/// 2. Primary Focus Card — ONE, big, clear
/// 3. Secondary Cards — MAX 2, smaller
/// 4. Bottom Nav — Home / AI / Insights / Profile
///
/// FORBIDDEN:
/// ❌ Multiple equal cards
/// ❌ Dashboard layout
/// ❌ Dense information
///
/// Goal: User understands everything in 3 seconds.
class HomePageIntl extends StatefulWidget {
  const HomePageIntl({super.key});
  @override
  State<HomePageIntl> createState() => _HomePageIntlState();
}

enum _PageState { loading, loaded, error, empty }

class _HomePageIntlState extends State<HomePageIntl> {
  final _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrls[0],
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 5),
  ));

  var _state = _PageState.loading;
  String? _error;

  // Data — kept minimal on purpose
  String _greeting = '';
  String _primaryTitle = '';
  String _primaryReason = '';
  String _primaryAction = '';
  String _primaryDuration = '';
  String _season = '';
  String _userName = 'Friend';
  String _hemisphere = 'north';
  String _secondary1Title = '';
  String _secondary1Subtitle = '';
  String _secondary2Title = '';
  String _secondary2Subtitle = '';
  String _selectedMood = '';
  bool _reflecting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Friend';
    _hemisphere = prefs.getString('hemisphere') ?? 'north';

    if (!(prefs.getBool('onboarding_completed') ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/onboarding');
      });
      return;
    }

    // Show cache instantly
    final cachedPrefs = await SharedPreferences.getInstance();
    final cachedGreeting = cachedPrefs.getString('cached_greeting') ?? '';
    if (cachedGreeting.isNotEmpty) {
      setState(() {
        _greeting = cachedGreeting;
        _season = cachedPrefs.getString('cached_season') ?? 'spring';
        _primaryTitle = cachedPrefs.getString('cached_primary_title') ?? '';
        _primaryReason = cachedPrefs.getString('cached_primary_reason') ?? '';
        _state = _PageState.loaded;
      });
    } else {
      if (mounted) setState(() { _state = _PageState.loading; _error = null; });
    }

    try {
      final res = await _dio.get('/api/v1/contents/recommend',
          queryParameters: {'hemisphere': _hemisphere, 'locale': 'en-US'});
      final d = res.data;
      if (!mounted) return;

      // Extract PRIMARY focus — only the first action
      final actions = List<Map<String, dynamic>>.from(d['actions'] ?? []);
      final suggestions = List<Map<String, dynamic>>.from(d['gentle_suggestions'] ?? []);
      final insight = d['daily_insight'] ?? d['insight'] ?? '';

      // Primary: first action OR first suggestion
      final primary = actions.isNotEmpty ? actions[0] :
                      (suggestions.isNotEmpty ? suggestions[0] : null);

      // Secondary: max 2
      final secondaries = [...actions.skip(1), ...suggestions.skip(primary == suggestions[0] ? 1 : 0)].take(2).toList();

      setState(() {
        _greeting = d['greeting'] ?? 'The light is changing.';
        _season = d['season'] ?? 'spring';
        _primaryTitle = primary?['title'] ?? 'Take a moment today';
        _primaryReason = primary?['why'] ?? insight.isNotEmpty ? insight : 'A small shift can change your day';
        _primaryAction = primary?['description'] ?? '';
        _primaryDuration = '${primary?['duration_min'] ?? 3} min';
        _secondary1Title = secondaries.isNotEmpty ? (secondaries[0]['title'] ?? '') : '';
        _secondary1Subtitle = secondaries.isNotEmpty ? '${secondaries[0]['duration_min'] ?? 3} min' : '';
        _secondary2Title = secondaries.length > 1 ? (secondaries[1]['title'] ?? '') : '';
        _secondary2Subtitle = secondaries.length > 1 ? '${secondaries[1]['duration_min'] ?? 3} min' : '';
        _state = _PageState.loaded;
      });

      // Cache
      try {
        await cachedPrefs.setString('cached_greeting', _greeting);
        await cachedPrefs.setString('cached_season', _season);
        await cachedPrefs.setString('cached_primary_title', _primaryTitle);
        await cachedPrefs.setString('cached_primary_reason', _primaryReason);
      } catch (_) {}

    } on DioException catch (e) {
      if (!mounted) return;
      final p = await SharedPreferences.getInstance();
      final cg = p.getString('cached_greeting') ?? '';
      if (cg.isNotEmpty && _state != _PageState.loaded) {
        setState(() {
          _greeting = cg;
          _season = p.getString('cached_season') ?? 'spring';
          _state = _PageState.loaded;
        });
        return;
      }
      setState(() { _state = _PageState.error; _error = _friendlyMsg(e); });
    } catch (_) {
      if (!mounted) return;
      setState(() { _state = _PageState.error; _error = 'Something went wrong.'; });
    }
  }

  String _friendlyMsg(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout => 'Taking a moment. Try again.',
    DioExceptionType.connectionError => 'No connection. Your data is safe.',
    _ => 'Something went wrong.',
  };

  Future<void> _reflect(String mood) async {
    if (_reflecting) return;
    setState(() { _selectedMood = mood; _reflecting = true; });
    try {
      await _dio.post('/api/v1/followup/quick/daily-checkin', data: {'mood': mood, 'energy': 3});
    } catch (_) {}
    if (mounted) setState(() { _selectedMood = ''; _reflecting = false; });
  }

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  // Design tokens — 8px grid system
  static const _spacing4 = 4.0;
  static const _spacing8 = 8.0;
  static const _spacing16 = 16.0;
  static const _spacing24 = 24.0;
  static const _spacing32 = 32.0;
  static const _radius16 = 16.0;
  static const _radius20 = 20.0;

  Color get _bg => _dark ? const Color(0xFF0A0A14) : const Color(0xFFFAFAFA);
  Color get _surface => _dark ? const Color(0xFF161622) : Colors.white;
  Color get _text => _dark ? const Color(0xFFF0F0F5) : const Color(0xFF111111);
  Color get _sub => _dark ? const Color(0xFF8E8E9A) : const Color(0xFF8E8E93);
  Color get _accent => const Color(0xFF533AFD);
  Color get _mint => const Color(0xFF00C4A7);
  Color get _seasonC => const {
    'spring': Color(0xFF34C759), 'summer': Color(0xFFFF9500),
    'autumn': Color(0xFFFF3B30), 'winter': Color(0xFF5856D6),
  }[_season] ?? const Color(0xFF533AFD);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunshiColors.background,
      body: switch (_state) {
        _PageState.loading => _loading,
        _PageState.error => _errorState,
        _PageState.empty => _emptyState,
        _PageState.loaded => _content,
      },
      // Bottom Navigation — Apple Health style: Home / AI / Insights / Profile
      bottomNavigationBar: _bottomNav,
    );
  }

  // ════════════════════════════════════════════════════════
  // CONTENT — Apple Health structure
  // ════════════════════════════════════════════════════════

  Widget get _content {
    return RefreshIndicator(
      onRefresh: _load,
      color: _accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _spacing16),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: _spacing16),

              // ── 1. Greeting — Calm style ──
              _greetingSection,
              const SizedBox(height: _spacing32),

              // ── 2. Primary Focus Card — ONE big card ──
              _primaryCard,
              const SizedBox(height: _spacing16),

              // ── 3. Secondary Cards — MAX 2 ──
              if (_secondary1Title.isNotEmpty) _secondaryCard(
                title: _secondary1Title,
                subtitle: _secondary1Subtitle,
                icon: Icons.bedtime_outlined,
                onTap: () => context.push('/skills'),
              ),
              const SizedBox(height: _spacing8),
              if (_secondary2Title.isNotEmpty) _secondaryCard(
                title: _secondary2Title,
                subtitle: _secondary2Subtitle,
                icon: Icons.spa_outlined,
                onTap: () => context.push('/reflection'),
              ),

              const SizedBox(height: _spacing32),

              // ── 4. Quick Mood — Calm style minimal ──
              _moodSection,
              const SizedBox(height: _spacing32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Greeting ──

  Widget get _greetingSection => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(_greeting,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _text,
          height: 1.2,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: _spacing4),
      Text(_userName,
        style: TextStyle(fontSize: 17, color: _sub, fontWeight: FontWeight.w400),
      ),
    ],
  );

  // ── Primary Focus Card — Apple Health style ──

  Widget get _primaryCard => GestureDetector(
    onTap: () => context.push('/chat'),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_spacing24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_radius20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_dark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _seasonC.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: _seasonC, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('TODAY\'S FOCUS',
                  style: TextStyle(
                    color: _seasonC,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title — large, clear
          Text(_primaryTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _text,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Reason — "why this matters"
          Text(_primaryReason,
            style: TextStyle(
              fontSize: 15,
              color: _sub,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Action button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_primaryAction.isNotEmpty ? _primaryAction : 'Start',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ],
                ),
              ),
              const Spacer(),
              Text(_primaryDuration,
                style: TextStyle(color: _sub, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── Secondary Card — smaller, supporting ──

  Widget _secondaryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_spacing16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_dark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _sub.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _sub, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(subtitle,
            style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: _sub.withOpacity(0.5), size: 18),
        ],
      ),
    ),
  );

  // ── Quick Mood — Calm minimal style ──

  Widget get _moodSection {
    final moods = [('calm', '😌'), ('tired', '😴'), ('anxious', '😰'),
                   ('peaceful', '🕊️'), ('energetic', '⚡'), ('overwhelmed', '🫧')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How are you?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _sub)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: moods.map((m) {
            final sel = _selectedMood == m.$1;
            return GestureDetector(
              onTap: () => _reflect(m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sel ? _accent.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: sel ? Border.all(color: _accent, width: 2) : null,
                ),
                child: Text(m.$2, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Bottom Navigation — Apple Health 4-tab ──

  Widget get _bottomNav => Container(
    decoration: BoxDecoration(
      color: _surface,
      border: Border(top: BorderSide(
        color: _dark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E5EA), width: 0.5)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Home', true, () {}),
            _navItem(Icons.chat_bubble_outline_rounded, 'AI', false, () => context.push('/chat')),
            _navItem(Icons.insights_outlined, 'Insights', false, () => context.push('/skills')),
            _navItem(Icons.person_outline_rounded, 'Profile', false, () => context.push('/profile')),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _accent : _sub, size: 24),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                color: active ? _accent : _sub,
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );

  // ── Loading ──

  Widget get _loading => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(_spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bone(180, 32), const SizedBox(height: 8),
            _bone(60, 16), const SizedBox(height: 32),
            _bone(null, 220, radius: _radius20), const SizedBox(height: 16),
            _bone(null, 64, radius: _radius16), const SizedBox(height: 8),
            _bone(null, 64, radius: _radius16),
          ],
        ),
      ),
    ),
  );

  // ── Error ──

  Widget get _errorState => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const SizedBox(height: 100),
          Icon(Icons.cloud_off_outlined, size: 56, color: _sub.withOpacity(0.4)),
          const SizedBox(height: 20),
          Text(_error ?? 'Something went wrong', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _text, height: 1.5)),
          const SizedBox(height: 20),
          TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context).t('home_page_intl_try_again')),
            style: TextButton.styleFrom(foregroundColor: _accent)),
        ]),
      ),
    ),
  );

  // ── Empty ──

  Widget get _emptyState => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const SizedBox(height: 100),
          Icon(Icons.wb_twilight, size: 56, color: _seasonC.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text('A new season is settling in.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 12),
          Text('Check back soon.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _sub)),
        ]),
      ),
    ),
  );

  Widget _bone(double? w, double h, {double radius = 8}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: _dark ? const Color(0xFF1A1A2A) : const Color(0xFFF0F0F5),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
