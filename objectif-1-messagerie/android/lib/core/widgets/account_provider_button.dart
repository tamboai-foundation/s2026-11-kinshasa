import 'package:flutter/material.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:ngoma/core/theme.dart';

/// Original provider assets. The account bridge owns authentication.
class AccountProviderButton extends StatelessWidget {
  const AccountProviderButton({
    super.key,
    required this.provider,
    required this.label,
    required this.onPressed,
    this.loading = false,
  }) : assert(provider == 'google' || provider == 'apple');

  final String provider;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      backgroundColor: WouandaColors.surfaceLight,
      foregroundColor: WouandaColors.textPrimaryLight,
      disabledBackgroundColor: WouandaColors.surfaceLight,
      disabledForegroundColor: WouandaColors.textSecondaryLight,
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: const BorderSide(color: WouandaColors.textSecondaryLight),
      textStyle: AppTheme.bodyMd(fontWeight: FontWeight.w600),
    ),
    onPressed: onPressed,
    child: Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: loading
                ? const WouandaBusyBar(size: 20)
                : OverflowBox(
                    maxWidth: 44,
                    maxHeight: 44,
                    child: ExcludeSemantics(
                      child: Image.asset(
                        'assets/images/auth/$provider.png',
                        // Apple's official logo-only asset includes padding.
                        width: provider == 'apple' ? 44 : 20,
                        height: provider == 'apple' ? 44 : 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}
