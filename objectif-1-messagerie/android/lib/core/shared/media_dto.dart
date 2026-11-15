/// Structured media shared by every bridge contract (protocole §5.5).
///
/// `url` (server) wins over `path` (file already downloaded locally); screens
/// fall back to a generic icon when both are missing.
enum MediaType {
  image,
  video,
  audio,
  document,
  file;

  static MediaType fromCode(String? code) => MediaType.values.firstWhere(
    (type) => type.name == code,
    orElse: () => MediaType.file,
  );
}

class MediaDto {
  final MediaType type;
  final String? url;
  final String? path;
  final String? label;

  const MediaDto({required this.type, this.url, this.path, this.label});

  const MediaDto.image(String this.url)
    : type = MediaType.image,
      path = null,
      label = null;

  /// [source] for widgets that need a non-null string (empty → placeholder).
  String get displayUrl => source ?? '';

  /// The best available source for display, or null when none is usable.
  String? get source {
    if (url != null && url!.isNotEmpty) return url;
    if (path != null && path!.isNotEmpty) return path;
    return null;
  }

  factory MediaDto.fromMap(Map<String, dynamic> m) => MediaDto(
    type: MediaType.fromCode(m['type'] as String?),
    url: m['url'] as String?,
    path: m['path'] as String?,
    label: m['label'] as String?,
  );

  static MediaDto? fromMapOrNull(Object? raw) =>
      raw is Map ? MediaDto.fromMap(Map<String, dynamic>.from(raw)) : null;

  Map<String, Object?> toMap() => {
    'type': type.name,
    'url': url,
    'path': path,
    'label': label,
  };
}
