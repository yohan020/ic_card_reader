import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/widgets/pass_result_scope_note.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('calculation scope remains visible in $brightness', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(
            body: PassResultScopeNote(detail: '관광시설 혜택은 제외하며 버스는 추정 요금입니다.'),
          ),
        ),
      );
      expect(find.textContaining('입력한 교통 이용 기준'), findsOneWidget);
      expect(find.textContaining('버스는 추정 요금'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
