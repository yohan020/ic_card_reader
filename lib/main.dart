import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/features/issue_report/data/issue_report_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    IcCardReaderApp(issueReportRepository: IssueReportBootstrap.repository()),
  );
}
