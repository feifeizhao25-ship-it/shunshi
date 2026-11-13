/// 完整时辰养生表。十二个时辰和首页卡片是同一份白话，不写经络。
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/storage/storage_manager.dart';
import '../../../design_system/theme.dart';
import '../../widgets/empty_state.dart';
import '../home/ultimate_home_page.dart';
import 'solar_wellness_copy.dart';

Future<String?> readSolarWellnessToken() async {
  try {
    final stored = await tokenStorage.getAccessToken();
    if (stored != null && stored.trim().isNotEmpty) return stored.trim();
  } catch (_) {}
  try {
    final fallback = StorageManager.user.getToken();
    if (fallback != null && fallback.trim().isNotEmpty) return fallback.trim();
  } catch (_) {}
  return null;
}

Future<SolarWellnessLoad> loadSolarWellnessAdvice() {
  return fetchSolarWellnessAdvice(
    readToken: readSolarWellnessToken,
    send: (token) async {
      try {
        final res = await ApiClient().get(
          '/solar-wellness/daily-advice',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
          level: SpeedLevel.s2,
        );
        return SolarWellnessHttpResult(
          statusCode: res.statusCode,
          data: res.data,
        );
      } on DioException catch (error) {
        return SolarWellnessHttpResult(
          statusCode: error.response?.statusCode,
          data: error.response?.data,
          failed: true,
        );
      }
    },
  );
}

class SolarDetailPage extends StatefulWidget {
  const SolarDetailPage({super.key, this.load});

  final Future<SolarWellnessLoad> Function()? load;

  @override
  State<SolarDetailPage> createState() => _SolarDetailPageState();
}

class _SolarDetailPageState extends State<SolarDetailPage> {
  bool _loading = true;
  SolarWellnessLoad? _result;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loader = widget.load ?? loadSolarWellnessAdvice;
    final result = await loader();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark
        ? ShunShiColors.darkSurface
        : ShunShiColors.background;
    final text = dark
        ? ShunShiColors.darkTextPrimary
        : ShunShiColors.textPrimary;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          kSolarWellnessTitle,
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            color: text,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
      ),
      body: _body(context, dark),
    );
  }

  Widget _body(BuildContext context, bool dark) {
    if (_loading) {
      return LoadingExplain(message: kSolarWellnessLoading);
    }
    final result = _result;
    if (result == null || result.failed) {
      return _status(
        dark: dark,
        icon: Icons.cloud_off,
        title: result?.needsLogin == true
            ? kSolarWellnessLoginTitle
            : kSolarWellnessErrorTitle,
        body: result?.error ?? kSolarWellnessErrorBody,
        retry: true,
      );
    }
    if (result.entries.isEmpty) {
      return _status(
        dark: dark,
        icon: Icons.event_busy,
        title: kSolarWellnessEmptyTitle,
        body: kSolarWellnessEmptyBody,
      );
    }
    final current = getCurrentShiChen().name;
    final card = dark
        ? ShunShiColors.darkSurfaceContainerLowest
        : ShunShiColors.surfaceContainerLowest;
    final text = dark
        ? ShunShiColors.darkTextPrimary
        : ShunShiColors.textPrimary;
    final muted = dark
        ? ShunShiColors.darkTextSecondary
        : ShunShiColors.textSecondary;
    return SingleChildScrollView(
      key: const Key('solar-wellness-list'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kSolarWellnessIntro,
            style: TextStyle(fontSize: 15, height: 1.6, color: muted),
          ),
          const SizedBox(height: 16),
          for (final entry in result.entries) ...[
            _entryCard(
              entry,
              current: entry.name == current,
              card: card,
              text: text,
              muted: muted,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _entryCard(
    ShiChenData entry, {
    required bool current,
    required Color card,
    required Color text,
    required Color muted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: current
              ? ShunShiColors.primary.withValues(alpha: 0.45)
              : ShunShiColors.borderGhost,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                shiChenTimeDisplay(entry),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.6,
                  color: muted,
                ),
              ),
              if (current) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    kSolarWellnessNow,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ShunShiColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            shiChenHeadline(entry),
            style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
          const SizedBox(height: 4),
          Text(entry.meridian, style: TextStyle(fontSize: 13, color: muted)),
          const SizedBox(height: 8),
          Text(
            entry.wellnessPrinciple,
            style: TextStyle(fontSize: 15, height: 1.6, color: text),
          ),
          const SizedBox(height: 6),
          Text(
            entry.aiQuote,
            style: TextStyle(fontSize: 14, height: 1.6, color: muted),
          ),
          const SizedBox(height: 10),
          for (final action in entry.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${action.title}：${action.description}',
                style: TextStyle(fontSize: 14, height: 1.5, color: text),
              ),
            ),
        ],
      ),
    );
  }

  Widget _status({
    required bool dark,
    required IconData icon,
    required String title,
    required String body,
    bool retry = false,
  }) {
    final text = dark
        ? ShunShiColors.darkTextPrimary
        : ShunShiColors.textPrimary;
    final muted = dark
        ? ShunShiColors.darkTextSecondary
        : ShunShiColors.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: muted),
            const SizedBox(height: 16),
            Text(
              title,
              key: const Key('solar-wellness-status-title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              key: const Key('solar-wellness-status-body'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6, color: muted),
            ),
            if (retry) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _reload,
                child: const Text(kSolarWellnessRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
