import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_tappable.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:ngoma/core/theme.dart';
import 'package:wouanda_foundation/wouanda_foundation.dart';
import 'package:ngoma/core/platform/wouanda_error_code.dart';

/// Global error handler widget
/// Wraps screens to catch and display errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(AppError error, VoidCallback retry)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(
          _error!,
          () => setState(() => _error = null),
        );
      }
      return WouandaErrorScreen(
        error: _error!,
        onRetry: () => setState(() => _error = null),
      );
    }
    return widget.child;
  }
}

/// Premium error screen with retry capability
class WouandaErrorScreen extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const WouandaErrorScreen({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _getErrorVisual(error, isDark);

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon with glow
                Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(data.icon, size: 48, color: data.color),
                    )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack)
                    .then()
                    .shake(
                      delay: 200.ms,
                      duration: 400.ms,
                      hz: 3,
                      offset: Offset(2, 0),
                    ),
                SizedBox(height: 32),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.getTextPrimary(isDark),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                SizedBox(height: 12),
                Text(
                  error.userMessage ?? error.message,
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    fontSize: 14,
                    color: AppTheme.getTextSecondary(isDark),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                SizedBox(height: 8),
                // Error code
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.getCard(isDark),
                    borderRadius: BorderRadius.circular(
                      WouandaSpacing.radiusSmall,
                    ),
                    border: Border.all(
                      color: AppTheme.getBorder(isDark).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Code: ${error.code}',
                    style: AppTheme.font(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(isDark),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                SizedBox(height: 32),
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: Icon(LucideIcons.refreshCw),
                      label: Text(
                        'Réessayer',
                        style: AppTheme.font(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: data.color,
                        foregroundColor: context.palette.onAccent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            WouandaSpacing.radiusMedium,
                          ),
                          side: BorderSide(
                            color: context.palette.border.withValues(
                              alpha: 0.1,
                            ),
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    'Retour',
                    style: AppTheme.font(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextSecondary(isDark),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ErrorVisual _getErrorVisual(AppError error, bool isDark) {
    switch (error.code) {
      case 'NETWORK_ERROR':
        return _ErrorVisual(
          title: 'Connexion perdue',
          icon: LucideIcons.wifiOff,
          color: AppTheme.warningFor(isDark),
        );
      case 'UNAUTHORIZED':
        return _ErrorVisual(
          title: 'Accès refusé',
          icon: LucideIcons.lock,
          color: AppTheme.wouandaLove,
        );
      case WouandaErrorCode.notFound:
        return _ErrorVisual(
          title: 'Introuvable',
          icon: LucideIcons.searchX,
          color: AppTheme.info,
        );
      case WouandaErrorCode.serverError:
        return _ErrorVisual(
          title: 'Erreur serveur',
          icon: LucideIcons.cloudOff,
          color: AppTheme.error,
        );
      case 'TIMEOUT':
        return _ErrorVisual(
          title: 'Temps écoulé',
          icon: LucideIcons.timerOff,
          color: AppTheme.warningFor(isDark),
        );
      case 'INSUFFICIENT_FUNDS':
        return _ErrorVisual(
          title: 'Solde insuffisant',
          icon: LucideIcons.wallet,
          color: AppTheme.wouandaShop,
        );
      default:
        return _ErrorVisual(
          title: 'Oups !',
          icon: LucideIcons.circleAlert,
          color: AppTheme.error,
        );
    }
  }
}

class _ErrorVisual {
  final String title;
  final IconData icon;
  final Color color;
  _ErrorVisual({required this.title, required this.icon, required this.color});
}

/// Inline error widget for smaller error displays
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Color? color;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = color ?? AppTheme.error;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
        border: Border.all(color: errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: errorColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.font(
                fontSize: 13,
                color: AppTheme.getTextPrimary(isDark),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            WouandaTappable(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    WouandaSpacing.radiusSmall,
                  ),
                ),
                child: Text(
                  'Réessayer',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: errorColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Snackbar helper for quick error/success messages
class WouandaSnackbar {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              LucideIcons.circleAlert,
              color: context.palette.onAccent,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTheme.font(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              LucideIcons.circleCheck,
              color: context.palette.onAccent,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTheme.font(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.info, color: context.palette.onAccent, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTheme.font(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              LucideIcons.triangleAlert,
              color: context.palette.onAccent,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTheme.font(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
