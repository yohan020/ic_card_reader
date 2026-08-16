import 'package:flutter/material.dart';

import 'src/core/design/app_theme.dart';
import 'src/features/pass_comparison/presentation/pass_comparison_prototype_page.dart';

void main() {
  runApp(const PassComparisonPrototypeApp());
}

class PassComparisonPrototypeApp extends StatelessWidget {
  const PassComparisonPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '교통패스 비교 프로토타입',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: const PassComparisonPrototypePage(),
  );
}
