import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/features/messaging/messaging_media_viewer.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// What a tap on an attachment of a bubble opens, as in any native messenger:
/// images and videos in the full-screen viewer, PDF and text in an included
/// reader, other documents in the phone's own app, a position on the map.
Future<void> openMessagingAttachment(
  BuildContext context, {
  required List<MessageAttachmentDto> attachments,
  required MessageAttachmentDto attachment,
  String? caption,
}) {
  if (isVisualAttachment(attachment)) {
    return MessagingMediaViewerScreen.open(
      context,
      attachments: attachments,
      initial: attachment,
      caption: caption,
    );
  }
  if (attachment.type == 'location') return _openLocation(attachment);
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => MessagingDocumentViewerScreen(attachment: attachment),
    ),
  );
}

Future<void> _openLocation(MessageAttachmentDto attachment) async {
  final source = attachmentSource(attachment);
  if (source == null) return;
  final coordinates = source.startsWith('geo:') ? source.substring(4) : null;
  final uri = coordinates != null
      ? Uri.parse('geo:$coordinates?q=$coordinates')
      : Uri.tryParse(source);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

bool isPdfAttachment(MessageAttachmentDto attachment) =>
    attachment.mimeType == 'application/pdf' ||
    attachment.label.toLowerCase().endsWith('.pdf');

bool _isText(MessageAttachmentDto attachment) =>
    (attachment.mimeType ?? '').startsWith('text/') ||
    attachment.label.toLowerCase().endsWith('.txt');

/// « 1,2 Mo » : readable size of an attachment.
String attachmentSizeLabel(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} Ko';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';
}

/// Icon and short name of a document kind.
({IconData icon, String kind}) documentKind(MessageAttachmentDto attachment) {
  final name = attachment.label.toLowerCase();
  final extension = name.contains('.') ? name.split('.').last : '';
  return switch (extension) {
    'pdf' => (icon: LucideIcons.fileText, kind: 'PDF'),
    'doc' || 'docx' => (icon: LucideIcons.fileText, kind: 'Word'),
    'xls' ||
    'xlsx' ||
    'csv' => (icon: LucideIcons.fileSpreadsheet, kind: 'Excel'),
    'ppt' || 'pptx' => (icon: LucideIcons.presentation, kind: 'Présentation'),
    'zip' || 'rar' || '7z' => (icon: LucideIcons.fileArchive, kind: 'Archive'),
    'txt' => (icon: LucideIcons.fileText, kind: 'Texte'),
    _ => (icon: LucideIcons.file, kind: extension.toUpperCase()),
  };
}

/// The local file of an attachment. A remote one is downloaded once into the
/// cache and reused; [onProgress] reports 0..1 when the size is known.
Future<File> resolveAttachmentFile(
  MessageAttachmentDto attachment, {
  void Function(double)? onProgress,
}) async {
  final source = attachmentSource(attachment);
  if (source == null) throw StateError('missing source');
  final uri = Uri.tryParse(source);
  final remote = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  if (!remote) {
    final path = source.startsWith('file://')
        ? Uri.parse(source).toFilePath()
        : source;
    final file = File(path);
    if (!await file.exists()) throw StateError('missing file');
    return file;
  }
  final cache = Directory(
    '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}wouanda-attachments',
  );
  await cache.create(recursive: true);
  final name = attachment.label.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File(
    '${cache.path}${Platform.pathSeparator}${source.hashCode.toRadixString(16)}-$name',
  );
  if (await file.exists() && await file.length() > 0) return file;
  final client = http.Client();
  try {
    final response = await client.send(http.Request('GET', uri));
    if (response.statusCode != 200) {
      throw HttpException('${response.statusCode}');
    }
    final total = response.contentLength ?? attachment.sizeBytes ?? 0;
    var received = 0;
    final partial = File('${file.path}.part');
    final sink = partial.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call((received / total).clamp(0, 1));
      }
    } finally {
      await sink.close();
    }
    return await partial.rename(file.path);
  } finally {
    client.close();
  }
}

