import 'package:ngoma/core/platform/wouanda_error_code.dart';
import 'package:flutter/services.dart';

/// Applies to all providers at the composition root. Domain refusals and
/// missing handlers are stable outcomes, not retryable connectivity problems.
Duration? wouandaBridgeRetry(int retryCount, Object error) {
  if (retryCount >= 2 || error is! PlatformException) return null;
  const transient = {
    WouandaErrorCode.offline,
    WouandaErrorCode.serverError,
    'TIMEOUT',
  };
  if (!transient.contains(error.code)) return null;
  return Duration(milliseconds: 500 * (retryCount + 1));
}
