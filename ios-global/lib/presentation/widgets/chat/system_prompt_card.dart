import 'package:flutter/material.dart';
import 'package:seasons/core/theme/seasons_colors.dart';
import 'package:seasons/core/theme/seasons_text_styles.dart';

/// System Prompt Card - Structured cards sent by AI in conversations
class SystemPromptCard extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final VoidCallback? onTap;

  const SystemPromptCard({
    super.key,
    required this.cardData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardType = cardData['card_type'] ?? 'recipe';
    final emoji = cardData['card_emoji'] ?? cardData['emoji'] ?? '✨';
    final title = cardData['title'] ?? '';
    final description = cardData['description'] ?? '';
    final label = cardData['card_label'] ?? _getTypeLabel(cardType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: SeasonsColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SeasonsColors.border, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, emoji, label, title),
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(description, style: SeasonsTextStyles.body.copyWith(color: SeasonsColors.textSecondary, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              _buildCardContent(context, cardType),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String emoji, String label, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _getGradientColors(cardData['card_type'] ?? 'recipe'), begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SeasonsTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 2),
                Text(title, style: SeasonsTextStyles.heading.copyWith(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (cardData['difficulty'] != null && cardData['difficulty'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('${cardData['difficulty']}', style: SeasonsTextStyles.caption.copyWith(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, String cardType) {
    switch (cardType) {
      case 'recipe': return _buildRecipeContent(context);
      case 'acupoint': return _buildAcupointContent(context);
      case 'exercise': return _buildExerciseContent(context);
      case 'tea': return _buildTeaContent(context);
      case 'sleep': return _buildSleepContent(context);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildRecipeContent(BuildContext context) {
    final ingredients = (cardData['ingredients'] as List?) ?? [];
    final steps = (cardData['steps'] as List?) ?? [];
    final duration = cardData['duration'] ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ingredients.isNotEmpty) ...[
            Text('Ingredients', style: SeasonsTextStyles.heading.copyWith(fontSize: 14)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: ingredients.map<Widget>((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: SeasonsColors.primaryLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(e.toString(), style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.primaryDark, fontSize: 12)),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (steps.isNotEmpty) ...[
            Text('Steps', style: SeasonsTextStyles.heading.copyWith(fontSize: 14)),
            const SizedBox(height: 4),
            ...steps.take(3).map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: SeasonsTextStyles.caption.copyWith(fontSize: 12)),
                  Expanded(child: Text(step.toString(), style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.textSecondary, fontSize: 12))),
                ],
              ),
            )),
          ],
          if (duration.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time, size: 14, color: SeasonsColors.textHint),
              const SizedBox(width: 4),
              Text(duration, style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.textHint, fontSize: 12)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildAcupointContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('📍 Location', cardData['location'] ?? ''),
          _buildInfoRow('💆 Method', cardData['method'] ?? ''),
          _buildInfoRow('✨ Effect', cardData['effect'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildExerciseContent(BuildContext context) {
    final benefits = (cardData['benefits'] as List?) ?? [];
    final duration = cardData['duration'] ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (benefits.isNotEmpty) ...[
            Text('Benefits', style: SeasonsTextStyles.heading.copyWith(fontSize: 14)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: benefits.map<Widget>((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: SeasonsColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(e.toString(), style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.primaryDark, fontSize: 12)),
              )).toList(),
            ),
          ],
          if (duration.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.timer, size: 14, color: SeasonsColors.textHint),
              const SizedBox(width: 4),
              Text(duration, style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.textHint, fontSize: 12)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildTeaContent(BuildContext context) {
    final ingredients = (cardData['ingredients'] as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ingredients', style: SeasonsTextStyles.heading.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: ingredients.map<Widget>((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: SeasonsColors.warm.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(e.toString(), style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.warm, fontSize: 12)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('🌙 Method', cardData['method'] ?? ''),
          if (cardData['best_time'] != null) _buildInfoRow('⏰ Best Time', cardData['best_time'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.textSecondary, fontSize: 12))),
          Expanded(child: Text(value, style: SeasonsTextStyles.caption.copyWith(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: SeasonsColors.border, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Seasons Wellness · ${_getTypeLabel(cardData['card_type'] ?? 'recipe')}', style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.textHint, fontSize: 11)),
          Text('View Details →', style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.primary, fontSize: 11)),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'recipe': return 'Recipe';
      case 'acupoint': return 'Acupressure';
      case 'exercise': return 'Exercise';
      case 'tea': return 'Tea';
      case 'sleep': return 'Sleep Tip';
      default: return 'Wellness';
    }
  }

  List<Color> _getGradientColors(String type) {
    switch (type) {
      case 'recipe': return [const Color(0xFFFF8A65), const Color(0xFFFF6E40)];
      case 'acupoint': return [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
      case 'exercise': return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
      case 'tea': return [const Color(0xFF8D6E63), const Color(0xFF6D4C41)];
      case 'sleep': return [const Color(0xFF7E57C2), const Color(0xFF5E35B1)];
      default: return [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
    }
  }
}
