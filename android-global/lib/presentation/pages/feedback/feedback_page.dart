import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../../core/network/api_singleton.dart';

/// 用户Feedback页
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _msgCtrl = TextEditingController();
  String _category = 'general';
  int _rating = 0;
  bool _submitting = false;

  static const _categories = [
    ('general', 'General Feedback'),
    ('bug', 'Bug Report'),
    ('feature', 'Feature Suggestion'),
    ('content', 'Content Suggestion'),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiClient().post('/api/v1/feedback', data: {
        'user_id': 'guest',
        'category': _category,
        'message': _msgCtrl.text.trim(),
        'rating': _rating > 0 ? _rating : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('feedback_thank_you_for_your_feedback')), duration: Duration(seconds: 2)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e'), duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('feedback'), style: TextStyle(color: ShunShiColors.textPrimary, fontWeight: FontWeight.w700)),
        elevation: 0,
        iconTheme: const IconThemeData(color: ShunShiColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context).get('feedback_type'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _categories.map((c) => ChoiceChip(
            label: Text(c.$2),
            selected: _category == c.$1,
            onSelected: (_) => setState(() => _category = c.$1),
            backgroundColor: ShunShiColors.surfaceContainerLowest,
            selectedColor: ShunShiColors.primary.withValues(alpha: 0.15),
            side: BorderSide.none,
          )).toList()),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context).get('feedback_rating'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Icon(i < _rating ? Icons.star : Icons.star_border,
              color: i < _rating ? Colors.amber : ShunShiColors.textTertiary, size: 32),
          ))),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context).get('feedback_content'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).t('feedback_please_describe_your_question_or'),
              hintStyle: TextStyle(color: ShunShiColors.textTertiary),
              filled: true,
              fillColor: ShunShiColors.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ShunShiColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(AppLocalizations.of(context).get('feedback_submit_btn'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}
