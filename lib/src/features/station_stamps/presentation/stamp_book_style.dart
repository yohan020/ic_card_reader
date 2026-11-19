import 'package:flutter/material.dart';

/// Representative route hues, not official railway logos or a branded asset.
/// Applied to the path only; station and collection markers stay independent.
abstract final class StampBookRouteColors {
  static const yamanote = Color(0xFF80C241);
  static const chuoSobu = Color(0xFFFFD400);
  static const midosuji = Color(0xFFC92F45);
  static const osakaLoop = Color(0xFFC65F1C);
}

/// Approved B2 paper / teal / vermilion, scoped to the new book only.
class StampBookColors {
  StampBookColors(BuildContext context)
    : dark = Theme.of(context).brightness == Brightness.dark;
  final bool dark;
  Color get background =>
      dark ? const Color(0xFF171C1C) : const Color(0xFFF4F0E6);
  Color get paper => dark ? const Color(0xFF242C2B) : const Color(0xFFFFFDF7);
  Color get ink => dark ? const Color(0xFFE6E9DF) : const Color(0xFF233C4D);
  Color get muted => dark ? const Color(0xFFB9C2B8) : const Color(0xFF626C65);
  Color get teal => dark ? const Color(0xFF9DCAC1) : const Color(0xFF426C69);
  Color get onTeal => dark ? const Color(0xFF16302D) : const Color(0xFFFFFDF7);
  Color get stamp => dark ? const Color(0xFFF0A08B) : const Color(0xFFAB4E3C);
  Color get line => dark ? const Color(0xFF4D5B56) : const Color(0xFFDDDCD0);
  Color get ticketOutline =>
      dark ? const Color(0xFF788E84) : const Color(0xFF9CA89C);
  Color get ticketStub =>
      dark ? const Color(0xFF303E36) : const Color(0xFFE7EBDD);
}

ThemeData stampBookTheme(BuildContext context) {
  final c = StampBookColors(context);
  final theme = Theme.of(context);
  return theme.copyWith(
    scaffoldBackgroundColor: c.background,
    textTheme: theme.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
    colorScheme: theme.colorScheme.copyWith(
      primary: c.teal,
      onPrimary: c.onTeal,
      surface: c.paper,
      onSurface: c.ink,
      onSurfaceVariant: c.muted,
      outline: c.line,
    ),
    appBarTheme: theme.appBarTheme.copyWith(
      backgroundColor: c.background,
      foregroundColor: c.ink,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: c.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.teal,
        foregroundColor: c.onTeal,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.teal),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: c.teal),
    ),
  );
}
