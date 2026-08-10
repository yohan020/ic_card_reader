import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/features/issue_report/data/issue_report_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final issueReportRepository = await IssueReportBootstrap.initialize();
  runApp(IcCardReaderApp(issueReportRepository: issueReportRepository));
}
