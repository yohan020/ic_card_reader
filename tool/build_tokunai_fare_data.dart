import 'dart:convert';
import 'dart:io';

import 'lib/tokunai_fare_builder.dart';

const _directoryPath = 'assets/data/pass_comparison/tokunai_jr_data.json';
const _defaultOutputPath = 'assets/data/pass_comparison/tokunai_jr_data.json';

Future<void> main(List<String> arguments) async {
  final inputPath = _valueAfter(arguments, '--input');
  final outputPath = _valueAfter(arguments, '--output') ?? _defaultOutputPath;
  if (inputPath == null) {
    stderr.writeln(
      'Usage: dart run tool/build_tokunai_fare_data.dart '
      '--input path/to/verified_fares.json [--output path]',
    );
    exitCode = 64;
    return;
  }

  try {
    final directory = _object(await File(_directoryPath).readAsString());
    final verifiedInput = _object(await File(inputPath).readAsString());
    final asset = buildTokunaiFareAsset(
      stationDirectory: directory,
      verifiedInput: verifiedInput,
    );
    await File(outputPath).writeAsString(encodeTokunaiFareAsset(asset));
    stdout.writeln(
      'Wrote ${asset['fares'] is List ? (asset['fares'] as List).length : 0} verified Tokunai fares.',
    );
  } on FileSystemException catch (error) {
    stderr.writeln(error.message);
    exitCode = 66;
  } on FormatException catch (error) {
    stderr.writeln('Invalid JSON: ${error.message}');
    exitCode = 65;
  } on TokunaiFareBuildException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  }
}

String? _valueAfter(List<String> arguments, String flag) {
  final index = arguments.indexOf(flag);
  if (index < 0 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}

Map<String, Object?> _object(String source) =>
    Map<String, Object?>.from(jsonDecode(source) as Map);
