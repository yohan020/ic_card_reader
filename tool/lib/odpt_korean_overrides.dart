import 'tokunai_fare_builder.dart';

/// Reads user-maintained Korean station labels keyed by stable ODPT station ID.
/// One CSV row can address a grouped station with IDs separated by `|`.
Map<String, String> parseOdptKoreanOverrides(String source) {
  final rows = _parseCsv(source);
  if (rows.isEmpty) return const {};
  final header = rows.first;
  final idIndex = _headerIndex(header, 'odpt_station_id');
  final nameIndex = _headerIndex(header, 'name_ko');
  final result = <String, String>{};

  for (var index = 1; index < rows.length; index++) {
    final row = rows[index];
    if (row.every((value) => value.trim().isEmpty)) continue;
    if (row.length != header.length) {
      throw TokunaiFareBuildException(
        'Invalid Korean override CSV column count at row ${index + 1}.',
      );
    }
    final nameKo = row[nameIndex].trim();
    if (nameKo.isEmpty) {
      throw TokunaiFareBuildException(
        'Missing Korean station name at row ${index + 1}.',
      );
    }
    final ids = row[idIndex]
        .split('|')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    if (ids.isEmpty) {
      throw TokunaiFareBuildException(
        'Missing ODPT station ID at row ${index + 1}.',
      );
    }
    for (final id in ids) {
      final previous = result[id];
      if (previous != null && previous != nameKo) {
        throw TokunaiFareBuildException(
          'Conflicting Korean station name for $id.',
        );
      }
      result[id] = nameKo;
    }
  }
  return result;
}

/// Applies the user labels after ODPT has grouped physical station entries.
/// Unknown IDs and disagreeing labels deliberately fail the import instead of
/// silently producing a partly corrected generated asset.
int applyOdptKoreanOverrides(
  List<Map<String, Object?>> stations,
  Map<String, String> overrides,
) {
  var changed = 0;
  for (final station in stations) {
    final ids = (station['odptIds'] as List<Object?>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final names = ids.map(overrides.remove).whereType<String>().toSet();
    if (names.length > 1) {
      throw TokunaiFareBuildException(
        'Conflicting Korean station names in one grouped ODPT station.',
      );
    }
    if (names.isNotEmpty) {
      final name = names.single;
      station['nameKo'] = name;
      changed++;
    }
  }
  if (overrides.isNotEmpty) {
    throw TokunaiFareBuildException(
      'Unknown ODPT station ID in Korean override CSV: ${overrides.keys.first}',
    );
  }
  return changed;
}

int _headerIndex(List<String> header, String name) {
  final index = header.indexOf(name);
  if (index < 0) {
    throw TokunaiFareBuildException('Required CSV column is missing: $name');
  }
  return index;
}

List<List<String>> _parseCsv(String source) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;

  void addField() {
    row.add(field.toString());
    field = StringBuffer();
  }

  void addRow() {
    addField();
    rows.add(row);
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
    } else if ((char == '\r' || char == '\n') && !quoted) {
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
  return rows;
}
