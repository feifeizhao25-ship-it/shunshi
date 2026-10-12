import 'package:flutter/material.dart';
import '../../../data/services/family_api.dart';

const _relations = {
  'parent': '父母',
  'father': '父亲',
  'mother': '母亲',
  'spouse': '配偶',
  'child': '子女',
  'grandparent': '祖父母',
  'sibling': '兄弟姐妹',
  'other': '其他',
};

class FamilyPageV2 extends StatefulWidget {
  const FamilyPageV2({super.key, this.api});
  final FamilyApi? api;
  @override
  State<FamilyPageV2> createState() => _FamilyPageV2State();
}

class _FamilyPageV2State extends State<FamilyPageV2> {
  late final FamilyApi _api = widget.api ?? FamilyApi();
  Map<String, dynamic>? _family;
  String? _error;
  bool _loading = true, _saving = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _family = null;
    });
    try {
      final family = await _api.load();
      if (!mounted || generation != _generation) return;
      setState(() {
        _family = family;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = '家庭信息暂时无法读取，请确认已登录后重试';
      });
    }
  }

  Future<void> _change(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('操作未完成，请检查登录状态、网络或家庭人数后重试')));
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _add() async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
    if (values != null && mounted) await _change(() => _api.add(values));
  }

  Future<void> _remove(Map member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除家庭成员'),
        content: Text('确定移除“${member['name']}”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认移除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _change(() => _api.remove(member['id'] as String));
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = (_family?['members'] as List?) ?? [];
    final enabled = !_loading && !_saving && _family != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        title: const Text('家庭关怀'),
        actions: [
          IconButton(
            tooltip: '刷新家庭信息',
            onPressed: _loading || _saving ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _saving ? () async {} : _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null) ...[
                    const Icon(Icons.cloud_off, size: 44),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('重新读取')),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF205C44),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _family?['family_name'] as String? ?? '我的家庭',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '已记录 ${members.length} 位成员',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '记录家人的基本信息，留意日常关怀。',
                            style: TextStyle(color: Color(0xFFD6E6DB)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '还没有家庭成员，可以先添加一位家人。',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final member in members)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (member['name'] as String).isEmpty
                                          ? '未填写姓名'
                                          : member['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_relations[member['relation']] ?? '家人'} · ${member['age'] == null ? '年龄未填写' : '${member['age']} 岁'}',
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: '移除成员',
                                onPressed: enabled
                                    ? () => _remove(member)
                                    : null,
                                icon: const Icon(Icons.person_remove_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: enabled ? _add : null,
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(_saving ? '正在保存…' : '添加家庭成员'),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '年龄可以暂不填写。家庭记录不等同于付费会员席位。',
                      style: TextStyle(color: Color(0xFF617166)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();
  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _age = TextEditingController();
  String _relation = 'parent';
  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('添加家庭成员'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              maxLength: 80,
              decoration: const InputDecoration(labelText: '姓名'),
              validator: (v) => v == null || v.trim().isEmpty ? '请填写姓名' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _relation,
              decoration: const InputDecoration(labelText: '关系'),
              items: _relations.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => _relation = v ?? 'parent',
            ),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '年龄（选填）'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final age = int.tryParse(v.trim());
                return age == null || age < 0 || age > 120
                    ? '请输入 0 至 120 的整数'
                    : null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, <String, dynamic>{
              'name': _name.text.trim(),
              'relation': _relation,
              'age': _age.text.trim().isEmpty
                  ? null
                  : int.parse(_age.text.trim()),
            });
          }
        },
        child: const Text('保存'),
      ),
    ],
  );
}
