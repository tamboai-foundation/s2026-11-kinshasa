import 'package:flutter/material.dart';

/// The transparent Wouanda W. The PNG is the high density export of
/// assets/brand/wouanda_mark.svg, retained as the brand source.
class WouandaBrandMark extends StatelessWidget {
  final double width;

  const WouandaBrandMark({super.key, required this.width});

  @override
  Widget build(BuildContext context) => Align(
    widthFactor: 1,
    heightFactor: 1,
    child: Image.asset(
      'assets/images/wouanda.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'Wouanda',
    ),
  );
}
