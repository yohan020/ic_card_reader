import 'dart:convert';

import 'package:flutter/services.dart';

import 'pass_named_place.dart';

import 'pass_transit_data.dart';

class HakonePlace implements PassNamedPlace {
  @override
  String get nameJa => ja;
  @override
  String get nameKo => ko;
  @override
  String get nameEn => en;
  @override
  String get secondaryLabel => detail;

  const HakonePlace({
    required this.id,
    required this.ja,
    required this.en,
    required this.ko,
    required this.mode,
    required this.operator,
    required this.line,
  });
  factory HakonePlace.fromJson(Map<String, dynamic> json) => HakonePlace(
    id: json['id'] as String,
    ja: json['ja'] as String,
    en: json['en'] as String,
    ko: json['ko'] as String,
    mode: json['mode'] as String,
    operator: json['operator'] as String,
    line: json['line'] as String,
  );
  final String id, ja, en, ko, mode, operator, line;
  String get displayName => ko.isEmpty ? ja : ko;
  String get detail => '$ja · ${_modeKo(mode)}';
  String detailForMode(String selectedMode) => '$ja · ${_modeKo(selectedMode)}';
  static String _modeKo(String mode) => switch (mode) {
    'rail' => '등산전차',
    'cable' => '케이블카',
    'ropeway' => '로프웨이',
    'cruise' => '해적선',
    _ => mode,
  };

  bool supportsMode(String selectedMode) =>
      mode == selectedMode ||
      (selectedMode == 'cable' && id == 'OH57') ||
      (selectedMode == 'ropeway' && id == 'OH62');
}

class HakoneDeparture implements PassNamedPlace {
  @override
  String get nameJa => ja;
  @override
  String get nameKo => ko;
  @override
  String get nameEn => en;
  @override
  String get secondaryLabel => '$ja · $line';

  const HakoneDeparture({
    required this.id,
    required this.line,
    required this.order,
    required this.ja,
    required this.en,
    required this.ko,
    required this.adult2,
    required this.adult3,
  });
  factory HakoneDeparture.fromJson(Map<String, dynamic> json) =>
      HakoneDeparture(
        id: json['id'] as String,
        line: json['line'] as String,
        order: json['order'] as int,
        ja: json['ja'] as String,
        en: json['en'] as String,
        ko: json['ko'] as String,
        adult2: json['adult2'] as int,
        adult3: json['adult3'] as int,
      );
  final String id, line, ja, en, ko;
  final int order, adult2, adult3;
  String get displayName => ko.isEmpty ? ja : ko;
}

class HakoneFreepassData {
  HakoneFreepassData._(
    this.departures,
    this.places,
    this._fares,
    this._ropeway,
    this._cruise,
    this.bus,
  );
  factory HakoneFreepassData.fromJson(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    Map<String, int> map(String key, String field) => {
      for (final item in (root[key] as List).cast<Map<String, dynamic>>())
        _key(item['from'] as String, item['to'] as String): item[field] as int,
    };
    return HakoneFreepassData._(
      (root['departures'] as List)
          .cast<Map<String, dynamic>>()
          .map(HakoneDeparture.fromJson)
          .toList(growable: false),
      (root['points'] as List)
          .cast<Map<String, dynamic>>()
          .map(HakonePlace.fromJson)
          .toList(growable: false),
      map('railCableFares', 'fare'),
      map('ropewayFares', 'oneWay'),
      map('cruiseFares', 'oneWay'),
      (root['bus'] as List).cast<Map<String, dynamic>>(),
    );
  }
  final List<HakoneDeparture> departures;
  final List<HakonePlace> places;
  final Map<String, int> _fares, _ropeway, _cruise;
  final List<Map<String, dynamic>> bus;
  int passPrice(HakoneDeparture departure, int days) =>
      days == 2 ? departure.adult2 : departure.adult3;
  int? fare(HakonePlace a, HakonePlace b, {String? mode}) {
    final key = _key(a.id, b.id);
    if (mode == 'ropeway' ||
        (a.supportsMode('ropeway') && b.supportsMode('ropeway'))) {
      return _ropeway[key];
    }
    if (mode == 'cruise' || (a.mode == 'cruise' && b.mode == 'cruise')) {
      return _cruise[key];
    }
    return _fares[key];
  }

  List<HakonePlace> placesForMode(String mode) =>
      places.where((e) => e.supportsMode(mode)).toList(growable: false);
  List<HakoneDeparture> searchDeparture(String query) =>
      _search(query, departures, (e) => [e.ja, e.ko, e.en]);
  List<HakonePlace> searchPlace(String query, String mode) =>
      _search(query, placesForMode(mode), (e) => [e.ja, e.ko, e.en]);
  static List<T> _search<T>(
    String query,
    List<T> values,
    List<String> Function(T) fields,
  ) {
    final q = normalizeStationSearchText(query);
    if (q.isEmpty) return const [];
    final initials = hangulInitials(q);
    final initial = isHangulInitialSearch(q);
    return values
        .where(
          (v) => fields(v).any((f) {
            final n = normalizeStationSearchText(f);
            return n.contains(q) ||
                (initial && hangulInitials(n).startsWith(initials));
          }),
        )
        .toList();
  }

  static String _key(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
}

class HakoneFreepassDataRepository {
  const HakoneFreepassDataRepository();

  static Future<HakoneFreepassData>? _cachedLoad;

  Future<HakoneFreepassData> load() => _cachedLoad ??= _load();

  Future<HakoneFreepassData> _load() async => HakoneFreepassData.fromJson(
    await rootBundle.loadString(
      'assets/data/pass_comparison/hakone_freepass_2026_v2.json',
    ),
  );
}
