import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/content_item.dart';
import 'infrastructure_providers.dart';

final contentProvider =
    AsyncNotifierProvider<ContentNotifier, ContentState>(ContentNotifier.new);

class ContentState {
  final List<ContentItem> items;
  final ContentType? selectedType;
  final bool hasMore;
  final int page;

  const ContentState({
    this.items = const [],
    this.selectedType,
    this.hasMore = true,
    this.page = 0,
  });

  ContentState copyWith({
    List<ContentItem>? items,
    ContentType? selectedType,
    bool? hasMore,
    int? page,
  }) {
    return ContentState(
      items: items ?? this.items,
      selectedType: selectedType ?? this.selectedType,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class ContentNotifier extends AsyncNotifier<ContentState> {
  @override
  Future<ContentState> build() async {
    return _load(reset: true);
  }

  Future<ContentState> _load({bool reset = false}) async {
    final current = reset ? const ContentState() : (state.value ?? const ContentState());
    final repo = ref.read(contentRepositoryProvider);
    final items = await repo.getContentList(
      type: current.selectedType,
      page: reset ? 0 : current.page,
    );
    if (reset) {
      return ContentState(items: items, hasMore: items.length >= 20);
    }
    return current.copyWith(
      items: [...current.items, ...items],
      hasMore: items.length >= 20,
      page: current.page + 1,
    );
  }

  Future<void> filterByType(ContentType? type) async {
    state = const AsyncLoading();
    final repo = ref.read(contentRepositoryProvider);
    final items = await repo.getContentList(type: type);
    state = AsyncData(ContentState(
      items: items,
      selectedType: type,
      hasMore: items.length >= 20,
    ));
  }

  Future<void> loadMore() async {
    if (state.value?.hasMore != true) return;
    final more = await _load(reset: false);
    state = AsyncData(more);
  }
}
