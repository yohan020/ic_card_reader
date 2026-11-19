import 'package:flutter/foundation.dart';

import '../../station_resolver/domain/station_resolution.dart';

part 'stamp_book_collection_index.g.dart';

class StampStation {
  const StampStation(
    this.id,
    this.japanese,
    this.korean,
    this.english, {
    this.exclusion,
  });
  final String id;
  final String japanese;
  final String korean;
  final String english;
  final String? exclusion;
}

class StampLine {
  const StampLine({
    required this.id,
    required this.japanese,
    required this.korean,
    required this.english,
    required this.operator,
    required this.operatorKorean,
    required this.operatorEnglish,
    required this.regions,
    required this.stations,
    required this.source,
    this.partial = false,
    this.orderVerified = true,
    this.excludedStations = const [],
    this.sourceLineIds = const [],
    this.stationSections = const [],
  });
  final String id,
      japanese,
      korean,
      english,
      operator,
      operatorKorean,
      operatorEnglish,
      source;
  final List<String> regions;
  final List<StampStation> stations;
  final List<StampStation> excludedStations;

  /// Legal catalog provenance for a passenger-facing collection line.
  final List<String> sourceLineIds;

  /// Connected station sequences, including excluded stops. Junctions may
  /// repeat between sections; collection totals still use unique [stations].
  final List<List<StampStation>> stationSections;
  List<List<StampStation>> get orderedStationSections => stationSections.isEmpty
      ? [
          List.unmodifiable([...stations, ...excludedStations]),
        ]
      : stationSections;
  final bool partial, orderVerified;
}

const yamanoteStampLine = StampLine(
  id: 'yamanote',
  japanese: '山手線',
  korean: '야마노테선',
  english: 'Yamanote Line',
  operator: '東日本旅客鉄道',
  operatorKorean: 'JR동일본',
  operatorEnglish: 'JR East',
  regions: ['kanto'],
  stations: yamanoteStampStations,
  source: 'https://www.jreast.co.jp/suica/area/tokyo/',
);

/// Own curated membership/order, with names reused from tokunai_jr_data.json.
/// Not an official stamp/icon and not evidence of travelling the whole line.
const yamanoteStampStations = <StampStation>[
  StampStation('jr-east:tokyo', '東京', '도쿄', 'Tokyo'),
  StampStation('jr-east:kanda', '神田', '간다', 'Kanda'),
  StampStation('jr-east:akihabara', '秋葉原', '아키하바라', 'Akihabara'),
  StampStation('jr-east:okachimachi', '御徒町', '오카치마치', 'Okachimachi'),
  StampStation('jr-east:ueno', '上野', '우에노', 'Ueno'),
  StampStation('jr-east:uguisudani', '鶯谷', '우구이스다니', 'Uguisudani'),
  StampStation('jr-east:nippori', '日暮里', '닛포리', 'Nippori'),
  StampStation('jr-east:nishi-nippori', '西日暮里', '니시닛포리', 'Nishi-nippori'),
  StampStation('jr-east:tabata', '田端', '다바타', 'Tabata'),
  StampStation('jr-east:komagome', '駒込', '고마고메', 'Komagome'),
  StampStation('jr-east:sugamo', '巣鴨', '스가모', 'Sugamo'),
  StampStation('jr-east:otsuka', '大塚', '오쓰카', 'Otsuka'),
  StampStation('jr-east:ikebukuro', '池袋', '이케부쿠로', 'Ikebukuro'),
  StampStation('jr-east:mejiro', '目白', '메지로', 'Mejiro'),
  StampStation('jr-east:takadanobaba', '高田馬場', '다카다노바바', 'Takadanobaba'),
  StampStation('jr-east:shin-okubo', '新大久保', '신오쿠보', 'Shin-okubo'),
  StampStation('jr-east:shinjuku', '新宿', '신주쿠', 'Shinjuku'),
  StampStation('jr-east:yoyogi', '代々木', '요요기', 'Yoyogi'),
  StampStation('jr-east:harajuku', '原宿', '하라주쿠', 'Harajuku'),
  StampStation('jr-east:shibuya', '渋谷', '시부야', 'Shibuya'),
  StampStation('jr-east:ebisu', '恵比寿', '에비스', 'Ebisu'),
  StampStation('jr-east:meguro', '目黒', '메구로', 'Meguro'),
  StampStation('jr-east:gotanda', '五反田', '고탄다', 'Gotanda'),
  StampStation('jr-east:osaki', '大崎', '오사키', 'Osaki'),
  StampStation('jr-east:shinagawa', '品川', '시나가와', 'Shinagawa'),
  StampStation(
    'jr-east:takanawa-gateway',
    '高輪ゲートウェイ',
    '다카나와게이트웨이',
    'Takanawa Gateway',
  ),
  StampStation('jr-east:tamachi', '田町', '다마치', 'Tamachi'),
  StampStation('jr-east:hamamatsucho', '浜松町', '하마마쓰초', 'Hamamatsucho'),
  StampStation('jr-east:shimbashi', '新橋', '신바시', 'Shimbashi'),
  StampStation('jr-east:yurakucho', '有楽町', '유라쿠초', 'Yurakucho'),
];

