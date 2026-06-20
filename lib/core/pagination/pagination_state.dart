import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaginationState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final String? error;

  const PaginationState({
    required this.items,
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.error,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

typedef FetchItems<T> = Future<List<T>> Function(int offset, int limit);

class PaginationNotifier<T> extends StateNotifier<PaginationState<T>> {
  final FetchItems<T> fetchItems;
  final int limit;
  int _offset = 0;

  PaginationNotifier({
    required this.fetchItems,
    this.limit = 20,
  }) : super(PaginationState<T>(items: const []));

  Future<void> fetchFirstPage() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null, clearError: true);
    try {
      _offset = 0;
      final newItems = await fetchItems(_offset, limit);
      if (!mounted) return;
      state = state.copyWith(
        items: newItems,
        isLoading: false,
        hasMore: newItems.length >= limit,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchNextPage() async {
    if (!mounted || state.isLoading || state.isFetchingMore || !state.hasMore) return;
    state = state.copyWith(isFetchingMore: true, error: null, clearError: true);
    try {
      _offset += limit;
      final newItems = await fetchItems(_offset, limit);
      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isFetchingMore: false,
        hasMore: newItems.length >= limit,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isFetchingMore: false, error: e.toString());
      // Revert offset on failure so we can try again
      _offset -= limit;
    }
  }

  void refresh() {
    fetchFirstPage();
  }
}
