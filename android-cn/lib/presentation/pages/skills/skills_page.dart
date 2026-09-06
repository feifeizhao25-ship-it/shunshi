import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/config/app_config.dart';
import '../../../data/storage/storage_manager.dart';

/// Displays the real Skills API contract without inventing confidence or actions.
class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key, this.client, this.accessToken});
  final Dio? client;
  final Future<String?> Function()? accessToken;
  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  late final Dio _dio =
      widget.client ??
      Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/v1/?$'), ''),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
  List<Map<String, dynamic>> _skills = [];
  bool _loading = true;
  String? _error;
  String? _activeSkill;
  Map<String, dynamic>? _result;
  int _offset = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void dispose() {
    if (widget.client == null) _dio.close(force: true);
    super.dispose();
  }

  Future<void> _loadSkills({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get(
        '/api/v1/skills',
        queryParameters: {'limit': 50, 'offset': more ? _offset : 0},
      );
      if (response.data is! List) throw const FormatException();
      final items = List<Map<String, dynamic>>.from(response.data as List);
      if (!mounted) return;
      setState(() {
        _skills = more ? [..._skills, ...items] : items;
        _offset = _skills.length;
        _hasMore = items.length == 50;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '能力列表加载失败，请重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _execute(Map<String, dynamic> skill) async {
    if (_activeSkill != null) return;
    setState(() {
      _activeSkill = skill['skill_id'] as String?;
      _error = null;
    });
    try {
      final token = widget.accessToken != null
          ? await widget.accessToken!()
          : StorageManager.user.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _error = '请先登录，再使用此能力');
        return;
      }
      final response = await _dio.post(
        '/api/v1/skills/execute',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'message': '请提供${skill['name']}的日常建议',
          'skill_ids': [skill['skill_id']],
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['final_response'] is! String ||
          (data['final_response'] as String).trim().isEmpty)
        throw const FormatException();
      if (mounted) setState(() => _result = data);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (mounted)
        setState(
          () => _error = status == 401
              ? '登录已失效，请重新登录'
              : status == 403
              ? '当前账号无权使用此能力，请检查会员权益'
              : '建议生成失败，请稍后重试',
        );
    } catch (_) {
      if (mounted) setState(() => _error = '建议生成失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _activeSkill = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日常养生建议')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_error!, semanticsLabel: _error),
                      if (_skills.isEmpty)
                        TextButton(
                          onPressed: () => _loadSkills(),
                          child: const Text('重新加载'),
                        ),
                    ],
                  ),
                ),
              ),
            if (_result != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _result = null),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回能力列表'),
                ),
              ),
              const Text(
                '本次建议',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _result!['status'] == 'blocked'
                    ? '本次已转为安全提醒'
                    : _result!['status'] == 'partial'
                    ? '部分内容未能完成'
                    : _result!['status'] == 'failed'
                    ? '本次未能完成'
                    : '人工智能生成，请结合自身情况参考',
              ),
              const SizedBox(height: 20),
              MarkdownBody(
                data: _result!['final_response'] as String,
                selectable: true,
              ),
            ] else ...[
              const Text(
                '选择你现在关心的事',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('用于日常生活参考，不替代医疗诊断。会员能力会在调用时核验权益。'),
              const SizedBox(height: 20),
              if (!_loading && _skills.isEmpty && _error == null)
                const Text('暂时没有可用能力'),
              for (final skill in _skills)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(skill['name'] as String? ?? '日常建议'),
                    subtitle: Text(skill['description'] as String? ?? ''),
                    trailing: _activeSkill == skill['skill_id']
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : Icon(
                            skill['is_premium'] == true
                                ? Icons.workspace_premium_outlined
                                : Icons.chevron_right,
                          ),
                    onTap: _activeSkill == null ? () => _execute(skill) : null,
                  ),
                ),
              if (_hasMore && !_loading)
                TextButton(
                  onPressed: () => _loadSkills(more: true),
                  child: const Text('加载更多'),
                ),
              if (_loading) const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
