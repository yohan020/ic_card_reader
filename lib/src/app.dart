import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design/app_theme.dart';
import 'core/localization/app_language.dart';
import 'core/localization/app_strings.dart';
import 'features/card_reader/presentation/card_reader_page.dart';
import 'features/issue_report/domain/issue_report_repository.dart';
import 'features/station_resolver/domain/station_name_display.dart';
import 'features/pass_comparison/presentation/pass_name_scope.dart';

class IcCardReaderApp extends StatefulWidget {
  const IcCardReaderApp({super.key, this.issueReportRepository});

  final IssueReportRepository? issueReportRepository;

  @override
  State<IcCardReaderApp> createState() => _IcCardReaderAppState();
}

class _IcCardReaderAppState extends State<IcCardReaderApp> {
  static const _appLanguageKey = 'appLanguage';
  static const _stationNameModeKey = 'stationNameDisplayMode';

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _appLanguage = AppLanguage.system;
  StationNameDisplayMode _stationNameDisplayMode =
      StationNameDisplayMode.japanese;
  bool _appLanguageChanged = false;
  bool _stationNameModeChanged = false;
  late final Future<SharedPreferences?> _preferences;

  @override
  void initState() {
    super.initState();
    _registerStationDataLicense();
    _preferences = _loadPreferences();
    _restoreLanguageSettings();
  }

  Future<SharedPreferences?> _loadPreferences() async {
    try {
      return await SharedPreferences.getInstance();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _restoreLanguageSettings() async {
    final preferences = await _preferences;
    if (!mounted || preferences == null) return;
    setState(() {
      if (!_appLanguageChanged) {
        final name = preferences.get(_appLanguageKey);
        _appLanguage =
            AppLanguage.values.asNameMap()[name] ?? AppLanguage.system;
      }
      if (!_stationNameModeChanged) {
        final name = preferences.get(_stationNameModeKey);
        _stationNameDisplayMode =
            StationNameDisplayMode.values.asNameMap()[name] ??
            StationNameDisplayMode.japanese;
      }
    });
  }

  Future<void> _setAppLanguage(AppLanguage language) async {
    setState(() {
      _appLanguageChanged = true;
      _appLanguage = language;
    });
    await _savePreference(_appLanguageKey, language.name);
  }

  Future<void> _setStationNameMode(StationNameDisplayMode mode) async {
    setState(() {
      _stationNameModeChanged = true;
      _stationNameDisplayMode = mode;
    });
    await _savePreference(_stationNameModeKey, mode.name);
  }

  Future<void> _savePreference(String key, String value) async {
    try {
      await (await _preferences)?.setString(key, value);
    } on PlatformException {
      // Keep the in-memory selection if device storage is unavailable.
    } on MissingPluginException {
      // Keep the in-memory selection on hosts without preference storage.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => strings(context).appTitle,
      locale: _appLanguage.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      builder: (context, child) =>
          PassNameScope(mode: _stationNameDisplayMode, child: child!),
      home: CardReaderPage(
        issueReportRepository: widget.issueReportRepository,
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        stationNameDisplayMode: _stationNameDisplayMode,
        onStationNameDisplayModeChanged: _setStationNameMode,
        appLanguage: _appLanguage,
        onAppLanguageChanged: _setAppLanguage,
      ),
    );
  }
}

bool _stationDataLicenseRegistered = false;

void _registerStationDataLicense() {
  if (_stationDataLicenseRegistered) return;
  _stationDataLicenseRegistered = true;
  LicenseRegistry.addLicense(() async* {
    final yoikoTerms = await rootBundle.loadString(
      'assets/licenses/yoiko-station-data-TERMS.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'Yoiko station code data',
    ], yoikoTerms);
    final wikidataNotice = await rootBundle.loadString(
      'assets/licenses/wikidata-station-names-CC0.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'Wikidata Korean station labels',
    ], wikidataNotice);
    final englishStationNotice = await rootBundle.loadString(
      'assets/licenses/english-station-names-NOTICE.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'English station names · Japan Station Master / ODPT / MLIT / Wikidata',
    ], englishStationNotice);
    final icaNotice = await rootBundle.loadString(
      'assets/licenses/ica-reader-MIT.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'ICa reader format reference',
    ], icaNotice);
    final contactlessNotice = await rootBundle.loadString(
      'assets/licenses/contactless-data-NOTICE.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'Contactless railway data · N02 / Wikidata / independent review',
    ], contactlessNotice);
    final lockerNotice = await rootBundle.loadString(
      'assets/licenses/coin-locker-links-NOTICE.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'Coin locker external links · independent curation',
    ], lockerNotice);
  });
}
