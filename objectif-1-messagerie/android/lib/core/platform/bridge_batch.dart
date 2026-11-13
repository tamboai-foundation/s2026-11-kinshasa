import 'package:flutter/services.dart';
import 'wouanda_error_code.dart';

/// One native TFlow batch. The controller retains the cursor; Flutter appends
/// only these items and renders placebo rows while the next call is pending.
class BridgeBatch<T> {
  const BridgeBatch({
    required this.items,
    required this.hasMore,
    this.summary = const {},
  });
  final List<T> items;
  final bool hasMore;
  final Map<String, dynamic> summary;

  factory BridgeBatch.fromMap(
    Map raw,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (raw['items'] is! List || raw['hasMore'] is! bool) {
      throw PlatformException(
        code: WouandaErrorCode.serverError,
        message: 'Invalid batch snapshot',
      );
    }
    return BridgeBatch(
      items: [
        for (final item in raw['items'] as List)
          decode(Map<String, dynamic>.from(item as Map)),
      ],
      hasMore: raw['hasMore'] as bool,
      summary: Map<String, dynamic>.from(raw['summary'] as Map? ?? const {}),
    );
  }
}
