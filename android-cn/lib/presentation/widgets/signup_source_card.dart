// lib/presentation/widgets/signup_source_card.dart
//
// 注册来源题「从哪知道我们」：可跳过的单选，放在首次资料填写的选填区。
// 后端开关 SHUNSHI_GROWTH_SIGNUP_SOURCE_ENABLED 默认关闭；开关关着、接口失败或
// 已经答过/跳过时，本组件什么都不显示，也不影响「完成」按钮。
// 只提交选项代码（例如 zhihu），不带手机号、昵称等任何身份信息，也不收自由文本。

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/network/api_client.dart';

/// 答过或跳过后写入，同一台设备不再追问。
const signupSourceDonePrefKey = 'signup_source_done';

class SignupSourceOption {
  final String code;
  final String label;
  const SignupSourceOption(this.code, this.label);
}

typedef SignupSourceLoader = Future<List<SignupSourceOption>?> Function();
typedef SignupSourceSubmitter = Future<void> Function(String code);

/// 解析 GET /api/v1/growth/signup-source。未开启或格式不对时返回 null（不显示题目）。
List<SignupSourceOption>? parseSignupSourceOptions(dynamic body) {
  if (body is! Map) return null;
  final data = body['data'];
  if (data is! Map || data['enabled'] != true) return null;
  final raw = data['options'];
  if (raw is! List) return null;
  final options = <SignupSourceOption>[];
  for (final item in raw) {
    if (item is Map && item['code'] is String && item['label'] is String) {
      options.add(SignupSourceOption(item['code'] as String, item['label'] as String));
    }
  }
  return options.isEmpty ? null : options;
}

Future<List<SignupSourceOption>?> loadSignupSourceOptions() async {
  final response = await ApiClient().get('/api/v1/growth/signup-source');
  return parseSignupSourceOptions(response.data);
}

Future<void> submitSignupSource(String code) async {
  await ApiClient().post('/api/v1/growth/signup-source', data: {'source': code});
}

class SignupSourceCard extends StatefulWidget {
  const SignupSourceCard({super.key, this.loader, this.submitter});

  /// 测试可注入；默认请求后端。
  final SignupSourceLoader? loader;
  final SignupSourceSubmitter? submitter;

  @override
  State<SignupSourceCard> createState() => _SignupSourceCardState();
}

class _SignupSourceCardState extends State<SignupSourceCard> {
  List<SignupSourceOption>? _options;
  bool _hidden = true;
  bool _thanked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(signupSourceDonePrefKey) == true) return;
      final options = await (widget.loader ?? loadSignupSourceOptions)();
      if (!mounted || options == null || options.isEmpty) return;
      setState(() {
        _options = options;
        _hidden = false;
      });
    } catch (_) {
      // 开关查询失败就当没开，不打扰注册。
    }
  }

  Future<void> _markDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(signupSourceDonePrefKey, true);
    } catch (_) {}
  }

  Future<void> _choose(String code) async {
    setState(() => _thanked = true);
    await _markDone();
    try {
      await (widget.submitter ?? submitSignupSource)(code);
    } catch (_) {
      // 提交失败不重试、不提示：这道题不该挡住任何事。
    }
  }

  Future<void> _skip() async {
    setState(() => _hidden = true);
    await _markDone();
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    if (_hidden || options == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    if (_thanked) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text('谢谢告诉我们', style: theme.textTheme.bodySmall),
      );
    }
    return Padding(
      key: const Key('signup_source_card'),
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '从哪知道我们（选填）',
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                ),
              ),
              TextButton(
                key: const Key('signup_source_skip'),
                onPressed: _skip,
                child: const Text('跳过'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  key: Key('signup_source_${option.code}'),
                  label: Text(option.label),
                  selected: false,
                  onSelected: (_) => _choose(option.code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
