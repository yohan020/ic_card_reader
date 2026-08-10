import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/design/app_theme.dart';
import 'features/card_reader/presentation/card_reader_page.dart';
import 'features/issue_report/domain/issue_report_repository.dart';

class IcCardReaderApp extends StatefulWidget {
  const IcCardReaderApp({super.key, this.issueReportRepository});

  final IssueReportRepository? issueReportRepository;

  @override
  State<IcCardReaderApp> createState() => _IcCardReaderAppState();
}

class _IcCardReaderAppState extends State<IcCardReaderApp> {
  ThemeMode _themeMode = ThemeMode.system;

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
      ),
    );
  }
}

bool _stationDataLicenseRegistered = false;

void _registerStationDataLicense() {
  if (_stationDataLicenseRegistered) return;
  _stationDataLicenseRegistered = true;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/licenses/yoiko-station-data-TERMS.txt',
    );
    yield LicenseEntryWithLineBreaks(const [
      'Yoiko station code data',
    ], license);
  });
}
