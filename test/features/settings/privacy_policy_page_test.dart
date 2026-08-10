import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/settings/presentation/privacy_policy_page.dart';

void main() {
  testWidgets('explains NFC use and optional issue report transmission', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));

    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(find.text('1. NFC 사용 목적'), findsOneWidget);
    expect(find.textContaining('카드에 정보를 기록하거나 변경하지 않습니다'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('4. 전송하지 않는 정보'), 300);
    expect(find.textContaining('카드 IDm 원문'), findsWidgets);
    expect(find.textContaining('기기 고유 식별자'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('7. 보관과 삭제'), 300);
    expect(find.textContaining('최대 1년간 보관'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('iccardreader10@gmail.com'),
      300,
    );
    expect(find.textContaining('iccardreader10@gmail.com'), findsOneWidget);
    expect(
      find.textContaining('https://yohan020.github.io/ic_card_reader/'),
      findsOneWidget,
    );
  });
}
