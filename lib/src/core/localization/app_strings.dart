import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_ko.dart';

export '../../../l10n/app_localizations.dart';
export '../../../l10n/app_localizations_ko.dart';

AppLocalizations strings(BuildContext context) =>
    AppLocalizations.of(context) ?? _koreanStrings;

bool usesEnglish(BuildContext context) => strings(context).localeName == 'en';

String localized(BuildContext context, String korean, String english) =>
    usesEnglish(context) ? english : korean;

final _koreanStrings = AppLocalizationsKo();
