import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../data/network/api_client.dart';
import '../../../design_system/app_colors.dart';

/// 用户反馈页
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
    ('general', '综合反馈'),
    ('bug', '问题报告'),
    ('feature', '功能建议'),
    ('content', '内容建议'),
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
      await ApiClient().post('/api/v1/feedback/submit', data: {
        'user_id': 'guest',
        'category': _category,
        'message': _msgCtrl.text.trim(),
        'rating': _rating > 0 ? _rating : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('感谢您的反馈！'), duration: Duration(seconds: 2)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败，请稍后重试'), duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('意见反馈', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('反馈类型', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _categories.map((c) => ChoiceChip(
            label: Text(c.$2),
            selected: _category == c.$1,
            onSelected: (_) => setState(() => _category = c.$1),
            backgroundColor: AppColors.surfaceContainerLowest(context),
            selectedColor: AppColors.primary(context).withValues(alpha: 0.15),
            side: BorderSide.none,
          )).toList()),
          const SizedBox(height: 20),
          Text('评分', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Icon(i < _rating ? Icons.star : Icons.star_border,
              color: i < _rating ? Colors.amber : AppColors.textTertiary(context), size: 32),
          ))),
          const SizedBox(height: 20),
          Text('反馈内容', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '请描述您的问题或建议...',
              hintStyle: TextStyle(color: AppColors.textTertiary(context)),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('提交反馈', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}