abstract interface class StampCollectionStore {
  Future<List<String>> read();
  Future<void> write(List<String> ids);
}

/// Only derived station IDs persist when a store is provided.
/// No raw history, dates, card identity, balances or travel paths are retained.
class StationStampSession extends ChangeNotifier {
  StationStampSession({StampCollectionStore? store})
    : _store = store,
      _ready = store == null;
  final StampCollectionStore? _store;
  bool _ready, _disposed = false, _loading = false, _saveFailed = false;
  bool _loadFailed = false;
  int _revision = 0;
  Future<void> _pendingSave = Future.value();
  Future<void>? _restore;
  Future<List<String>>? _savedIds;
  int? _previewCount;
  bool get ready => _ready;
  int? get previewCount => _previewCount;
  bool get loading => _loading;
  bool get loadFailed => _loadFailed;
  bool get saveFailed => _saveFailed;
  Future<void> get pendingSave => _pendingSave;
  final Map<String, int> _counts = {};
  // Keep old nationwide awards without loading the archived catalog or
  // showing inactive stations. A later expansion can recognize these IDs.
  final _retainedIds = <String>{};
  static final _retiredIdFormat = RegExp(
    r'^(?:stamp:[0-9a-f]{16}|jr-east:[a-z0-9-]+)$',
  );

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<List<String>> _readSavedIds() => _savedIds ??= _readFromStore();

  Future<List<String>> _readFromStore() async {
    try {
      return await Future.sync(_store!.read);
    } catch (_) {
      _savedIds = null;
      rethrow;
    }
  }

  /// Home needs only its book's count, not the full collection or catalog.
  Future<void> loadPreviewCount(Set<String> bookIds) async {
    if (_ready || _disposed || _previewCount != null) return;
    try {
      final saved = await _readSavedIds();
      if (_ready || _disposed) return;
      _previewCount = saved.isEmpty
          ? 0
          : saved.where(bookIds.contains).toSet().length;
      _changed();
    } catch (_) {
      // A missing count is not zero. The collection can retry on entry.
    }
  }

  Future<void> restore() => _ready ? Future.value() : (_restore ??= _load());
  Future<void> _load() async {
    if (_store == null || _ready) return;
    _loading = true;
    _loadFailed = false;
    _changed();
    try {
      final saved = await _readSavedIds();
      if (_disposed) return;
      for (final id in saved) {
        if (_bookStampIds.contains(id)) {
          _collected.add(id);
        } else if (_retiredIdFormat.hasMatch(id)) {
          _retainedIds.add(id);
        }
      }
      _counts.clear();
      _ready = true;
    } catch (_) {
      _loadFailed = true;
    } finally {
      _savedIds = null;
      _loading = false;
      _restore = null;
      _changed();
    }
  }

  Future<void> retrySave() {
    if (_ready) _persist();
    return _pendingSave;
  }

  void _persist() {
    if (_store == null) return;
    final ids = [..._collected, ..._retainedIds]..sort();
    final revision = ++_revision;
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _store.write(ids);
        if (revision == _revision) _saveFailed = false;
      } catch (_) {
        if (revision == _revision) _saveFailed = true;
      }
      _changed();
    });
  }

  final Set<String> _collected = {};
  Set<String> get collected => Set.unmodifiable(_collected);
  int get count => _collected.length;

  int countFor(StampLine line) => _counts.putIfAbsent(
    line.id,
    () => line.stations.where((s) => _collected.contains(s.id)).length,
  );
  bool completeFor(StampLine line) =>
      line.stations.isNotEmpty && countFor(line) == line.stations.length;

  static Set<String> candidates(Iterable<ResolvedStationPair> railPairs) {
    final ids = <String>{};
    for (final pair in railPairs) {
      for (final resolution in [pair.boarding, pair.alighting]) {
        final record = resolution.station;
        // A resolved connecting/ambiguous operator must not earn a JR stamp.
        if (record == null) continue;
        final code = record.code;
        final match =
            _bookCodeStations['${code.regionCode}/${code.lineCode}/${code.stationCode}'];
        if (match != null &&
            match.operator == record.operatorName &&
            match.japanese == record.stationName) {
          ids.add(match.id);
        }
        if (record.operatorName == '東日本旅客鉄道' && code.regionCode == 0) {
          for (final station in yamanoteStampStations) {
            if (record.stationName == station.japanese) ids.add(station.id);
          }
        }
      }
    }
    return ids;
  }

  int collect(Iterable<String> candidates) {
    if (!_ready) return 0;
    final before = count;
    _collected.addAll(candidates.where(_bookStampIds.contains));
    if (count != before) {
      _counts.clear();
      _persist();
      _changed();
    }
    return count - before;
  }

  void clear() {
    if (!_ready) return;
    _collected.clear();
    _retainedIds.clear();
    _counts.clear();
    _persist();
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
