import 'package:flutter/material.dart';

/// Marque NGoma : le nom en rouge de la charte, comme sur les modèles Web,
/// Windows et Linux (24/11/2026 : plus de logo « W » de NGoma dans le
/// modèle NGoma). Le nom de la classe est gardé pour ne pas toucher aux écrans.
class NgomaBrandMark extends StatelessWidget {
  final double width;

  const NgomaBrandMark({super.key, required this.width});

  @override
  Widget build(BuildContext context) => Align(
    widthFactor: 1,
    heightFactor: 1,
    child: Semantics(
      label: 'NGoma',
      child: Text(
        'NGoma',
        style: TextStyle(
          fontSize: width * 0.42,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}
