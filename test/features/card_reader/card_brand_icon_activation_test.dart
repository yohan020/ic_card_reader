import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon_frame.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/hayakaken_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/ica_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/icoca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/kitaca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/manaca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/nimoca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/pasmo_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/pitapa_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/sugoca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/suica_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/toica_card_icon.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

const _expected = <CardBrandIdentity, Type>{
  CardBrandIdentity.suicaFamily: SuicaCardIcon,
  CardBrandIdentity.kitaca: KitacaCardIcon,
  CardBrandIdentity.manaca: ManacaCardIcon,
  CardBrandIdentity.sugoca: SugocaCardIcon,
  CardBrandIdentity.pasmo: PasmoCardIcon,
  CardBrandIdentity.icoca: IcocaCardIcon,
  CardBrandIdentity.toica: ToicaCardIcon,
  CardBrandIdentity.nimoca: NimocaCardIcon,
  CardBrandIdentity.hayakaken: HayakakenCardIcon,
  CardBrandIdentity.ica: IcaCardIcon,
};

void main() {
  test(
    'every activated identity has exactly one approved icon, not PiTaPa',
    () {
      expect(_expected.keys.toSet(), CardBrandIdentity.values.toSet());
      expect(CardBrandIdentity.values.length, 10);
      expect(
        CardBrandIdentity.values.map((brand) => brand.name),
        isNot(contains('pitapa')),
      );
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.7]) {
      testWidgets(
        'all balance icons and names narrow screen dark=$dark scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          Future<void> show(CardBrandIdentity? brand) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: HistoryListPage(
                    histories: const [],
                    currentBalance: 1234,
                    brandIdentity: brand,
                    stationPairs: const {},
                    onScan: () {},
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          }

          await show(null);
          final amountX = tester.getTopLeft(find.text('¥1234')).dx;
          expect(find.text('현재 카드 잔액'), findsOneWidget);
          expect(
            find.byIcon(Icons.account_balance_wallet_outlined),
            findsOneWidget,
          );
          for (final entry in _expected.entries) {
            await show(entry.key);
            expect(find.byType(entry.value), findsOneWidget);
            expect(find.byType(CardBrandIconFrame), findsOneWidget);
            expect(
              tester.getSize(find.byType(CardBrandIcon)),
              cardBrandBalanceSize,
            );
            expect(
              find.byIcon(Icons.account_balance_wallet_outlined),
              findsNothing,
            );
            expect(find.byType(PitapaCardIcon), findsNothing);
            expect(find.text('현재 ${entry.key.label} 잔액'), findsOneWidget);
            expect(find.text('가장 최근 기록 기준'), findsNothing);
            expect(find.text('초기 잔액 기록 기준'), findsOneWidget);
            expect(tester.getTopLeft(find.text('¥1234')).dx, amountX);
            final heading = tester.widget<Text>(
              find.text('현재 ${entry.key.label} 잔액'),
            );
            expect(heading.style!.fontSize, 13);
            expect(heading.style!.fontWeight, FontWeight.w600);
            expect(tester.takeException(), isNull);
          }

          await show(null);
          expect(find.text('현재 카드 잔액'), findsOneWidget);
          expect(find.byType(CardBrandIconFrame), findsNothing);
          expect(
            find.byIcon(Icons.account_balance_wallet_outlined),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
