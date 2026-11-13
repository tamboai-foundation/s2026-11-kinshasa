import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ngoma/core/i18n/l10n.dart';

import 'wouanda_platform_widgets.dart';

/// What a list or a page shows when it could not load: say it plainly, say
/// what to do, and offer the retry right there. Never a lone « Réessayer »
/// text button floating in an empty page.
///
/// Wording is the same in every service; pass [title] and [message] only where
/// the thing that failed is worth naming (« Réservations indisponibles »).
class WouandaErrorState extends StatelessWidget {
  const WouandaErrorState({
    super.key,
    required this.onRetry,
    this.title,
    this.message,
    this.icon = LucideIcons.circleAlert,
    this.retryLabel,
    this.compact = false,
  });

  final VoidCallback onRetry;

  /// The shared wording in the app language when null.
  final String? title;
  final String? message;
  final String? retryLabel;
  final IconData icon;

  /// Smaller drawing, for a section inside a page rather than the whole page.
  final bool compact;

  @override
  Widget build(BuildContext context) => WouandaEmptyState(
    icon: icon,
    illustrationSize: compact ? 72 : 104,
    title: title ?? context.l10n.errorStateTitle,
    message: message ?? context.l10n.errorStateMessage,
    actionLabel: retryLabel ?? context.l10n.errorStateRetry,
    onAction: onRetry,
  );
}
