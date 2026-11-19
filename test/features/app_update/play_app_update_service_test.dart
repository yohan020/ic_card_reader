import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/app_update/data/play_app_update_service.dart';
import 'package:ic_card_reader/src/features/app_update/domain/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('de.ffuf.in_app_update/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = PlayAppUpdateService();
  const stale = AppUpdateStatus.available(AppUpdateInstallMode.immediate);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Map<String, Object?> info({int availability = 2, bool immediate = true}) => {
    'updateAvailability': availability,
    'immediateAllowed': immediate,
    'flexibleAllowed': !immediate,
    'availableVersionCode': 22,
    'installStatus': 0,
    'packageName': 'app.iccardreader.ic_card_reader',
    'clientVersionStalenessDays': null,
    'updatePriority': 0,
  };

  test(
    'refreshes single-use Play info on every attempt after cancellation',
    () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'checkForUpdate') return info();
        throw PlatformException(code: 'USER_DENIED_UPDATE');
      });
      await service.checkForUpdate();
      await service.startUpdate(stale);
      await service.startUpdate(stale);
      expect(calls, [
        'checkForUpdate',
        'checkForUpdate',
        'performImmediateUpdate',
        'checkForUpdate',
        'performImmediateUpdate',
      ]);
    },
  );

  test('does not install a canceled flexible update', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'checkForUpdate') return info(immediate: false);
      throw PlatformException(code: 'USER_DENIED_UPDATE');
    });
    await service.startUpdate(stale);
    expect(calls, ['checkForUpdate', 'startFlexibleUpdate']);
  });

  test(
    'propagates Play update failure instead of treating it as success',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkForUpdate') return info();
        throw PlatformException(code: 'IN_APP_UPDATE_FAILED');
      });
      await expectLater(service.startUpdate(stale), throwsStateError);
    },
  );

  test('does not start a stale update when Play now reports latest', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'checkForUpdate');
      return info(availability: 1);
    });
    await service.startUpdate(stale);
  });

  test('unknown availability is not reported as latest', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => info(availability: 0),
    );
    expect(
      (await service.checkForUpdate()).availability,
      AppUpdateAvailability.unavailable,
    );
    await expectLater(service.startUpdate(stale), throwsStateError);
  });

  testWidgets('unresponsive information lookup is bounded', (tester) async {
    final pending = Completer<Object?>();
    messenger.setMockMethodCallHandler(channel, (_) => pending.future);
    final future = service.startUpdate(stale);
    final expectation = expectLater(future, throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 16));
    await expectation;
    pending.complete(info());
    await tester.pump();
  });

  test('resumes an immediate update already in progress', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'checkForUpdate') return info(availability: 3);
      return null;
    });
    await service.startUpdate(stale);
    expect(calls, ['checkForUpdate', 'performImmediateUpdate']);
  });

  testWidgets('bounds only flexible install handoff after download', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'checkForUpdate') return info(immediate: false);
      if (call.method == 'completeFlexibleUpdate') return pending.future;
      return null;
    });
    final expectation = expectLater(
      service.startUpdate(stale),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump();
    expect(calls, [
      'checkForUpdate',
      'startFlexibleUpdate',
      'completeFlexibleUpdate',
    ]);
    await tester.pump(const Duration(seconds: 16));
    await expectation;
    pending.complete();
    await tester.pump();
  });
}
