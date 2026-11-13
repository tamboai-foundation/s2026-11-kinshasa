import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:ngoma/core/theme.dart';

/// One bubble surface for service conversations and the Wouanda inbox.
/// Rich content stays with its adapter; geometry and colour stay here.
class WouandaMessageBubbleFrame extends StatelessWidget {
  const WouandaMessageBubbleFrame({
    super.key,
    required this.isMine,
    required this.child,
    this.firstOfGroup = true,
    this.lastOfGroup = true,
  });
  final bool isMine;
  final bool firstOfGroup;
  final bool lastOfGroup;
  final Widget child;

  /// Outgoing bubbles are a soft tint of the accent, not a saturated fill:
  /// a dark block under every sent message tires the eyes (charter §12).
  static Color fillOf(BuildContext context, bool isMine) => isMine
      ? Color.alphaBlend(
          context.palette.accent.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .2 : .12,
          ),
          context.palette.surface,
        )
      : context.palette.surface;

  /// Text colour on [fillOf]; the same for both sides, so it always reads.
  static Color inkOf(BuildContext context) => context.palette.textPrimary;

  /// Time, ticks and secondary lines on a bubble.
  static Color metaOf(BuildContext context) => context.palette.textTertiary;

  @override
  Widget build(BuildContext context) {
    const big = Radius.circular(WouandaSpacing.radiusLarge);
    const small = Radius.circular(WouandaSpacing.radiusSmall);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: firstOfGroup ? 8 : 2,
          left: isMine ? 40 : 0,
          right: isMine ? 0 : 40,
        ),
        decoration: BoxDecoration(
          color: fillOf(context, isMine),
          border: isMine ? null : Border.all(color: context.palette.border),
          borderRadius: BorderRadius.only(
            topLeft: !isMine && !firstOfGroup ? small : big,
            bottomLeft: !isMine && !lastOfGroup ? small : big,
            topRight: isMine && !firstOfGroup ? small : big,
            bottomRight: isMine && !lastOfGroup ? small : big,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

// ─── Composer ────────────────────────────────────────────────────────

/// WhatsApp-style composer: a rounded field with attach and camera inside,
/// and one round action that is the microphone when empty, send otherwise.
class WouandaConversationComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool hasDraft;
  final bool busy;
  final bool canAttach;
  final bool canUseCamera;
  final bool canRecord;
  final VoidCallback onChanged;
  final int? maxLength;
  final VoidCallback onAttach;
  final VoidCallback onCamera;
  final VoidCallback onRecord;
  final VoidCallback onSend;
  final FocusNode? focusNode;

  /// Editing a message shows a check instead of the paper plane.
  final IconData sendIcon;
  final String sendTooltip;
  final String hintText;

  const WouandaConversationComposer({
    super.key,
    required this.controller,
    required this.hasDraft,
    required this.busy,
    required this.canAttach,
    required this.canUseCamera,
    required this.canRecord,
    required this.onChanged,
    required this.onAttach,
    required this.onCamera,
    required this.onRecord,
    required this.onSend,
    this.maxLength,
    this.focusNode,
    this.sendIcon = LucideIcons.send,
    this.sendTooltip = 'Envoyer',
    this.hintText = 'Message',
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = WouandaColors.textSecondary(brightness);
    final showSend = hasDraft || !canRecord;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: WouandaColors.surface(brightness),
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
              border: Border.all(color: WouandaColors.border(brightness)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLength: maxLength,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: (_) => onChanged(),
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTheme.bodyMd(
                      color: WouandaColors.textPrimary(brightness),
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      counterText: '',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      hintStyle: AppTheme.bodyMd(color: muted),
                    ),
                  ),
                ),
                if (canAttach)
                  IconButton(
                    tooltip: 'Joindre',
                    onPressed: busy ? null : onAttach,
                    icon: Icon(LucideIcons.paperclip, size: 20, color: muted),
                  ),
                if (canUseCamera && !hasDraft)
                  IconButton(
                    tooltip: 'Photo',
                    onPressed: busy ? null : onCamera,
                    icon: Icon(LucideIcons.camera, size: 20, color: muted),
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox.square(
          dimension: 48,
          child: IconButton.filled(
            tooltip: showSend ? sendTooltip : 'Message vocal',
            style: IconButton.styleFrom(
              backgroundColor: context.palette.accent,
              foregroundColor: context.palette.onAccent,
            ),
            onPressed: busy || (showSend && !hasDraft)
                ? null
                : (showSend ? onSend : onRecord),
            icon: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : WouandaMotion.fast,
              child: busy
                  ? const WouandaBusyBar(size: 20)
                  : Icon(
                      showSend ? sendIcon : LucideIcons.mic,
                      key: ValueKey(showSend),
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
