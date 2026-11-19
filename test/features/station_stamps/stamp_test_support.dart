import 'package:flutter/material.dart';
import 'package:ic_card_reader/l10n/app_localizations.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_name_scope.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

const preview = bool.fromEnvironment('STAMP_PREVIEW');
TextTheme previewTextTheme(TextTheme t) {
  TextStyle? font(TextStyle? s) => s?.copyWith(
    fontFamily: 'Preview',
    fontFamilyFallback: const ['PreviewJapanese', 'PreviewLatin'],
  );
  return TextTheme(
    displayLarge: font(t.displayLarge),
    displayMedium: font(t.displayMedium),
    displaySmall: font(t.displaySmall),
    headlineLarge: font(t.headlineLarge),
    headlineMedium: font(t.headlineMedium),
    headlineSmall: font(t.headlineSmall),
    titleLarge: font(t.titleLarge),
    titleMedium: font(t.titleMedium),
    titleSmall: font(t.titleSmall),
    bodyLarge: font(t.bodyLarge),
    bodyMedium: font(t.bodyMedium),
    bodySmall: font(t.bodySmall),
    labelLarge: font(t.labelLarge),
    labelMedium: font(t.labelMedium),
    labelSmall: font(t.labelSmall),
  );
}

Widget app(
  Widget page, {
  String language = 'ko',
  bool dark = false,
  double scale = 1,
  StationNameDisplayMode mode = StationNameDisplayMode.korean,
}) {
  final theme = dark ? AppTheme.dark : AppTheme.light;
  return RepaintBoundary(
    key: const ValueKey('stamp-preview'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: preview
          ? theme.copyWith(
              textTheme: previewTextTheme(theme.textTheme),
              primaryTextTheme: previewTextTheme(theme.primaryTextTheme),
              appBarTheme: theme.appBarTheme.copyWith(
                titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                  fontFamily: 'Preview',
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: theme.filledButtonTheme.style?.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Preview',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          : theme,
      builder: (context, child) => PassNameScope(
        mode: mode,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
      home: page,
    ),
  );
}
