import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/settings/domain/installed_app_version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(InstalledAppVersion.channel, null);
  });

  test(
    'reads the version and build number from the installed package',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(InstalledAppVersion.channel, (call) async {
            expect(call.method, 'installedVersion');
            return '2.3.4 (57)';
          });
      expect(await InstalledAppVersion.read(), '2.3.4 (57)');
    },
  );

  test(
    'does not substitute a source version when platform is unavailable',
    () async {
      expect(await InstalledAppVersion.read(), isNull);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(InstalledAppVersion.channel, (_) async {
            throw PlatformException(code: 'VERSION_UNAVAILABLE');
          });
      expect(await InstalledAppVersion.read(), isNull);
    },
  );
}
