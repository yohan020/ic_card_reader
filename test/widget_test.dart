import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/app.dart';

void main() {
  testWidgets('shows the privacy notice and scan action', (tester) async {
    await tester.pumpWidget(const IcCardReaderApp());

    expect(find.text('카드 데이터는 이 기기에서만 처리합니다'), findsOneWidget);
    expect(find.text('IC 카드 스캔'), findsOneWidget);
  });
}
