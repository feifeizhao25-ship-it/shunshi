// CacheService — UX_API_SPEC §5 Multi-Level Cache
// L1: 内存缓存 (staleTime + gcTime)
// L2: SharedPreferences 持久化
// 支持 staleTime/gcTime/命中率追踪/预热
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// ==================== Cache Entry ====================

class _CacheEntry {
  final dynamic data;
  final int cachedAt; // ms
  final String key;

  _CacheEntry({required this.data, required this.cachedAt, required this.key});

  bool isStale(Duration staleTime) {
    return DateTime.now().millisecondsSinceEpoch - cachedAt > staleTime.inMilliseconds;
  }

  bool isExpired(Duration gcTime) {
    return DateTime.now().millisecondsSinceEpoch - cachedAt > gcTime.inMilliseconds;
  }

  Map<String, dynamic> toMap() => {
    'data': data,
    'cached_at': cachedAt,
    'key': key,
  };

  factory _CacheEntry.fromMap(Map<String, dynamic> map) => _CacheEntry(
    data: map['data'],
    cachedAt: map['cached_at'] as int? ?? 0,
    key: map['key'] as String? ?? '',
  );
}

// ==================== Cache Stats ====================

class CacheStats {
  int hits = 0;
  int misses = 0;
  int staleHits = 0; // 命中但已 stale（可后台 revalidate）
  int evictions = 0;

  double get hitRate => (hits + staleHits + misses) == 0
      ? 0
      : (hits + staleHits) / (hits + staleHits + misses);

  @override
  String toString() => 'CacheStats(hits=$hits, stale=$staleHits, misses=$misses, rate=${(hitRate * 100).toStringAsFixed(1)}%)';
}

// ==================== Cache Key Convention (§5.2) ====================

/// 缓存键命名规范
class CacheKeys {
  // 今日数据
  static String today([String? location]) => 'today:${location ?? 'default'}';
  // 节气
  static String solarTerms() => 'solar_terms';
  static String solarTerm(String slug) => 'solar_term:$slug';
  // 食谱
  static String recipes(Map<String, dynamic> filters) => 'recipes:${_encodeFilters(filters)}';
  static String recipe(String slug) => 'recipe:$slug';
  // 穴位/草本
  static String acupoint(String slug) => 'acupoint:$slug';
  static String herb(String slug) => 'herb:$slug';
  // 用户
  static String userProfile() => 'user:profile';
  static String userFavorites([int? page]) => 'user:favorites:${page ?? 1}';
  static String userJournals(String from, String to) => 'user:journals:$from:$to';
  static String userBodyType() => 'user:body_type';
  // 对话
  static String chatSession(String id) => 'chat:session:$id';
  static String chatSessions([int? page]) => 'chat:sessions:${page ?? 1}';
  // 搜索
  static String search(String query) => 'search:$query';
  // 社区
  static String communityFeed(String type, [int? page]) => 'community:feed:$type:${page ?? 1}';
  // 会员
  static String plans() => 'plans';

  static String _encodeFilters(Map<String, dynamic> f) {
    final keys = f.keys.toList()..sort();
    return keys.map((k) => '$k=${f[k]}').join('&');
  }
}

// ==================== Cache Configs (§5.3) ====================

/// 各类数据的缓存配置
class CacheConfig {
  final Duration staleTime;
  final Duration gcTime;
  final bool persist; // 是否持久化到 L2
  final bool offline; // 是否预下载到离线包

  const CacheConfig({
    required this.staleTime,
    required this.gcTime,
    this.persist = false,
    this.offline = false,
  });

  // §5.3 完整缓存配置表
  static const solarTerms = CacheConfig(
    staleTime: Duration(days: 7),
    gcTime: Duration(days: 30),
    persist: true,
    offline: true,
  );
  static const today = CacheConfig(
    staleTime: Duration(minutes: 30),
    gcTime: Duration(hours: 24),
    persist: true,
  );
  static const recipeDetail = CacheConfig(
    staleTime: Duration(hours: 24),
    gcTime: Duration(days: 7),
    persist: true,
    offline: true,
  );
  static const recipeList = CacheConfig(
    staleTime: Duration(minutes: 5),
    gcTime: Duration(hours: 1),
  );
  static const userProfile = CacheConfig(
    staleTime: Duration(minutes: 5),
    gcTime: Duration(days: 365), // 永久
    persist: true,
  );
  static const userFavorites = CacheConfig(
    staleTime: Duration(minutes: 5),
    gcTime: Duration(hours: 24),
    persist: true,
  );
  static const journals = CacheConfig(
    staleTime: Duration(seconds: 30),
    gcTime: Duration(hours: 24),
    persist: true,
    offline: true,
  );
  static const chatHistory = CacheConfig(
    staleTime: Duration(seconds: 30),
    gcTime: Duration(days: 7),
    persist: true,
  );
  static const quizResult = CacheConfig(
    staleTime: Duration(days: 36500), // 永久
    gcTime: Duration(days: 36500),
    persist: true,
    offline: true,
  );
  static const plans = CacheConfig(
    staleTime: Duration(hours: 1),
    gcTime: Duration(hours: 24),
  );
  static const searchResults = CacheConfig(
    staleTime: Duration(hours: 1),
    gcTime: Duration(hours: 1),
  );
  static const communityFeed = CacheConfig(
    staleTime: Duration(minutes: 1),
    gcTime: Duration(minutes: 5),
  );
  static const systemConfig = CacheConfig(
    staleTime: Duration(minutes: 5),
    gcTime: Duration(hours: 1),
    persist: true,
  );
}

