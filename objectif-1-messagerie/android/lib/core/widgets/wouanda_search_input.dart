import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// The one field people type a search into, in every service (an event, a
/// place, an address, a conversation, a help topic).
///
/// What it does by itself, so no screen has to remember it:
/// - a × appears as soon as there is text, and clears it in one tap
///   (`onChanged('')` then [onCleared] are called, the keyboard stays);
/// - the keyboard's action key says « Rechercher »;
/// - the magnifier (or [icon], a pin for a place) leads the field.
///
/// Screens add their own extras with [trailing] (a loader, a map button);
/// the × always comes last. A field that only opens a search screen is
/// `WouandaSearchField` (core/navigation/mini_app_header.dart), which shows
/// the same × through `onClear`.
class WouandaSearchInput extends StatefulWidget {
  const WouandaSearchInput({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.errorText,
    this.icon = LucideIcons.search,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.trailing = const [],
    this.pill = false,
    this.style,
    this.textInputAction = TextInputAction.search,
    this.clearKey,
    this.onTap,
    this.clearable = true,
    this.textCapitalization = TextCapitalization.none,
    this.isDense = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final String? errorText;

  /// [LucideIcons.search] for a search, [LucideIcons.mapPin] for a place;
  /// null when a mark beside the field already says it (Go's A and B).
  final IconData? icon;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// After the × emptied the field (and `onChanged('')` ran).
  final VoidCallback? onCleared;

  /// Extra actions inside the field, before the ×.
  final List<Widget> trailing;

  /// The rounded muted look of a search heading a list (inbox, help).
  final bool pill;
  final TextStyle? style;
  final TextInputAction textInputAction;

  /// Lets a screen and its tests find the ×.
  final Key? clearKey;

  final VoidCallback? onTap;

  /// False hides the × (a field of several that is not the one in use).
  final bool clearable;
  final TextCapitalization textCapitalization;
  final bool isDense;

  @override
  State<WouandaSearchInput> createState() => _WouandaSearchInputState();
}

class _WouandaSearchInputState extends State<WouandaSearchInput> {
  TextEditingController? _own;
  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _clear() {
    HapticFeedback.selectionClick();
    _controller.clear();
    widget.onChanged?.call('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const pillBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(WouandaSpacing.radiusPill),
      ),
      borderSide: BorderSide.none,
    );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final hasText =
            value.text.isNotEmpty && widget.enabled && widget.clearable;
        final actions = [
          ...widget.trailing,
          if (hasText)
            IconButton(
              key:
                  widget.clearKey ??
                  const ValueKey('wouanda-search-input-clear'),
              tooltip: 'Effacer',
              onPressed: _clear,
              icon: Icon(LucideIcons.x, size: 18, color: palette.textSecondary),
            ),
        ];
        return TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          textCapitalization: widget.textCapitalization,
          onSubmitted: widget.onSubmitted,
          textInputAction: widget.textInputAction,
          style: widget.style,
          decoration: InputDecoration(
            hintText: widget.hintText,
            labelText: widget.labelText,
            errorText: widget.errorText,
            isDense: widget.isDense,
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20),
            suffixIcon: actions.isEmpty
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: actions),
            fillColor: widget.pill ? palette.surfaceMuted : null,
            filled: widget.pill ? true : null,
            border: widget.pill ? pillBorder : null,
            enabledBorder: widget.pill ? pillBorder : null,
            focusedBorder: widget.pill
                ? OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(WouandaSpacing.radiusPill),
                    ),
                    borderSide: BorderSide(color: palette.accent),
                  )
                : null,
          ),
        );
      },
    );
  }
}
