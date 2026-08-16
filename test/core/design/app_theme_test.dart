import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';

void main() {
  test('uses the lightweight ripple for segmented control feedback', () {
    final theme = AppTheme.light;
    final style = theme.segmentedButtonTheme.style;

    expect(theme.splashFactory, InkRipple.splashFactory);
    expect(style?.animationDuration, const Duration(milliseconds: 220));
  });
}
