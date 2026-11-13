import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'bridge_batch.dart';

/// Shared list presentation for every bridge that returns batches.
class BridgeListState<T> {
  const BridgeListState({
    this.items = const [],
    this.loading = false,
    this.hasMore = false,
    this.error,
    this.summary = const {},
  });
  final List<T> items;
  final bool loading, hasMore;
  final Object? error;
  final Map<String, dynamic> summary;
}

class BridgeListNotifier<T> extends StateNotifier<BridgeListState<T>> {
  BridgeListNotifier(
    this.read, {
    Stream<String>? signals,
    Set<String> refreshOn = const {},
  }) : super(const BridgeListState()) {
    _signals = signals?.listen(
      (key) {
        if (refreshOn.contains(key)) load();
      },
      onError: (Object _) {
        load();
      },
    );
    load();
  }
  final Future<BridgeBatch<T>> Function(bool more) read;
  StreamSubscription<String>? _signals;
  int _revision = 0;
  Future<void> _reading = Future.value();
  Future<BridgeListState<T>> get future async {
    while (mounted) {
      final pending = _reading;
      await pending;
      if (identical(pending, _reading)) break;
    }
    return mounted ? state : const BridgeListState();
  }

  Future<void> load() {
    _reading = _load(false);
    return future.then((_) {});
  }

  Future<void> loadMore() {
    if (state.loading || !state.hasMore) return _reading;
    return _reading = _load(true);
  }

  Future<void> _load(bool more) async {
    if (more && (state.loading || !state.hasMore)) return;
    final revision = ++_revision;
    state = BridgeListState(
      items: more ? state.items : [],
      loading: true,
      hasMore: more && state.hasMore,
      summary: state.summary,
    );
    try {
      final batch = await read(more);
      if (!mounted || revision != _revision) return;
      state = BridgeListState(
        items: [...state.items, ...batch.items],
        hasMore: batch.hasMore,
        summary: batch.summary.isEmpty ? state.summary : batch.summary,
      );
    } catch (error) {
      if (mounted && revision == _revision) {
        state = BridgeListState(
          items: state.items,
          hasMore: state.hasMore,
          error: error,
          summary: state.summary,
        );
      }
    }
  }

  @override
  void dispose() {
    _signals?.cancel();
    super.dispose();
  }
}
