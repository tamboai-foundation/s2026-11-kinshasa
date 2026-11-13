import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_draggable_sheet.dart';
import 'package:ngoma/core/widgets/wouanda_list.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// One option of a choice: what is picked, how it reads, an optional icon.
@immutable
class WouandaChoice<T> {
  const WouandaChoice({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  /// An action that removes something (« Supprimer »): said in red.
  final bool destructive;
}

/// The one way the app offers a list of choices (a category, a gender, an
/// action on a row): a Wouanda sheet from the bottom, its title, the options
/// as rows the thumb reaches, a check on the current one. Never a Material
/// drop-down or pop-up menu, whose colours and shapes are not ours.
Future<T?> showWouandaChoices<T>(
  BuildContext context, {
  required String title,
  required List<WouandaChoice<T>> choices,
  T? selected,
}) => showWouandaSheet<T>(
  context,
  showDragHandle: true,
  builder: (sheetContext) {
    final palette = sheetContext.palette;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WouandaSpacing.pageGutter,
                0,
                WouandaSpacing.pageGutter,
                8,
              ),
              child: Text(title, style: AppTheme.h3()),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final choice in choices)
                    WouandaListRow(
                      key: ValueKey('choice-${choice.value}'),
                      icon: choice.destructive ? null : choice.icon,
                      leading: choice.destructive && choice.icon != null
                          ? Icon(choice.icon, color: palette.negative)
                          : null,
                      title: choice.label,
                      subtitle: choice.subtitle,
                      trailing: choice.value == selected
                          ? Icon(
                              LucideIcons.check,
                              size: 20,
                              color: palette.accent,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(sheetContext).pop(choice.value);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// A form field that holds one choice: it looks like every text field of the
/// app (the theme's own input decoration), shows the current option, and
/// opens [showWouandaChoices] when touched.
class WouandaChoiceField<T> extends StatelessWidget {
  const WouandaChoiceField({
    super.key,
    required this.label,
    required this.choices,
    required this.value,
    required this.onChanged,
    this.hint,
    this.icon,
    this.errorText,
    this.labelInside = true,
  });

  final String label;

  /// False when the form already prints its labels above the fields: the
  /// label then only titles the sheet.
  final bool labelInside;
  final List<WouandaChoice<T>> choices;
  final T? value;

  /// Null: the field is shown disabled.
  final ValueChanged<T>? onChanged;
  final String? hint;
  final IconData? icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final current = choices.where((c) => c.value == value).firstOrNull;
    final enabled = onChanged != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label, ${current?.label ?? hint ?? 'aucun choix'}',
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
          onTap: !enabled
              ? null
              : () async {
                  final picked = await showWouandaChoices<T>(
                    context,
                    title: label,
                    choices: choices,
                    selected: value,
                  );
                  if (picked != null) onChanged!(picked);
                },
          child: InputDecorator(
            isEmpty: current == null,
            decoration: InputDecoration(
              labelText: labelInside ? label : null,
              hintText: hint,
              errorText: errorText,
              enabled: enabled,
              prefixIcon: icon == null ? null : Icon(icon),
              suffixIcon: Icon(
                LucideIcons.chevronDown,
                size: 20,
                color: palette.textSecondary,
              ),
            ),
            child: current == null
                ? null
                : Text(
                    current.label,
                    maxLines: null,
                    softWrap: true,
                    style: AppTheme.bodyMd(color: palette.textPrimary),
                  ),
          ),
        ),
      ),
    );
  }
}
