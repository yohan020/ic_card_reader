import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixtureFile = File('test/fixtures/felica/android_history_20_v1.json');

  test(
    'Android physical-card fixture contains 20 valid anonymous blocks',
    () {
      final fixture =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      final blocks = (fixture['blocks'] as List<dynamic>).cast<String>();

      expect(fixture['fixtureVersion'], 1);
      expect(fixture['source'], 'physical_card');
      expect(fixture['platform'], 'android');
      expect(fixture['containsIdm'], isFalse);
      expect(fixture['expectedBlockCount'], 20);
      expect(blocks, hasLength(20));
      expect(blocks.toSet(), hasLength(20));

      final rawBlockPattern = RegExp(r'^[0-9A-F]{32}$');
      for (final block in blocks) {
        expect(block, matches(rawBlockPattern));
      }

      expect(fixture.keys, isNot(contains('idm')));
      expect(fixture.keys, isNot(contains('deviceId')));
      expect(fixture.keys, isNot(contains('user')));
    },
    skip: fixtureFile.existsSync() ? false : 'Local private fixture not found',
  );
}