// ==================== CacheService ====================

class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  // L1: 内存缓存
  final Map<String, _CacheEntry> _memoryCache = {};

  // L2: 持久化缓存 (SharedPreferences)
  SharedPreferences? _prefs;
  static const _l2Prefix = 'cache_v2_';

  // 统计
  final CacheStats _stats = CacheStats();

  // L2 最大存储: 10MB
  static const _maxL2Bytes = 10 * 1024 * 1024;

  // ==================== Init ====================

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ==================== Core Get/Set ====================

  /// 获取缓存数据
  /// 返回 CacheResult: data + isStale + source
  CacheResult<T>? get<T>(String key, {required CacheConfig config}) {
    // L1: 内存
    final memEntry = _memoryCache[key];
    if (memEntry != null) {
      if (memEntry.isExpired(config.gcTime)) {
        _memoryCache.remove(key);
        _stats.evictions++;
      } else {
        final stale = memEntry.isStale(config.staleTime);
        if (stale) {
          _stats.staleHits++;
        } else {
          _stats.hits++;
        }
        return CacheResult<T>(
          data: memEntry.data as T,
          isStale: stale,
          source: CacheSource.memory,
        );
      }
    }

    // L2: 持久化
    if (config.persist) {
      final l2Data = _getL2<T>(key);
      if (l2Data != null) {
        // 回填 L1
        _memoryCache[key] = _CacheEntry(
          data: l2Data.data,
          cachedAt: l2Data.cachedAt,
          key: key,
        );
        final stale = l2Data.isStale(config.staleTime);
        if (stale) {
          _stats.staleHits++;
        } else {
          _stats.hits++;
        }
        return CacheResult<T>(
          data: l2Data.data as T,
          isStale: stale,
          source: CacheSource.disk,
        );
      }
    }

    _stats.misses++;
    return null;
  }

  /// 写入缓存
  Future<void> set<T>(String key, T data, {required CacheConfig config}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // L1
    _memoryCache[key] = _CacheEntry(data: data, cachedAt: now, key: key);

    // L2
    if (config.persist) {
      await _setL2(key, data, now);
    }
  }

  /// 失效指定 key
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove('$_l2Prefix$key');
  }

  /// 失效匹配前缀的所有 key
  Future<void> invalidateByPrefix(String prefix) async {
    _memoryCache.removeWhere((key, _) => key.startsWith(prefix));

    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((k) => k.startsWith('$_l2Prefix$prefix'));
      for (final k in keys) {
        await _prefs!.remove(k);
      }
    }
  }

  /// 失效所有缓存
  Future<void> invalidateAll() async {
    _memoryCache.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_l2Prefix));
      for (final k in keys) {
        await _prefs!.remove(k);
      }
    }
  }

  // ==================== L2 Helpers ====================

  _CacheEntry? _getL2<T>(String key) {
    if (_prefs == null) return null;
    final raw = _prefs!.getString('$_l2Prefix$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _CacheEntry.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setL2<T>(String key, T data, int cachedAt) async {
    if (_prefs == null) return;
    final entry = _CacheEntry(data: data, cachedAt: cachedAt, key: key);
    try {
      await _prefs!.setString('$_l2Prefix$key', jsonEncode(entry.toMap()));
    } catch (e) {
      // L2 写入失败不阻塞（可能超 10MB 限制）
      if (kDebugMode) print('Cache L2 write failed: $e');
    }
  }

  // ==================== Stats ====================

  CacheStats get stats => _stats;

  /// L2 缓存大小 (bytes)
  int get l2SizeBytes {
    if (_prefs == null) return 0;
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_l2Prefix));
    int total = 0;
    for (final k in keys) {
      total += (_prefs!.getString(k)?.length ?? 0) * 2; // UTF-16
    }
    return total;
  }

  /// L1 缓存条目数
  int get l1Count => _memoryCache.length;

  /// L2 缓存条目数
  int get l2Count {
    if (_prefs == null) return 0;
    return _prefs!.getKeys().where((k) => k.startsWith(_l2Prefix)).length;
  }

  // ==================== Prewarm (§5.6) ====================

  /// 预热缓存 — App 启动后 5s 静默预拉
  Future<void> prewarm() async {
    // 预热由调用方通过 ApiClient 发起，这里只检查哪些需要更新
    if (kDebugMode) {
      print('Cache prewarm: L1=$l1Count, L2=$l2Count, size=${l2SizeBytes ~/ 1024}KB');
    }
  }
}

// ==================== Cache Result ====================

enum CacheSource { memory, disk, network }

class CacheResult<T> {
  final T data;
  final bool isStale; // 已过 staleTime，需要后台 revalidate
  final CacheSource source;

  const CacheResult({
    required this.data,
    required this.isStale,
    required this.source,
  });

  @override
  String toString() => 'CacheResult(source=$source, stale=$isStale, data=$data)';
}

// ==================== Global Instance ====================

final cacheService = CacheService();
