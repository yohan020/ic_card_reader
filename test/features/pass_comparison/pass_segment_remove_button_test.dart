import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/widgets/pass_segment_remove_button.dart';

void main() {
  testWidgets('keeps a removable segment header at the single-segment height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassSegmentRemoveButton(onPressed: () {})),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('pass-segment-remove-button'))),
      const Size(28, 28),
    );
    expect(find.byTooltip('구간 삭제'), findsOneWidget);
  });
}