/// Reads a PDF or a text file inside the app; any other document opens in the
/// phone's own application. Sharing doubles as « enregistrer ».
class MessagingDocumentViewerScreen extends StatefulWidget {
  const MessagingDocumentViewerScreen({super.key, required this.attachment});
  final MessageAttachmentDto attachment;

  @override
  State<MessagingDocumentViewerScreen> createState() =>
      _MessagingDocumentViewerScreenState();
}

class _MessagingDocumentViewerScreenState
    extends State<MessagingDocumentViewerScreen> {
  final _progress = ValueNotifier<double?>(null);
  late Future<File> _file = _load();
  PdfControllerPinch? _pdf;
  String? _text;
  int _page = 1;
  int _pages = 0;

  Future<File> _load() async {
    final file = await resolveAttachmentFile(
      widget.attachment,
      onProgress: (value) => _progress.value = value,
    );
    if (isPdfAttachment(widget.attachment)) {
      _pdf = PdfControllerPinch(document: PdfDocument.openFile(file.path));
    } else if (_isText(widget.attachment)) {
      final bytes = await file
          .openRead(0, 200 * 1024)
          .expand((c) => c)
          .toList();
      _text = String.fromCharCodes(bytes);
    }
    return file;
  }

  @override
  void dispose() {
    _pdf?.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _share(File file) => SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], subject: widget.attachment.label),
  );

  Future<void> _openExternally(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune application ne peut ouvrir ce fichier.'),
        ),
      );
    }
  }

  void _retry() => setState(() {
    _progress.value = null;
    _file = _load();
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          widget.attachment.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          FutureBuilder<File>(
            future: _file,
            builder: (context, snapshot) {
              final file = snapshot.data;
              if (file == null) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Télécharger ou partager',
                    onPressed: () => _share(file),
                    icon: const Icon(LucideIcons.download),
                  ),
                  if (!isPdfAttachment(widget.attachment))
                    IconButton(
                      tooltip: 'Ouvrir avec une autre application',
                      onPressed: () => _openExternally(file),
                      icon: const Icon(LucideIcons.externalLink),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<File>(
        future: _file,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Message(
              icon: LucideIcons.fileX,
              text: 'Ce document ne peut pas être ouvert.',
              action: 'Réessayer',
              onAction: _retry,
            );
          }
          final file = snapshot.data;
          if (file == null) {
            return Center(
              child: ValueListenableBuilder<double?>(
                valueListenable: _progress,
                builder: (context, value, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WouandaBusyBar(size: 44),
                    const SizedBox(height: 14),
                    Text(
                      value == null
                          ? 'Préparation…'
                          : 'Téléchargement ${(value * 100).round()} %',
                      style: AppTheme.bodySm(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          if (_pdf != null) {
            return Stack(
              children: [
                PdfViewPinch(
                  controller: _pdf!,
                  backgroundDecoration: BoxDecoration(
                    color: palette.surfaceMuted,
                  ),
                  onDocumentLoaded: (document) =>
                      setState(() => _pages = document.pagesCount),
                  onPageChanged: (page) => setState(() => _page = page),
                  onDocumentError: (_) => setState(() {
                    _pdf = null;
                    _file = Future.error(StateError('pdf'));
                  }),
                ),
                if (_pages > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.scrim,
                          borderRadius: BorderRadius.circular(
                            WouandaSpacing.radiusPill,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: Text(
                            '$_page / $_pages',
                            style: AppTheme.caption(color: palette.onMedia),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
          if (_text != null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _text!,
                style: AppTheme.bodyMd(color: palette.textPrimary),
              ),
            );
          }
          final kind = documentKind(widget.attachment);
          return _Message(
            icon: kind.icon,
            text:
                '${widget.attachment.label}\n'
                '${[kind.kind, attachmentSizeLabel(widget.attachment.sizeBytes)].where((part) => part.isNotEmpty).join(' · ')}',
            action: 'Ouvrir',
            onAction: () => _openExternally(file),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: context.palette.accent),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd(color: context.palette.textPrimary),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    ),
  );
}
