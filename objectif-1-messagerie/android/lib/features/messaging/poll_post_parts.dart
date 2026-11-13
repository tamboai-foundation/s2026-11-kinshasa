import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wouanda_design/wouanda_design.dart';

import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/features/messaging/messaging_media_viewer.dart';

/// Polls and « Buzz » (contract v5): what the conversation shows of them.

// ─── Poll ────────────────────────────────────────────────────────────

/// The question and 2 to 4 options, or null when abandoned.
Future<(String, List<String>)?> showPollComposer(BuildContext context) =>
    showModalBottomSheet<(String, List<String>)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PollComposer(),
    );

class _PollComposer extends StatefulWidget {
  const _PollComposer();

  @override
  State<_PollComposer> createState() => _PollComposerState();
}

class _PollComposerState extends State<_PollComposer> {
  static const maxOptions = 4;
  final _question = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];

  @override
  void dispose() {
    _question.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  List<String> get _filled => [
    for (final option in _options)
      if (option.text.trim().isNotEmpty) option.text.trim(),
  ];

  bool get _ready => _question.text.trim().isNotEmpty && _filled.length >= 2;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nouveau sondage', style: AppTheme.titleMd()),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('messaging-poll-question'),
              controller: _question,
              autofocus: true,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Question',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  key: ValueKey('messaging-poll-option-$i'),
                  controller: _options[i],
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Option ${i + 1}',
                    counterText: '',
                    suffixIcon: _options.length > 2
                        ? IconButton(
                            tooltip: 'Retirer',
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () => setState(
                              () => _options.removeAt(i).dispose(),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            if (_options.length < maxOptions)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('messaging-poll-add-option'),
                  onPressed: () =>
                      setState(() => _options.add(TextEditingController())),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Ajouter une option'),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('messaging-poll-send'),
              onPressed: _ready
                  ? () => Navigator.pop(context, (
                      _question.text.trim(),
                      _filled,
                    ))
                  : null,
              child: const Text('Envoyer le sondage'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A poll inside its bubble: options to tap until the account has voted,
/// then the results (a vote is final, as on TikTok).
class MessagePollView extends StatelessWidget {
  const MessagePollView({
    super.key,
    required this.question,
    required this.poll,
    required this.ink,
    required this.meta,
    this.onVote,
  });

  final String question;
  final MessagePollDto poll;
  final Color ink;
  final Color meta;
  final ValueChanged<int>? onVote;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final results = poll.hasVoted || onVote == null;
    return SizedBox(
      width: 260,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(LucideIcons.listChecks, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Sondage',
                  style: AppTheme.caption(
                    color: accent,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              question,
              style: AppTheme.bodyMd(
                color: ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < poll.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: results
                    ? _PollResult(
                        option: poll.options[i],
                        total: poll.total,
                        mine: poll.myVote == i,
                        ink: ink,
                      )
                    : _PollChoice(
                        key: ValueKey('messaging-poll-choice-$i'),
                        label: poll.options[i].label,
                        ink: ink,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onVote!(i);
                        },
                      ),
              ),
            Text(
              results
                  ? '${poll.total} vote${poll.total > 1 ? 's' : ''}'
                  : 'Votez pour voir les résultats',
              style: AppTheme.caption(color: meta),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollChoice extends StatelessWidget {
  const _PollChoice({
    super.key,
    required this.label,
    required this.ink,
    required this.onTap,
  });
  final String label;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    shape: StadiumBorder(
      side: BorderSide(color: context.palette.accent.withValues(alpha: .6)),
    ),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodySm(color: ink),
          ),
        ),
      ),
    ),
  );
}

class _PollResult extends StatelessWidget {
  const _PollResult({
    required this.option,
    required this.total,
    required this.mine,
    required this.ink,
  });
  final MessagePollOptionDto option;
  final int total;
  final bool mine;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final share = total == 0 ? 0.0 : option.votes / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(WouandaSpacing.radiusSmall),
      child: Stack(
        children: [
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: share,
              child: ColoredBox(
                color: accent.withValues(alpha: mine ? .32 : .16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if (mine) ...[
                  Icon(LucideIcons.circleCheck, size: 15, color: accent),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: AppTheme.bodySm(color: ink).copyWith(
                      fontWeight: mine ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  '${(share * 100).round()} %',
                  style: AppTheme.caption(color: ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Buzz ────────────────────────────────────────────────────────────

/// The mark of a Buzz on top of its bubble.
class MessagePostChip extends StatelessWidget {
  const MessagePostChip({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            'Buzz',
            style: AppTheme.caption(
              color: accent,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Several photos and videos of a Buzz scroll sideways, « 1/3 » on top.
class MessagePostMedia extends StatefulWidget {
  const MessagePostMedia({
    super.key,
    required this.media,
    this.onTap,
    this.width = 260,
    this.height = 210,
  });

  final List<MessageAttachmentDto> media;
  final ValueChanged<MessageAttachmentDto>? onTap;
  final double width;
  final double height;

  @override
  State<MessagePostMedia> createState() => _MessagePostMediaState();
}

class _MessagePostMediaState extends State<MessagePostMedia> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: media.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => MessagingAttachmentPreview(
              attachment: media[index],
              cacheWidth: 640,
              onTap: widget.onTap == null
                  ? null
                  : () => widget.onTap!(media[index]),
            ),
          ),
          if (media.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    '${_page + 1}/${media.length}',
                    style: AppTheme.caption(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Under a Buzz: what it gathered, and the way into its space.
class MessagePostFooter extends StatelessWidget {
  const MessagePostFooter({
    super.key,
    required this.message,
    required this.ink,
    required this.meta,
    this.onOpen,
  });

  final UnifiedMessageDto message;
  final Color ink;
  final Color meta;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final reactions = message.reactions.fold<int>(
      0,
      (sum, item) => sum + item.count,
    );
    final comments = message.post?.comments ?? 0;
    return InkWell(
      key: ValueKey('messaging-post-open-${message.id}'),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: SizedBox(
          width: 236,
          child: Row(
            children: [
              Icon(LucideIcons.heart, size: 14, color: meta),
              const SizedBox(width: 4),
              Text('$reactions', style: AppTheme.caption(color: meta)),
              const SizedBox(width: 12),
              Icon(LucideIcons.messageCircle, size: 14, color: meta),
              const SizedBox(width: 4),
              Text('$comments', style: AppTheme.caption(color: meta)),
              const Spacer(),
              Text(
                'Ouvrir',
                style: AppTheme.caption(
                  color: context.palette.accent,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: context.palette.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
