import 'package:flutter/material.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// Layout placeholder while real data is loading, never a simulated result.
///
/// The one loading state of the app: animated grey blocks with a light
/// sweeping across them (`WouandaSkeletonRows`), the same everywhere, so every
/// screen that waits for the bridge looks alive without its own spinner.
/// The app has no wheel at all: a page waits with this, a button or a corner
/// waits with `WouandaBusyBar`.
class WouandaLoadingState extends StatelessWidget {
  const WouandaLoadingState({
    super.key,
    this.label = 'Chargement en cours',
    this.rows = 2,
  });
  final String label;
  final int rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: WouandaSkeletonRows(rows: rows, label: label),
  );
}

/// A whole page waiting: a title block, then rows, from the top, under the
/// status bar. Used where a screen has nothing to show yet.
class WouandaPageLoading extends StatelessWidget {
  const WouandaPageLoading({super.key, this.label = 'Chargement en cours'});
  final String label;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WouandaSkeleton(width: 180, height: 22),
              const SizedBox(height: 18),
              WouandaSkeletonRows(rows: 5, label: label),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Calendar cells waiting for availability. Shared across date-based services.
class WouandaCalendarLoading extends StatelessWidget {
  const WouandaCalendarLoading({super.key, this.weeks = 5});
  final int weeks;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Chargement du calendrier',
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var week = 0; week < weeks; week++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (var day = 0; day < 7; day++)
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: WouandaSkeleton(height: 40),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
