import 'package:ngoma/core/i18n/l10n.dart';

/// The words of a one-tap message (go v1.17): the bridge sends codes, the app
/// writes them in the reader's language. An unknown code is shown as it is,
/// never hidden. [landmark] completes `at_landmark` when the pickup has one.
String messagingQuickReplyLabel(
  AppLocalizations l10n,
  String code, {
  String? landmark,
}) => switch (code) {
  'coming' => l10n.quickReplyComing,
  'traffic' => l10n.quickReplyTraffic,
  'where_exactly' => l10n.quickReplyWhereExactly,
  'arrived' => l10n.quickReplyArrived,
  'waiting_front' => l10n.quickReplyWaitingFront,
  'call_me' => l10n.quickReplyCallMe,
  'coming_down' => l10n.quickReplyComingDown,
  'wait_2min' => l10n.quickReplyWait2min,
  'at_landmark' when landmark?.trim().isNotEmpty == true =>
    l10n.quickReplyAtLandmarkWith(landmark!.trim()),
  'at_landmark' => l10n.quickReplyAtLandmark,
  _ => code,
};
