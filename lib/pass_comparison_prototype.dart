import 'package:flutter/material.dart';

import 'src/core/design/app_theme.dart';
import 'src/features/pass_comparison/presentation/pass_strings.dart';
import 'src/features/pass_comparison/presentation/prototype_pass_selection_page.dart';

void main() {
  runApp(const PassComparisonPrototypeApp());
}

class PassComparisonPrototypeApp extends StatelessWidget {
  const PassComparisonPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => passText(context, '교통패스 비교 프로토타입'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: const PrototypePassSelectionPage(),
  );
}
