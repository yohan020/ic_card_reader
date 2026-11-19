import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_stamps/presentation/two_finger_diagram.dart';

void main() {
  Future<({TransformationController map, ScrollController page})> setup(
    WidgetTester tester, {
    double minimumScale = .2,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = TransformationController(), page = ScrollController();
    addTearDown(map.dispose);
    addTearDown(page.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: page,
            children: [
              const SizedBox(height: 80),
              SizedBox(
                height: 350,
                child: TwoFingerDiagram(
                  controller: map,
                  minimumScale: minimumScale,
                  sceneSize: const Size(500, 700),
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 1300),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (map: map, page: page);
  }

  testWidgets('one finger scrolls page but never pans or zooms diagram', (
    tester,
  ) async {
    final c = await setup(tester), before = Matrix4.identity();
    await tester.drag(find.byType(TwoFingerDiagram), const Offset(0, -130));
    await tester.pumpAndSettle();
    expect(c.page.offset, greaterThan(60));
    expect(c.map.value, before);
    expect(tester.takeException(), isNull);
  });
  testWidgets('horizontal single finger cannot pan diagram', (tester) async {
    final c = await setup(tester);
    await tester.drag(find.byType(TwoFingerDiagram), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(c.map.value, Matrix4.identity());
    expect(c.page.offset, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('two fingers pan and pinch without scrolling parent', (
    tester,
  ) async {
    final c = await setup(tester);
    final a = await tester.startGesture(const Offset(120, 200), pointer: 1),
        b = await tester.startGesture(const Offset(240, 200), pointer: 2);
    await tester.pump();
    await a.moveTo(const Offset(140, 220));
    await b.moveTo(const Offset(260, 220));
    await tester.pump();
    expect(c.map.value.getTranslation().x, closeTo(20, .01));
    expect(c.map.value.getTranslation().y, closeTo(20, .01));
    expect(c.page.offset, 0);
    await a.moveTo(const Offset(100, 220));
    await b.moveTo(const Offset(300, 220));
    await tester.pump();
    expect(c.map.value.getMaxScaleOnAxis(), greaterThan(1.5));
    expect(c.page.offset, 0);
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('two to one finger freezes map and hands movement to page', (
    tester,
  ) async {
    final c = await setup(tester);
    final a = await tester.startGesture(const Offset(120, 240), pointer: 1),
        b = await tester.startGesture(const Offset(240, 240), pointer: 2);
    await a.moveBy(const Offset(10, 10));
    await b.moveBy(const Offset(10, 10));
    await tester.pump();
    await b.up();
    final before = c.map.value.clone();
    await a.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(c.map.value, before);
    expect(c.page.offset, greaterThan(30));
    await a.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('cancel and dispose leave no continuing gesture', (tester) async {
    final c = await setup(tester);
    final a = await tester.startGesture(const Offset(120, 240), pointer: 1),
        b = await tester.startGesture(const Offset(240, 240), pointer: 2);
    await a.moveBy(const Offset(10, 10));
    await a.cancel();
    await b.cancel();
    await tester.pump();
    c.page.jumpTo(0);
    await tester.drag(find.byType(TwoFingerDiagram), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(c.page.offset, greaterThan(30));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('pinch starts at small planar scale without jumping to z scale', (
    tester,
  ) async {
    final c = await setup(tester, minimumScale: .02);
    c.map.value = Matrix4.identity()..scaleByDouble(.1, .1, 1, 1);
    final a = await tester.startGesture(const Offset(120, 200), pointer: 1);
    final b = await tester.startGesture(const Offset(240, 200), pointer: 2);
    await a.moveTo(const Offset(130, 205));
    await b.moveTo(const Offset(250, 205));
    await tester.pump();
    expect(c.map.value.entry(0, 0), closeTo(.1, .001));
    expect(c.page.offset, 0);
    await a.moveTo(const Offset(70, 205));
    await b.moveTo(const Offset(310, 205));
    await tester.pump();
    expect(c.map.value.entry(0, 0), closeTo(.2, .001));
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
