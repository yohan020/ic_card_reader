import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_stamps/domain/station_stamp_session.dart';
import 'package:ic_card_reader/src/features/station_stamps/presentation/stamp_book_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stamp_test_support.dart' show app;

const _coach = ValueKey('stamp-book-coach');
const _action = ValueKey('stamp-book-coach-action');
const _skip = ValueKey('stamp-book-coach-skip');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 120);
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('first tour uses live controls and is not repeated on entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = StationStampSession();
    addTearDown(session.dispose);
    Widget book() => app(
      StampBookPage(
        session: session,
        candidates: const {},
        hasScan: false,
        enableTutorial: true,
      ),
    );
    await tester.pumpWidget(book());
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    final action = find.byKey(_action);
    final actionInk = find.descendant(
      of: action,
      matching: find.byType(Material),
    );
    expect(tester.getSize(actionInk).height, 38);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    final collect = find.byKey(const ValueKey('stamp-book-collect'));
    expect(tester.widget<FilledButton>(collect).onPressed, isNull);
    await tester.tap(collect, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);

    // The transparent upper padding should also accept a tap.
    final bounds = tester.getRect(action);
    await tester.tapAt(Offset(bounds.center.dx, bounds.top + 2));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stamp-book-browse')));
    await tester.pumpAndSettle();
    expect(find.byType(StampBookBrowsePage), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('회사를 펼쳐봐요'), findsOneWidget);
    await tap(tester, 'stamp-book-company-toggle');
    expect(find.text('예시로 야마노테선을 눌러보세요.'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    final yamanote = find.byKey(const ValueKey('stamp-book-yamanote'));
    final otherLine = find.byKey(const ValueKey('stamp-book-chuo-sobu'));
    expect(yamanote.hitTestable(), findsOneWidget);
    expect(otherLine, findsOneWidget);
    expect(otherLine.hitTestable(), findsNothing);
    await tester.tapAt(tester.getCenter(otherLine));
    await tester.pumpAndSettle();
    expect(find.byType(StampBookBrowsePage), findsOneWidget);
    await tester.tap(yamanote);
    await tester.pumpAndSettle();
    expect(find.byType(YamanoteStampBookLinePage), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stamp-book-tab-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(_coach), findsNothing);
    expect(find.byKey(const ValueKey('stamp-book-map-0')), findsOneWidget);
    expect(session.collected, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(book());
    await tester.pumpAndSettle();
    expect(find.byKey(_coach), findsNothing);
  });

  testWidgets('skip and help replay work in dark large-text landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = StationStampSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(
        StampBookPage(
          session: session,
          candidates: const {'jr-east:ueno'},
          hasScan: true,
          enableTutorial: true,
        ),
        language: 'en',
        dark: true,
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_coach), findsOneWidget);
    await tester.ensureVisible(find.byKey(_skip));
    await tester.pumpAndSettle();
    expect(find.byKey(_skip).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(_skip));
    await tester.pumpAndSettle();
    expect(find.byKey(_coach), findsNothing);

    await tester.tap(find.byTooltip('About collection'));
    await tester.pumpAndSettle();
    await tap(tester, 'stamp-book-coach-replay');
    expect(find.byKey(_coach), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    await tap(tester, 'stamp-book-coach-action');
    expect(find.text('2 / 3'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stamp-book-browse')).hitTestable(),
      findsOneWidget,
    );
    await tap(tester, 'stamp-book-coach-action');
    expect(find.text('Expand the operator'), findsOneWidget);
    await tap(tester, 'stamp-book-coach-action');
    expect(find.text('Try opening the Yamanote Line.'), findsOneWidget);
    expect(find.byKey(_coach), findsOneWidget);
    await tap(tester, 'stamp-book-coach-action');
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(_coach), findsNothing);
    expect(find.byType(YamanoteStampBookLinePage), findsOneWidget);
    expect(session.collected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skipping on the browse route disables the diagram lesson', (
    tester,
  ) async {
    final session = StationStampSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(StampBookBrowsePage(session: session, continueTutorial: true)),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'stamp-book-coach-action');
    expect(find.text('예시로 야마노테선을 눌러보세요.'), findsOneWidget);
    await tap(tester, 'stamp-book-coach-skip');
    expect(find.byKey(_coach), findsNothing);
    await tap(tester, 'stamp-book-chuo-sobu');
    expect(find.byType(StampBookLinePage), findsOneWidget);
    expect(find.byKey(_coach), findsNothing);
  });

  testWidgets('developer preview cannot collect from an existing scan', (
    tester,
  ) async {
    final session = StationStampSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(
        StampBookPage(
          session: session,
          candidates: const {'jr-east:ueno'},
          hasScan: true,
          previewTutorial: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final collect = find.byKey(const ValueKey('stamp-book-collect'));
    expect(tester.widget<FilledButton>(collect).onPressed, isNull);
    expect(session.collected, isEmpty);
  });
}
