import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/theme.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// The one way to show a picture from the network, the assets or the phone.
///
/// While it loads there is a quiet block (never an empty hole), when it
/// arrives it fades in, and when it cannot be shown there is a calm fallback
/// instead of a blank or a red error. With animations reduced it simply
/// appears. Screens never build `Image.network`, `NetworkImage` or
/// `CachedNetworkImage` themselves (see `test/architecture/shared_image_test`).
ImageProvider<Object>? wouandaImageProvider(String? source) {
  final value = source?.trim();
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return CachedNetworkImageProvider(value);
  }
  if (value.startsWith('assets/')) return AssetImage(value);
  final path = value.startsWith('file://')
      ? Uri.parse(value).toFilePath()
      : value;
  return FileImage(File(path));
}

class WouandaImage extends StatelessWidget {
  const WouandaImage(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.fallback,
    this.semanticLabel,
    this.cacheWidth,
  });

  /// URL, `assets/…` path or local file; null or empty shows the fallback.
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  /// What stands in when there is no picture or it cannot load. A quiet icon
  /// block by default.
  final Widget? fallback;
  final String? semanticLabel;

  /// Decode no wider than this many pixels (thumbnails in long lists).
  final int? cacheWidth;

  Widget _fallback(BuildContext context, {required bool failed}) {
    final palette = context.palette;
    return SizedBox(
      width: width,
      height: height,
      child:
          fallback ??
          ColoredBox(
            color: palette.surfaceMuted,
            child: Center(
              child: Icon(
                failed ? LucideIcons.imageOff : LucideIcons.image,
                color: palette.textSecondary,
                size: (width != null && width! < 56) ? 16 : 24,
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = wouandaImageProvider(source);
    final provider = base != null && cacheWidth != null
        ? ResizeImage(base, width: cacheWidth)
        : base;
    if (provider == null) {
      final fallback = _fallback(context, failed: false);
      return radius <= 0
          ? fallback
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: fallback,
            );
    }
    final image = Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      frameBuilder: (context, child, frame, loadedSync) {
        if (loadedSync) return child;
        return Stack(
          fit: StackFit.passthrough,
          alignment: Alignment.center,
          children: [
            if (frame == null)
              // Same box as the picture will have, or the parent's.
              LayoutBuilder(
                builder: (context, box) => WouandaSkeleton(
                  width: width ?? (box.hasBoundedWidth ? box.maxWidth : 96),
                  height: height ?? (box.hasBoundedHeight ? box.maxHeight : 96),
                  radius: 0,
                ),
              ),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: WouandaMotion.duration(context, WouandaMotion.standard),
              curve: WouandaMotion.enterCurve,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (context, _, _) => _fallback(context, failed: true),
    );
    if (radius <= 0) return image;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}

/// A person's round picture: the photo when there is one, their initials when
/// there is not or when it fails, with the same quiet loading as every image.
class WouandaPersonAvatar extends StatelessWidget {
  const WouandaPersonAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
    this.placeholder,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Drawn instead of the initial when there is no photo (a shop, a group).
  final Widget? placeholder;

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = backgroundColor ?? palette.surfaceMuted;
    final foreground = foregroundColor ?? palette.textPrimary;
    final initials = ColoredBox(
      color: background,
      child: Center(
        child:
            placeholder ??
            Text(
              _initial,
              style: radius >= 28
                  ? AppTheme.titleLg(color: foreground)
                  : radius >= 16
                  ? AppTheme.titleMd(color: foreground)
                  : AppTheme.labelLg(color: foreground),
            ),
      ),
    );
    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: wouandaImageProvider(photoUrl) == null
            ? initials
            : WouandaImage(
                photoUrl,
                width: radius * 2,
                height: radius * 2,
                fallback: initials,
              ),
      ),
    );
  }
}
