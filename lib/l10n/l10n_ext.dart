import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Shorthand for `AppLocalizations.of(context)` → `context.l10n`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
