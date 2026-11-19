import 'dart:io';
import 'dart:typed_data';

const _magic = [0x48, 0x52, 0x50, 0x46]; // HRPF
const _version = 1;
const _missingFare = 0xffff;
const _headerLength = 8;

void main(List<String> arguments) {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/build_hokkaido_fare_index.dart '
      '<stations.csv> <minimum_fares.csv> <output.bin>',
    );
    exitCode = 64;
    return;
  }

  final stationRows = File(arguments[0])
      .readAsLinesSync()
      .skip(1)
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final stationIndexes = <String, int>{
    for (var index = 0; index < stationRows.length; index++)
      stationRows[index].split(',').first: index,
  };
  final stationCount = stationIndexes.length;
  if (stationCount != stationRows.length || stationCount > 0xffff) {
    throw StateError('Station IDs must be unique and fit in Uint16.');
  }

  final matrix = Uint16List(stationCount * stationCount)
    ..fillRange(0, stationCount * stationCount, _missingFare);
  for (final line in File(
    arguments[1],
  ).readAsLinesSync().skip(1).where((line) => line.isNotEmpty)) {
    final fields = line.split(',');
    final from = stationIndexes[fields[0]];
    final to = stationIndexes[fields[3]];
    final fare = int.parse(fields[8]);
    if (from == null || to == null || fare >= _missingFare) {
      throw StateError('Invalid Hokkaido fare row: $line');
    }
    matrix[from * stationCount + to] = fare;
  }

  final bytes = Uint8List(_headerLength + matrix.lengthInBytes);
  bytes.setRange(0, _magic.length, _magic);
  final header = ByteData.sublistView(bytes);
  header
    ..setUint16(4, _version, Endian.little)
    ..setUint16(6, stationCount, Endian.little);
  bytes.setRange(_headerLength, bytes.length, matrix.buffer.asUint8List());
  File(arguments[2]).writeAsBytesSync(bytes, flush: true);
}
