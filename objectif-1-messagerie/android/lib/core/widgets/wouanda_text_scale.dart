import 'package:flutter/widgets.dart';

/// A fixed height or ratio that holds text must grow with the text size, or
/// large text (accessibility settings, 130 % and more) overflows and cuts the
/// words. [textShare] is the part of the extent that is text: 1 for a block
/// made only of text, about .5 for a card that also holds a picture.
double wouandaScaledExtent(
  BuildContext context,
  double base, {
  double textShare = 1,
}) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  return base * (1 + (scale - 1).clamp(0, 1.5) * textShare);
}

/// The aspect ratio of a grid cell whose lower part is text: it gets taller
/// as the text grows, so the width stays the same and nothing overflows.
double wouandaScaledAspectRatio(
  BuildContext context,
  double base, {
  double textShare = .5,
}) => base / wouandaScaledExtent(context, 1, textShare: textShare);
