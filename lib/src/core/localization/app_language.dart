import 'package:flutter/widgets.dart';

enum AppLanguage {
  system,
  korean,
  english;

  Locale? get locale => switch (this) {
    system => null,
    korean => const Locale('ko'),
    english => const Locale('en'),
  };
}
