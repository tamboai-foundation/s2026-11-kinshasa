import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Wouanda uses no emoji (charter §12). Data that used to hold an emoji —
/// reactions, gifts, date types, intentions, statuses — now holds a stable
/// key, and the interface draws the matching icon from here.
abstract final class WouandaSymbols {
  static const _icons = <String, IconData>{
    // Reactions.
    'heart': LucideIcons.heart,
    'laugh': LucideIcons.laugh,
    'wow': LucideIcons.sparkles,
    'sad': LucideIcons.frown,
    'fire': LucideIcons.flame,
    'like': LucideIcons.thumbsUp,
    // Intentions.
    'love': LucideIcons.heart,
    'flower': LucideIcons.flower2,
    'friendship': LucideIcons.handshake,
    'adventure': LucideIcons.plane,
    'open': LucideIcons.sparkles,
    // Date types.
    'coffee': LucideIcons.coffee,
    'drink': LucideIcons.wine,
    'walk': LucideIcons.footprints,
    'dinner': LucideIcons.utensils,
    'activity': LucideIcons.target,
    'videoCall': LucideIcons.video,
    // Gifts.
    'rose': LucideIcons.flower,
    'bouquet': LucideIcons.flower2,
    'chocolate': LucideIcons.candy,
    'cake': LucideIcons.cake,
    'gift': LucideIcons.gift,
    'ring': LucideIcons.gem,
    'crown': LucideIcons.crown,
    'star': LucideIcons.star,
    'teddy': LucideIcons.smile,
    'fabric': LucideIcons.shirt,
    'pottery': LucideIcons.amphora,
    'mask': LucideIcons.drama,
    'beads': LucideIcons.gem,
    // Statuses.
    'active': LucideIcons.messageCircle,
    'scheduled': LucideIcons.calendar,
    'expired': LucideIcons.wind,
    'blocked': LucideIcons.ban,
    'pending': LucideIcons.hourglass,
  };

  /// Reactions offered on a message, in order.
  static const reactions = ['heart', 'laugh', 'wow', 'sad', 'fire', 'like'];

  /// True for a key the design system draws as an icon. A reaction that is
  /// not one is an emoji typed on the phone's own keyboard.
  static bool has(String key) => _icons.containsKey(key);

  static IconData of(String key) => _icons[key] ?? LucideIcons.circle;
}

/// Draws a [WouandaSymbols] key.
class WouandaSymbol extends StatelessWidget {
  const WouandaSymbol(this.symbol, {super.key, this.size = 20, this.color});

  final String symbol;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(WouandaSymbols.of(symbol), size: size, color: color);
}
