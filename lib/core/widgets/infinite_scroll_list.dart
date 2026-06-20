import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pagination/pagination_state.dart';
import '../../core/theme/app_theme.dart';

class InfiniteScrollList<T> extends ConsumerStatefulWidget {
  final StateNotifierProvider<PaginationNotifier<T>, PaginationState<T>> provider;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget? emptyState;
  final Widget? filterWidget;
  final EdgeInsetsGeometry padding;

  const InfiniteScrollList({
    super.key,
    required this.provider,
    required this.itemBuilder,
    this.emptyState,
    this.filterWidget,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 100),
  });

  @override
  ConsumerState<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends ConsumerState<InfiniteScrollList<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial fetch is usually done when the provider is initialized,
    // but we can ensure it is loaded by checking state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(widget.provider);
      if (state.items.isEmpty && !state.isLoading && state.error == null) {
        ref.read(widget.provider.notifier).fetchFirstPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(widget.provider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);

    return Column(
      children: [
        if (widget.filterWidget != null) widget.filterWidget!,
        Expanded(
          child: _buildContent(state),
        ),
      ],
    );
  }

  Widget _buildContent(PaginationState<T> state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}', style: const TextStyle(color: AppTheme.errorRed)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(widget.provider.notifier).refresh(),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return widget.emptyState ?? const Center(child: Text('No items found.'));
    }

    return RefreshIndicator(
      color: AppTheme.ink900,
      onRefresh: () async {
        await ref.read(widget.provider.notifier).fetchFirstPage();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: state.items.length + (state.isFetchingMore ? 1 : 0),
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
            );
          }
          return widget.itemBuilder(context, state.items[index]);
        },
      ),
    );
  }
}
