import 'package:ngoma/core/widgets/wouanda_draggable_sheet.dart';
import 'package:flutter/material.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ngoma/core/theme.dart';

class AuthRequiredSheet extends StatelessWidget {
  final String action;
  final String? returnTo;
  final String? title;
  final String? message;
  final String? primaryLabel;
  final String? primaryRoute;

  const AuthRequiredSheet({
    super.key,
    required this.action,
    this.returnTo,
    this.title,
    this.message,
    this.primaryLabel,
    this.primaryRoute,
  });

  static Future<void> show(
    BuildContext context,
    String action, {
    String? returnTo,
    String? title,
    String? message,
    String? primaryLabel,
    String? primaryRoute,
  }) {
    return showWouandaSheet(
      context,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthRequiredSheet(
        action: action,
        returnTo: returnTo,
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        primaryRoute: primaryRoute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final router = GoRouter.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(isDark),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(WouandaSpacing.radiusLarge),
          ),
          border: Border.all(
            color: AppTheme.getBorder(isDark).withValues(alpha: 0.45),
          ),
          boxShadow: WouandaElevation.card(Theme.of(context).brightness),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getBorder(isDark),
                  borderRadius: BorderRadius.circular(WouandaSpacing.radiusXs),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.getTextPrimary(isDark),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.lockKeyhole,
                    color: isDark
                        ? context.palette.textPrimary
                        : context.palette.onAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? 'Compte Wouanda requis',
                        style: AppTheme.h2(
                          color: AppTheme.getTextPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message ??
                            'Vous pouvez explorer librement. Pour $action, connectez-vous avec votre compte unique Wouanda.',
                        style: AppTheme.bodyMd(
                          color: AppTheme.getTextSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  final route = primaryRoute ?? '/auth';
                  if (route == '/auth') {
                    router.push(
                      route,
                      extra: {'returnTo': returnTo, 'returnToPrevious': true},
                    );
                  } else {
                    router.push(route);
                  }
                },
                icon: Icon(
                  primaryRoute == null || primaryRoute == '/auth'
                      ? LucideIcons.logIn
                      : LucideIcons.arrowRight,
                  size: 19,
                ),
                label: Text(primaryLabel ?? 'Se connecter'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Plus tard'),
            ),
          ],
        ),
      ),
    );
  }
}
