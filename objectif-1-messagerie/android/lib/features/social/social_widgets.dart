import 'package:flutter/material.dart';
import 'package:ngoma/core/platform/social/social_bridge.dart';
import 'package:ngoma_design/ngoma_design.dart';

const _gradients = <List<Color>>[
  [Color(0xFFF43F5E), Color(0xFFFB923C)],
  [Color(0xFF4F46E5), Color(0xFF38BDF8)],
  [Color(0xFF059669), Color(0xFFA3E635)],
  [Color(0xFFC026D3), Color(0xFFF472B6)],
  [Color(0xFF1E293B), Color(0xFF64748B)],
];

LinearGradient postGradient(int id) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: _gradients[id % _gradients.length],
);

String timeAgo(DateTime t) {
  final s = DateTime.now().difference(t).inSeconds.clamp(1, 1 << 30);
  if (s < 60) return "à l'instant";
  if (s < 3600) return 'il y a ${s ~/ 60} min';
  if (s < 86400) return 'il y a ${s ~/ 3600} h';
  return 'il y a ${s ~/ 86400} j';
}

class SocialAvatar extends StatelessWidget {
  final String name;
  final double size;

  const SocialAvatar({super.key, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: NgomaColors.brand100,
      shape: BoxShape.circle,
    ),
    child: Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: TextStyle(
        color: NgomaColors.brand700,
        fontWeight: FontWeight.w700,
        fontSize: size / 2.4,
      ),
    ),
  );
}

/// Vignette d'une publication (profils, liste de mes vidéos).
class PostMiniature extends StatelessWidget {
  final VideoPost post;

  const PostMiniature({super.key, required this.post});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: postGradient(post.id),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.all(10),
    alignment: Alignment.bottomLeft,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.caption.isEmpty ? 'Vidéo' : post.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '❤️ ${post.likes.length}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}
