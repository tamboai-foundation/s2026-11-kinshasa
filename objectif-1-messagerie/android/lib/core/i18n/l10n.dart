import 'package:flutter/widgets.dart';
import 'package:ngoma/l10n/app_localizations.dart';

export 'package:ngoma/l10n/app_localizations.dart' show AppLocalizations;

/// The app strings (French or English) for any widget. A tree without
/// localizations (a test, a preview) gets French, the reference language,
/// instead of a null error.
extension WouandaL10n on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('fr'));
}
