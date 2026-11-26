import 'package:flutter/material.dart';
import 'package:ngoma_design/ngoma_design.dart';

/// Layout placeholder while real data is loading, never a simulated result.
///
/// The one loading state of the app: animated grey blocks with a light
/// sweeping across them (`NgomaSkeletonRows`), the same everywhere, so every
/// screen that waits for the bridge looks alive without its own spinner.
/// The app has no wheel at all: a page waits with this, a button or a corner
/// waits with `NgomaBusyBar`.
class NgomaLoadingState extends StatelessWidget {
  const NgomaLoadingState({
    super.key,
    this.label = 'Chargement en cours',
    this.rows = 2,
  });
  final String label;
  final int rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: NgomaSkeletonRows(rows: rows, label: label),
  );
}

/// A whole page waiting: a title block, then rows, from the top, under the
/// status bar. Used where a screen has nothing to show yet.
class NgomaPageLoading extends StatelessWidget {
  const NgomaPageLoading({super.key, this.label = 'Chargement en cours'});
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
              const NgomaSkeleton(width: 180, height: 22),
              const SizedBox(height: 18),
              NgomaSkeletonRows(rows: 5, label: label),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Calendar cells waiting for availability. Shared across date-based services.
class NgomaCalendarLoading extends StatelessWidget {
  const NgomaCalendarLoading({super.key, this.weeks = 5});
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
                        child: NgomaSkeleton(height: 40),
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
