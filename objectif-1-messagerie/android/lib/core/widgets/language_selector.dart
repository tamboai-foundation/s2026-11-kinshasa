import 'package:ngoma/core/widgets/wouanda_choice.dart';
import 'package:flutter/material.dart';
import 'wouanda_min_size.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngoma/core/i18n/translations.dart';

import 'package:ngoma/core/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LanguageSelector extends ConsumerWidget {
  final Color? color;
  final bool transparent;

  const LanguageSelector({super.key, this.color, this.transparent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    final List<Widget> children = [
      Text(
        currentLanguage.code.toUpperCase(),
        style: AppTheme.font(
          color: color ?? context.palette.onAccent,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(width: 4),
      Icon(
        LucideIcons.chevronDown,
        size: 16,
        color: (color ?? context.palette.onAccent).withValues(alpha: 0.7),
      ),
    ];

    void onPressed() {
      () async {
        final code = await showWouandaChoices<String>(
          context,
          title: currentLanguage.t('choose_language'),
          selected: currentLanguage.code,
          choices: [
            for (final lang in supportedLocales)
              WouandaChoice(
                value: lang.code,
                label: '${lang.flag}  ${lang.nativeName}',
              ),
          ],
        );
        if (code != null) {
          ref.read(languageProvider.notifier).setLanguageByCode(code);
        }
      }();
    }

    if (transparent) {
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
        // 48 dp tall tap area around a small label.
        child: WouandaMinSize(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
            side: BorderSide(
              color: (color ?? context.palette.onMedia).withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
