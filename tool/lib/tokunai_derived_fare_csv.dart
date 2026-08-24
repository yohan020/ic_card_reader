import 'dart:convert';

import 'tokunai_fare_builder.dart';

const tokunaiDerivedFareSource =
    'Derived 2026 Tokunai JR fare table (Wikidata network distance + JR East fare table)';
const tokunaiJrFareTableUrl =
    'https://www.jreast.co.jp/2026unchin-kaitei/assets/pdf/kansen.pdf';

/// Converts the reviewed, unordered station-pair CSV into the builder input.
///
/// The table is derived data, not a response from JR East's fare-search API.
/// It intentionally preserves only the local station-pair fare used by the
/// prototype; route details remain in the source CSV for later auditing.
Map<String, Object?> tokunaiDerivedCsvToBuilderInput({
  required String csv,
  required Map<String, Object?> stationDirectory,
  required DateTime verifiedAt,
}) {
  final rows = _parseCsv(csv);
  if (rows.length < 2) {
    throw const TokunaiFareBuildException('CSV has no fare data rows.');
  }

  final header = rows.first;
  final origin = _headerIndex(header, 'origin');
  final destination = _headerIndex(header, 'destination');
  final icFare = _headerIndex(header, 'ic_fare');
  final directoryIdsByJapaneseName = <String, String>{};
  final stations = stationDirectory['stations'] as List<Object?>? ?? const [];
  for (final item in stations) {
    final station = Map<String, Object?>.from(item! as Map);
    final name = (station['nameJa'] as String? ?? '').trim();
    final id = (station['id'] as String? ?? '').trim();
    if (name.isEmpty || id.isEmpty) continue;
    if (directoryIdsByJapaneseName.containsKey(name)) {
      throw TokunaiFareBuildException(
        'Duplicated Japanese station name: $name',
      );
    }
    directoryIdsByJapaneseName[name] = id;
  }

  final fares = <Map<String, Object?>>[];
  for (var index = 1; index < rows.length; index++) {
    final row = rows[index];
    if (row.every((cell) => cell.trim().isEmpty)) continue;
    if (row.length != header.length) {
      throw TokunaiFareBuildException(
        'Invalid CSV column count at row ${index + 1}.',
      );
    }
    final fromName = row[origin].trim();
    final toName = row[destination].trim();
    final from = directoryIdsByJapaneseName[fromName];
    final to = directoryIdsByJapaneseName[toName];
    if (from == null || to == null) {
      throw TokunaiFareBuildException(
        'CSV station is not in the Tokunai directory: $fromName → $toName.',
      );
    }
    final fare = int.tryParse(row[icFare].trim());
    if (fare == null || fare <= 0) {
      throw TokunaiFareBuildException(
        'Invalid IC fare at row ${index + 1}: ${row[icFare]}',
      );
    }
    fares.add({
      'from': from,
      'to': to,
      'adultIcFare': fare,
      'sourceUrl': tokunaiJrFareTableUrl,
    });
  }

  return {
    'source': tokunaiDerivedFareSource,
    'verifiedAt': verifiedAt.toUtc().toIso8601String(),
    'fares': fares,
  };
}

int _headerIndex(List<String> header, String name) {
  final index = header.indexOf(name);
  if (index < 0) {
    throw TokunaiFareBuildException('Required CSV column is missing: $name');
  }
  return index;
}

List<List<String>> _parseCsv(String source) {
  final result = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;

  void addField() {
    row.add(field.toString());
    field = StringBuffer();
  }

  void addRow() {
    addField();
    result.add(row);
    row = <String>[];
  }

  for (var index = 0; index < source.length; index++) {
    final char = source[index];
    if (char == '"') {
      if (quoted && index + 1 < source.length && source[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      addField();
    } else if ((char == '\n' || char == '\r') && !quoted) {
      if (char == '\r' &&
          index + 1 < source.length &&
          source[index + 1] == '\n') {
        index++;
      }
      addRow();
    } else {
      field.write(char);
    }
  }
  if (quoted) {
    throw const TokunaiFareBuildException(
      'CSV contains an unclosed quoted field.',
    );
  }
  if (field.isNotEmpty || row.isNotEmpty) addRow();
  return result;
}

String encodeTokunaiDerivedBuilderInput(Map<String, Object?> input) =>
    const JsonEncoder.withIndent('  ').convert(input);
