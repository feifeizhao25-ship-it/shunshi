import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);

    // Save locally for now
    final prefs = await SharedPreferences.getInstance();
    final feedbacks = prefs.getStringList('feedbacks') ?? [];
    feedbacks.add('${DateTime.now().toIso8601String()}: $text');
    await prefs.setStringList('feedbacks', feedbacks);

    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('profile_thank_you_for_your_feedback_we_take_it_seriou')),
          duration: Duration(seconds: 2),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Feedback',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us what you think',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ShunShiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).t('feedback_issues_suggestions_experience_feedback'),
                hintStyle: TextStyle(color: ShunShiColors.textTertiary, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ShunShiColors.borderGhost),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ShunShiColors.borderGhost),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'SubmitFeedback',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
