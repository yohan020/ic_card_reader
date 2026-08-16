import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/design/app_theme.dart';
import 'features/card_reader/presentation/card_reader_page.dart';
import 'features/issue_report/domain/issue_report_repository.dart';
import 'features/station_resolver/domain/station_name_display.dart';

class IcCardReaderApp extends StatefulWidget {
  const IcCardReaderApp({super.key, this.issueReportRepository});

  final IssueReportRepository? issueReportRepository;

  @override
  State<IcCardReaderApp> createState() => _IcCardReaderAppState();
}

class _IcCardReaderAppState extends State<IcCardReaderApp> {
  ThemeMode _themeMode = ThemeMode.system;
  StationNameDisplayMode _stationNameDisplayMode =
      StationNameDisplayMode.japanese;

  @override
  void initState() {
    super.initState();
    _registerStationDataLicense();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '일본 교통카드 리더',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: CardReaderPage(
        issueReportRepository: widget.issueReportRepository,
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        stationNameDisplayMode: _stationNameDisplayMode,
        onStationNameDisplayModeChanged: (mode) =>
            setState(() => _stationNameDisplayMode = mode),
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
  });
}
