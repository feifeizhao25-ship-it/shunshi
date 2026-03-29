import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../../domain/entities/ai_response.dart';
import '../../providers/home_provider.dart';

/// Home Page — SEASONS Global
/// Clean, calm layout: greeting → insight → 3 suggestions → season card → AI entry

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

    if (homeState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BreathingDot(),
              SizedBox(height: 24),
              Text(
                'Loading your space...',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          color: const Color(0xFFA7C7E7),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 32),

              // ── Greeting ──
              _GreetingText(greeting: homeState.greeting ?? 'Good evening'),
              const SizedBox(height: 32),

              // ── Daily Insight ──
              if (homeState.dailyInsight != null)
                _DailyInsightCard(insight: homeState.dailyInsight!),
              const SizedBox(height: 24),

              // ── Suggestions ──
              if (homeState.suggestions.isNotEmpty) ...[
                _SectionLabel(label: 'Gentle suggestions for today'),
                const SizedBox(height: 12),
                ...homeState.suggestions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SuggestionCard(suggestion: s),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Season Card ──
              if (homeState.seasonCard != null)
                _SeasonCard(card: homeState.seasonCard!),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _GreetingText extends StatelessWidget {
  final String greeting;
  const _GreetingText({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w200,
            color: Color(0xFFF5F5F5),
            letterSpacing: 0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Here\'s your space for today.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Color(0xFF888888),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _DailyInsightCard extends StatelessWidget {
  final DailyInsight insight;
  const _DailyInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A3D52),
            const Color(0xFF1E2A38),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFA7C7E7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.season.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA7C7E7),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _seasonEmoji(insight.season),
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insight.text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w300,
              color: Color(0xFFF0F0F0),
              height: 1.65,
              letterSpacing: 0.2,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }

  String _seasonEmoji(String season) {
    switch (season.toLowerCase()) {
      case 'spring': return '🌱';
      case 'summer': return '☀️';
      case 'autumn': return '🍂';
      case 'winter': return '❄️';
      default: return '🌿';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFF666666),
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final GentleSuggestion suggestion;
  const _SuggestionCard({required this.suggestion});

  String get _emoji {
    switch (suggestion.iconName) {
      case 'breathe': return '🫁';
      case 'tea': return '🍵';
      case 'walk': return '🚶';
      case 'stretch': return '🧘';
      case 'journal': return '📝';
      case 'moon': return '🌙';
      case 'read': return '📖';
      case 'water': return '💧';
      case 'look_away': return '👀';
      case 'sunrise': return '🌅';
      case 'sleep': return '😴';
      case 'calm': return '💜';
      case 'ritual': return '🌿';
      case 'movement': return '🚶';
      case 'awareness': return '🌿';
      default: return '💜';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              suggestion.text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFE0E0E0),
                height: 1.5,
                letterSpacing: 0.15,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final SeasonCardData card;
  const _SeasonCard({required this.card});

  String get _gradientColors {
    switch (card.name.toLowerCase()) {
      case 'spring': return '🌱 Spring';
      case 'summer': return '☀️ Summer';
      case 'autumn': return '🍂 Autumn';
      case 'winter': return '❄️ Winter';
      default: return '🌿 ${card.name}';
    }
  }

  List<Color> get _gradColors {
    switch (card.name.toLowerCase()) {
      case 'spring': return [const Color(0xFF2D4A3E), const Color(0xFF1E2A38)];
      case 'summer': return [const Color(0xFF4A3528), const Color(0xFF1E2A38)];
      case 'autumn': return [const Color(0xFF4A3828), const Color(0xFF1E2A38)];
      case 'winter': return [const Color(0xFF2A3D4A), const Color(0xFF1E2A38)];
      default: return [const Color(0xFF2A3D52), const Color(0xFF1E2A38)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                card.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFFF5F5F5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    '${card.phase} ${card.hemisphere == 'south' ? '(Southern Hemisphere)' : '(Northern Hemisphere)'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (card.insight.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              card.insight,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Color(0xFFB0B0B0),
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreathingDot extends StatefulWidget {
  const _BreathingDot();

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFA7C7E7).withValues(alpha: 0.7),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA7C7E7).withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
