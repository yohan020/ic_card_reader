import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/settings/presentation/settings_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

void main() {
  testWidgets('puts privacy last and hides development-only settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
          onClearSession: () {},
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
        ),
      ),
    );

    expect(find.text('기본 처리는 기기 안에서'), findsNothing);
    expect(find.text('개발자 정보'), findsNothing);

    await tester.scrollUntilVisible(find.text('개인정보 및 데이터'), 200);
    expect(find.text('앱 정보'), findsOneWidget);
    expect(find.text('개인정보 및 데이터'), findsOneWidget);
  });

  testWidgets('uses the app dialog style when clearing the current history', (
    tester,
  ) async {
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SettingsPage(
          result: CardScanResult(
            scannedAt: DateTime(2026, 8, 12),
            blocks: [
              RawHistoryBlock(
                index: 0,
                bytes: Uint8List.fromList(List<int>.filled(16, 0)),
              ),
            ],
          ),
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
          onClearSession: () => cleared = true,
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
        ),
      ),
    );

    await tester.dragUntilVisible(
      find.text('현재 이용내역 지우기'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('현재 이용내역 지우기'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('clear-history-dialog')), findsOneWidget);
    expect(find.text('현재 이용내역을 지울까요?'), findsOneWidget);
    expect(find.text('실물 카드 안의 데이터는 변경되지 않습니다.'), findsOneWidget);

    final confirm = find.byKey(const ValueKey('confirm-clear-history'));
    final cancel = find.byKey(const ValueKey('cancel-clear-history'));
    expect(
      tester.getTopLeft(confirm).dy,
      lessThan(tester.getTopLeft(cancel).dy),
    );

    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
    expect(find.byKey(const ValueKey('clear-history-dialog')), findsNothing);
  });

  testWidgets('matches station-name display segments to the theme control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
          onClearSession: () {},
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
        ),
      ),
    );

    final selector = tester.widget<SizedBox>(
      find.byKey(const ValueKey('station-name-display-selector')),
    );
    expect(selector.width, double.infinity);
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    expect(find.text('함께 표시'), findsOneWidget);
  });
}
