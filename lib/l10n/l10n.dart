import 'package:flutter/widgets.dart';
import 'package:libre_tab/l10n/app_localizations.dart';

export 'package:libre_tab/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
