import 'dart:convert';
import 'dart:io';

import 'lib/odpt_korean_overrides.dart';

const _assetPath = 'assets/data/pass_comparison/odpt_pass_data.json';
const _overridePath =
    'assets/data/pass_comparison/manual_odpt_station_names_ko.csv';

Future<void> main() async {
  try {
    final assetFile = File(_assetPath);
    final overrideFile = File(_overridePath);
    if (!assetFile.existsSync()) {
      throw FileSystemException('ODPT asset was not found.', _assetPath);
    }
    if (!overrideFile.existsSync()) {
      throw FileSystemException(
        'Korean override CSV was not found.',
        _overridePath,
      );
    }
    final asset = Map<String, Object?>.from(
      jsonDecode(await assetFile.readAsString()) as Map,
    );
    final stations = (asset['stations'] as List<Object?>? ?? const [])
        .map((item) => Map<String, Object?>.from(item! as Map))
        .toList();
    final applied = applyOdptKoreanOverrides(
      stations,
      parseOdptKoreanOverrides(await overrideFile.readAsString()),
    );
    asset['stations'] = stations;
    await assetFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(asset)}\n',
    );
    stdout.writeln('Applied $applied Korean station overrides to $_assetPath.');
  } on FileSystemException catch (error) {
    stderr.writeln(error.message);
    exitCode = 66;
  } on FormatException catch (error) {
    stderr.writeln('Invalid JSON: ${error.message}');
    exitCode = 65;
  } on Exception catch (error) {
    stderr.writeln(error);
    exitCode = 65;
  }
}
