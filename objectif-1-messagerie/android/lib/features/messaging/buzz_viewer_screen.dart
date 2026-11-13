import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:wouanda_design/wouanda_design.dart';

import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/providers/messaging_provider.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_image.dart';
import 'package:ngoma/core/widgets/wouanda_loading_state.dart';
import 'package:ngoma/core/widgets/wouanda_platform_widgets.dart';
import 'package:ngoma/features/messaging/conversation_parts.dart';
import 'package:ngoma/features/messaging/messaging_document_viewer.dart';
import 'package:ngoma/features/messaging/messaging_media_viewer.dart';
import 'package:ngoma/features/messaging/messaging_service_style.dart';

/// The reaction a double tap gives, and the heart of the action bar.
const _like = 'heart';

bool _isBuzz(UnifiedMessageDto message) => message.isPost && !message.isDeleted;

String _ago(DateTime at) {
  final diff = DateTime.now().difference(at.toLocal());
  if (diff.inMinutes < 1) return 'à l’instant';
  if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  final local = at.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

/// v5: the Buzz of a conversation, full screen. Its media scroll sideways,
/// the other Buzz of the conversation up and down; a double tap likes it,
/// its comments (the messages of its public space) rise in a sheet.
class BuzzViewerScreen extends ConsumerStatefulWidget {
  const BuzzViewerScreen({
    super.key,
    required this.conversation,
    required this.initial,
  });

  /// Where the Buzz were posted.
  final UnifiedConversationDto conversation;
  final UnifiedMessageDto initial;

  static Future<void> open(
    BuildContext context, {
    required UnifiedConversationDto conversation,
    required UnifiedMessageDto post,
  }) => Navigator.of(context).push<void>(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) =>
          BuzzViewerScreen(conversation: conversation, initial: post),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  ConsumerState<BuzzViewerScreen> createState() => _BuzzViewerScreenState();
}

class _BuzzViewerScreenState extends ConsumerState<BuzzViewerScreen> {
  /// The Buzz in the order of the opening, newest first: a new one arriving
  /// does not move the page being watched.
  late final List<int> _ids;
  late final PageController _pages;
  late int _current;
  final Map<int, Future<UnifiedConversationDto>> _spaces = {};

  int get _cid => widget.conversation.id;

  ConversationMessagesNotifier get _notifier =>
      ref.read(conversationMessagesProvider(_cid).notifier);

  @override
  void initState() {
    super.initState();
    final posts = ref
        .read(conversationMessagesProvider(_cid))
        .messages
        .where(_isBuzz)
        .toList()
        .reversed;
    _ids = [for (final post in posts) post.id];
    if (!_ids.contains(widget.initial.id)) _ids.insert(0, widget.initial.id);
    _current = _ids.indexOf(widget.initial.id);
    _pages = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _say(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _react(UnifiedMessageDto post, String key) async {
    HapticFeedback.selectionClick();
    try {
      await _notifier.react(post, key);
    } on Object {
      if (mounted) _say('Réaction impossible pour le moment.');
    }
  }

  void _likeOnce(UnifiedMessageDto post) {
    final mine = post.reactions.where((r) => r.isMine).firstOrNull?.key;
    if (mine != _like) unawaited(_react(post, _like));
  }

  Future<UnifiedConversationDto> _space(UnifiedMessageDto post) =>
      _spaces.putIfAbsent(post.id, () {
        final future = _notifier.openPostSpace(post);
        // A failed opening is tried again next time.
        future.catchError((Object _) {
          _spaces.remove(post.id);
          return widget.conversation;
        });
        return future;
      });

  Future<void> _openComments(UnifiedMessageDto post) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BuzzComments(post: post, space: () => _space(post)),
      );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(conversationMessagesProvider(_cid));
    final byId = {for (final m in state.messages) m.id: m};
    final conversation = state.conversation ?? widget.conversation;
    final keys =
        ref.watch(messagingCapabilitiesProvider).value?.reactions ??
        const <String>[];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: palette.media,
        body: Stack(
          children: [
            PageView.builder(
              key: const ValueKey('buzz-viewer-pages'),
              controller: _pages,
              scrollDirection: Axis.vertical,
              itemCount: _ids.length,
              onPageChanged: (page) => setState(() => _current = page),
              itemBuilder: (context, index) {
                final id = _ids[index];
                final post =
                    byId[id] ?? (id == widget.initial.id ? widget.initial : null);
                if (post == null || post.isDeleted) {
                  return Center(
                    child: Text(
                      'Ce Buzz n’est plus disponible.',
                      style: AppTheme.bodyMd(color: palette.onMedia),
                    ),
                  );
                }
                return _BuzzPage(
                  key: ValueKey('buzz-$id'),
                  post: post,
                  conversation: conversation,
                  reactions: keys,
                  active: index == _current,
                  onLike: () => _likeOnce(post),
                  onReact: (key) => _react(post, key),
                  onComments: () => _openComments(post),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('buzz-viewer-close'),
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(LucideIcons.arrowLeft, color: palette.onMedia),
                    ),
                    Icon(LucideIcons.flame, size: 16, color: palette.onMedia),
                    const SizedBox(width: 6),
                    Text(
                      'Buzz',
                      style: AppTheme.bodyMd(
                        color: palette.onMedia,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (_ids.length > 1) ...[
                      const Spacer(),
                      Text(
                        '${_current + 1} sur ${_ids.length}',
                        style: AppTheme.caption(color: palette.onMediaMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuzzPage extends StatefulWidget {
  const _BuzzPage({
    super.key,
    required this.post,
    required this.conversation,
    required this.reactions,
    required this.active,
    required this.onLike,
    required this.onReact,
    required this.onComments,
  });

  final UnifiedMessageDto post;
  final UnifiedConversationDto conversation;
  final List<String> reactions;
  final bool active;
  final VoidCallback onLike;
  final ValueChanged<String> onReact;
  final VoidCallback onComments;

  @override
  State<_BuzzPage> createState() => _BuzzPageState();
}

class _BuzzPageState extends State<_BuzzPage> {
  int _media = 0;
  bool _expanded = false;
  bool _picking = false;
  Offset? _tap;
  final List<(int, Offset)> _hearts = [];
  int _heartSeq = 0;

  void _doubleTap() {
    final at = _tap;
    widget.onLike();
    if (at == null) return;
    setState(() => _hearts.add((_heartSeq++, at)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final post = widget.post;
    final visual = post.attachments.where(isVisualAttachment).toList();
    final others = post.attachments
        .where((a) => !isVisualAttachment(a))
        .toList();
    final mine = post.reactions.where((r) => r.isMine).firstOrNull?.key;
    final likes =
        post.reactions.where((r) => r.key == _like).firstOrNull?.count ?? 0;
    final otherReactions = post.reactions.where((r) => r.key != _like).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final author = post.isMine ? 'Vous' : post.senderLabel;
    final textOnly = visual.isEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) => _tap = details.localPosition,
      onDoubleTap: _doubleTap,
      onTap: _picking ? () => setState(() => _picking = false) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (textOnly)
            _TextBackdrop(text: post.content)
          else
            PageView.builder(
              key: ValueKey('buzz-media-${post.id}'),
              itemCount: visual.length,
              onPageChanged: (page) => setState(() => _media = page),
              itemBuilder: (context, index) {
                final attachment = visual[index];
                return attachment.type == 'video'
                    ? _BuzzVideo(
                        attachment: attachment,
                        active: widget.active && index == _media,
                      )
                    : Center(
                        child: MessagingAttachmentPreview(
                          attachment: attachment,
                          fit: BoxFit.contain,
                        ),
                      );
              },
            ),
          // Legibility of the overlays on any picture.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, .14, .55, 1],
                  colors: [
                    palette.media.withValues(alpha: .55),
                    palette.media.withValues(alpha: 0),
                    palette.media.withValues(alpha: 0),
                    palette.media.withValues(alpha: .78),
                  ],
                ),
              ),
            ),
          ),
          for (final (seq, at) in _hearts)
            _BurstHeart(
              key: ValueKey('heart-$seq'),
              at: at,
              onDone: () => setState(() => _hearts.removeWhere((h) => h.$1 == seq)),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final attachment in others)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OtherAttachment(
                          attachment: attachment,
                          all: post.attachments,
                        ),
                      ),
                    _Author(
                      name: author,
                      conversation: widget.conversation,
                      at: post.createdAt,
                    ),
                    if (!textOnly && post.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        key: ValueKey('buzz-caption-${post.id}'),
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * .3,
                          ),
                          child: SingleChildScrollView(
                            physics: _expanded
                                ? null
                                : const NeverScrollableScrollPhysics(),
                            child: Text(
                              post.content,
                              maxLines: _expanded ? null : 2,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: AppTheme.bodyMd(color: palette.onMedia),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (visual.length > 1) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: _Dots(count: visual.length, index: _media),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 160),
                      child: _picking
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ReactionPicker(
                                keys: widget.reactions,
                                mine: mine,
                                onPick: (key) {
                                  setState(() => _picking = false);
                                  widget.onReact(key);
                                },
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    _ActionBar(
                      postId: post.id,
                      liked: mine == _like,
                      likes: likes,
                      otherReactions: otherReactions,
                      myOther: mine != null && mine != _like ? mine : null,
                      comments: post.post?.comments ?? 0,
                      onLike: () => widget.onReact(_like),
                      onReactions: () => setState(() => _picking = !_picking),
                      onComments: widget.onComments,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Buzz without photo or video: its text is the picture.
class _TextBackdrop extends StatelessWidget {
  const _TextBackdrop({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.accent, palette.accent.withValues(alpha: .55)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 120, 32, 220),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTheme.font(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: palette.onMedia,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _Author extends StatelessWidget {
  const _Author({
    required this.name,
    required this.conversation,
    required this.at,
  });
  final String name;
  final UnifiedConversationDto conversation;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        WouandaPersonAvatar(
          name: name,
          radius: 18,
          backgroundColor: palette.onMedia.withValues(alpha: .18),
          foregroundColor: palette.onMedia,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMd(
                  color: palette.onMedia,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    messagingConversationIcon(conversation),
                    size: 12,
                    color: palette.onMediaMuted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'depuis ${conversation.title} · ${_ago(at)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(color: palette.onMediaMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OtherAttachment extends StatelessWidget {
  const _OtherAttachment({required this.attachment, required this.all});
  final MessageAttachmentDto attachment;
  final List<MessageAttachmentDto> all;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final voice = attachment.type == 'voice' || attachment.type == 'audio';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.media.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.onMedia.withValues(alpha: .14)),
      ),
      child: voice
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: MessagingAudioAttachmentPlayer(
                attachment: attachment,
                color: palette.onMedia,
              ),
            )
          : InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => openMessagingAttachment(
                context,
                attachments: all,
                attachment: attachment,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 18,
                      color: palette.onMedia,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        attachment.label.isEmpty
                            ? 'Document'
                            : attachment.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySm(color: palette.onMedia),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: palette.onMediaMuted,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? palette.onMedia
                  : palette.onMedia.withValues(alpha: .4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// One quiet bar under the description: like, the other reactions,
/// the comments.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.postId,
    required this.liked,
    required this.likes,
    required this.otherReactions,
    required this.myOther,
    required this.comments,
    required this.onLike,
    required this.onReactions,
    required this.onComments,
  });

  final int postId;
  final bool liked;
  final int likes;
  final List<MessageReactionDto> otherReactions;
  final String? myOther;
  final int comments;
  final VoidCallback onLike;
  final VoidCallback onReactions;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final others = otherReactions.fold<int>(0, (sum, r) => sum + r.count);
    final label = AppTheme.bodySm(
      color: palette.onMedia,
    ).copyWith(fontWeight: FontWeight.w600);
    Widget divider() => Container(
      width: 1,
      height: 22,
      color: palette.onMedia.withValues(alpha: .16),
    );
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: palette.media.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.onMedia.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          _BarButton(
            key: ValueKey('buzz-like-$postId'),
            onTap: onLike,
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    liked ? Icons.favorite : LucideIcons.heart,
                    key: ValueKey(liked),
                    size: 20,
                    color: liked ? WouandaColors.negative : palette.onMedia,
                  ),
                ),
                const SizedBox(width: 6),
                Text('$likes', style: label),
              ],
            ),
          ),
          divider(),
          _BarButton(
            key: ValueKey('buzz-react-$postId'),
            onTap: onReactions,
            child: Row(
              children: [
                if (otherReactions.isEmpty && myOther == null)
                  Icon(LucideIcons.smilePlus, size: 20, color: palette.onMedia)
                else
                  for (final reaction in [
                    ?myOther,
                    for (final r in otherReactions)
                      if (r.key != myOther) r.key,
                  ].take(3))
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: ReactionGlyph(
                        reaction,
                        size: 17,
                        color: palette.onMedia,
                      ),
                    ),
                if (others > 0) ...[
                  const SizedBox(width: 4),
                  Text('$others', style: label),
                ],
              ],
            ),
          ),
          divider(),
          Expanded(
            child: _BarButton(
              key: ValueKey('buzz-comments-$postId'),
              onTap: onComments,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    size: 19,
                    color: palette.onMedia,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comments > 0 ? 'Commentaires · $comments' : 'Commenter',
                    style: label,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(child: child),
    ),
  );
}

class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({
    required this.keys,
    required this.mine,
    required this.onPick,
  });
  final List<String> keys;
  final String? mine;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: palette.media.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.onMedia.withValues(alpha: .14)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final key in keys)
              InkWell(
                key: ValueKey('buzz-pick-$key'),
                customBorder: const CircleBorder(),
                onTap: () => onPick(key),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: key == mine
                        ? palette.onMedia.withValues(alpha: .2)
                        : Colors.transparent,
                  ),
                  child: ReactionGlyph(
                    key,
                    size: 22,
                    color: palette.onMedia,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The heart that bursts where the Buzz was double tapped.
class _BurstHeart extends StatelessWidget {
  const _BurstHeart({super.key, required this.at, required this.onDone});
  final Offset at;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Positioned(
    left: at.dx - 48,
    top: at.dy - 48,
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        onEnd: onDone,
        builder: (context, t, child) {
          final scale = t < .3 ? t / .3 * 1.15 : 1.15 - (t - .3) * .2;
          final opacity = t < .6 ? 1.0 : (1 - (t - .6) / .4).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, -24 * t),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: const Icon(
          Icons.favorite,
          size: 96,
          color: WouandaColors.negative,
        ),
      ),
    ),
  );
}

/// A video of a Buzz plays, in a loop, only while it is the one on screen.
class _BuzzVideo extends StatefulWidget {
  const _BuzzVideo({required this.attachment, required this.active});
  final MessageAttachmentDto attachment;
  final bool active;

  @override
  State<_BuzzVideo> createState() => _BuzzVideoState();
}

class _BuzzVideoState extends State<_BuzzVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    final source = attachmentSource(widget.attachment);
    if (source == null) {
      setState(() => _failed = true);
      return;
    }
    final uri = Uri.tryParse(source);
    final remote = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final controller = remote
        ? VideoPlayerController.networkUrl(uri)
        : VideoPlayerController.file(File(source));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      if (widget.active) await controller.play();
    } on Object {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(_BuzzVideo old) {
    super.didUpdateWidget(old);
    final controller = _controller;
    if (controller == null || old.active == widget.active) return;
    if (widget.active && !_paused) {
      unawaited(controller.play());
    } else {
      unawaited(controller.pause());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = _controller;
    if (_failed) {
      return Center(
        child: Text(
          'Cette vidéo ne peut pas être lue.',
          style: AppTheme.bodySm(color: palette.onMedia),
        ),
      );
    }
    if (controller == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          MessagingAttachmentPreview(
            attachment: widget.attachment,
            fit: BoxFit.contain,
          ),
          const WouandaLoadingState(),
        ],
      );
    }
    return GestureDetector(
      onTap: () => setState(() {
        _paused = controller.value.isPlaying;
        _paused ? controller.pause() : controller.play();
      }),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          if (_paused)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: palette.scrim,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.play, color: palette.onMedia, size: 30),
            ),
        ],
      ),
    );
  }
}

// ─── Comments ────────────────────────────────────────────────────────

/// The comments of a Buzz: the messages of its public space, opened (and
/// created on the server) at the first look.
class _BuzzComments extends ConsumerStatefulWidget {
  const _BuzzComments({required this.post, required this.space});
  final UnifiedMessageDto post;
  final Future<UnifiedConversationDto> Function() space;

  @override
  ConsumerState<_BuzzComments> createState() => _BuzzCommentsState();
}

class _BuzzCommentsState extends ConsumerState<_BuzzComments> {
  final _input = TextEditingController();
  int? _spaceId;
  Object? _error;
  ConversationMessagesNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      final space = await widget.space();
      if (!mounted) return;
      setState(() => _spaceId = space.id);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    final notifier = _notifier;
    if (notifier != null && notifier.mounted) notifier.setVisible(false);
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final notifier = _notifier;
    if (text.isEmpty || notifier == null) return;
    _input.clear();
    final sent = await notifier.send(text);
    if (!sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commentaire non envoyé.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = WouandaColors.textPrimary(brightness);
    final meta = WouandaColors.textSecondary(brightness);
    final spaceId = _spaceId;
    final state = spaceId == null
        ? null
        : ref.watch(conversationMessagesProvider(spaceId));
    if (spaceId != null && _notifier == null) {
      final notifier = ref.read(conversationMessagesProvider(spaceId).notifier);
      notifier.setVisible(true);
      _notifier = notifier;
    }
    final comments = state?.messages.where((m) => !m.isSystem).toList();
    final canSend = state?.conversation?.canSend ?? spaceId != null;

    Widget body;
    if (_error != null) {
      body = WouandaEmptyState(
        icon: LucideIcons.messageCircleWarning,
        title: widget.post.delivery == MessageDelivery.sent
            ? 'Commentaires indisponibles'
            : 'Buzz en cours d’envoi',
        message: 'Réessayez dans un instant.',
        actionLabel: 'Réessayer',
        onAction: _open,
      );
    } else if (comments == null || (state!.isLoading && comments.isEmpty)) {
      body = const WouandaLoadingState();
    } else if (comments.isEmpty) {
      body = Center(
        child: Text(
          'Soyez le premier à commenter.',
          style: AppTheme.bodySm(color: meta),
        ),
      );
    } else {
      body = ListView.separated(
        key: const ValueKey('buzz-comments-list'),
        reverse: true,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: comments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final comment = comments[comments.length - 1 - index];
          final name = comment.isMine ? 'Vous' : comment.senderLabel;
          return Opacity(
            opacity: comment.delivery == MessageDelivery.sent ? 1 : .6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WouandaPersonAvatar(name: name, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: name,
                              style: AppTheme.caption(
                                color: ink,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: '  ${_ago(comment.createdAt)}',
                              style: AppTheme.caption(color: meta),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      LinkifiedText(
                        comment.content.isNotEmpty
                            ? comment.content
                            : messagePreview(comment),
                        style: AppTheme.bodySm(color: ink),
                        linkColor: context.palette.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final count = comments?.length ?? widget.post.post?.comments ?? 0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * .68,
        decoration: BoxDecoration(
          color: WouandaColors.surface(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: WouandaColors.border(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              child: Row(
                children: [
                  Text(
                    count > 0 ? 'Commentaires · $count' : 'Commentaires',
                    style: AppTheme.bodyMd(
                      color: ink,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(LucideIcons.x, color: meta, size: 20),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: WouandaColors.border(brightness)),
            Expanded(child: body),
            if (canSend && _error == null)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: WouandaColors.border(brightness)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('buzz-comment-input'),
                          controller: _input,
                          enabled: spaceId != null,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire…',
                            isDense: true,
                            filled: true,
                            fillColor: WouandaColors.surfaceMuted(brightness),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        key: const ValueKey('buzz-comment-send'),
                        tooltip: 'Publier',
                        onPressed: spaceId == null ? null : _send,
                        icon: Icon(
                          LucideIcons.sendHorizontal,
                          color: context.palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
