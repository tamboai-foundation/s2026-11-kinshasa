import 'package:flutter/foundation.dart';

/// Non-production demo access for the MVP.
///
/// Debug/profile builds start in the fully provisioned test account so the
/// complete super-app can be exercised without identity verification. Release
/// builds always keep the normal authentication, identity and role checks.
/// Developers can still opt out with `--dart-define=NGOMA_MVP_MODE=false`.
abstract final class NgomaMvpMode {
  static const enabled =
      !kReleaseMode &&
      bool.fromEnvironment('NGOMA_MVP_MODE', defaultValue: false);
}
