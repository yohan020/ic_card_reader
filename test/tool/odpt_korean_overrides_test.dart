import 'package:flutter_test/flutter_test.dart';
// ignore: avoid_relative_lib_imports
import '../../tool/lib/odpt_korean_overrides.dart';

void main() {
  test('maps a grouped ODPT station row to one Korean name', () {
    final overrides = parseOdptKoreanOverrides('''
odpt_station_id,name_ja,name_ko
odpt.Station:Toei.Asakusa.Mita|odpt.Station:Toei.Mita.Mita,三田,미타
''');
    final stations = <Map<String, Object?>>[
      {
        'nameKo': '',
        'odptIds': [
          'odpt.Station:Toei.Asakusa.Mita',
          'odpt.Station:Toei.Mita.Mita',
        ],
      },
    ];

    expect(applyOdptKoreanOverrides(stations, overrides), 1);
    expect(stations.single['nameKo'], '미타');
  });

  test('rejects an override for an ODPT station not in the imported data', () {
    final overrides = parseOdptKoreanOverrides('''
odpt_station_id,name_ja,name_ko
odpt.Station:Toei.Unknown.Unknown,없는역,없는역
''');

    expect(
      () => applyOdptKoreanOverrides(<Map<String, Object?>>[], overrides),
      throwsA(isA<Exception>()),
    );
  });
}
