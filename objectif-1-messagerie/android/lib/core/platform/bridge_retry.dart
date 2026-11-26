import 'package:ngoma/core/platform/ngoma_error_code.dart';
import 'package:flutter/services.dart';

/// Applies to all providers at the composition root. Domain refusals and
/// missing handlers are stable outcomes, not retryable connectivity problems.
Duration? ngomaBridgeRetry(int retryCount, Object error) {
  if (retryCount >= 2 || error is! PlatformException) return null;
  const transient = {
    NgomaErrorCode.offline,
    NgomaErrorCode.serverError,
    'TIMEOUT',
  };
  if (!transient.contains(error.code)) return null;
  return Duration(milliseconds: 500 * (retryCount + 1));
}
