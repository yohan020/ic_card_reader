import 'contactless_alias.dart';
import 'contactless_english_names.dart';
import 'contactless_station_name.dart';
import '../../station_resolver/domain/english_station_search.dart';

class ContactlessLine {
  ContactlessLine(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get operatorId => data['operatorId'] as String;
  String get name => data['name'] as String;
  String get nameJa => data['nameJa'] as String;
  String get operatorName => data['operator'] as String;
  List<ContactlessAlias> get lineAliases => contactlessLineAliases(id);
  List<ContactlessAlias> get operatorAliases =>
      contactlessOperatorAliases(operatorId);
  String get displayName => withContactlessAliases(name, lineAliases);
  String get operatorDisplayName =>
      withContactlessAliases(operatorName, operatorAliases);
  String nameFor({required bool english}) =>
      english ? contactlessEnglishLines[id] ?? nameJa : displayName;
  String operatorNameFor({required bool english}) => english
      ? contactlessEnglishOperators[operatorId] ?? operatorName
      : operatorDisplayName;
  num? get operatorAnnualPassengersThousand =>
      data['operatorAnnualPassengersThousand'] as num?;
  String get status => data['status'] as String;
  bool get archived => data['archived'] == true;
  bool get connectionOnly => data['connectionOnly'] == true;
  List<String> strings(String key) => (data[key] as List? ?? []).cast<String>();
  List<Map<String, dynamic>> records(String key) =>
      (data[key] as List? ?? []).cast<Map<String, dynamic>>();
  String get label => switch (status) {
    'supported' => '전역 지원',
    'partial' => '일부 지원',
    'unsupported' => '미지원',
    'inferred' => '미지원(추정)',
    _ => '정보 미확인',
  };
  String labelFor({required bool english}) => !english
      ? label
      : switch (status) {
          'supported' => 'All stations',
          'partial' => 'Partial',
          'unsupported' => 'Not supported',
          'inferred' => 'Likely not supported',
          _ => 'Unverified',
        };
  int get eligibleCount =>
      records('stations').where((s) => s['eligible'] == true).length;
  String get summaryLabel => status == 'partial'
      ? (data['verifiedTotal'] != null && !connectionOnly ? '이용 가능한 역' : '대상 역')
      : status == 'supported'
      ? '지원 범위'
      : '지원 여부';
  String get summaryValue => status == 'partial'
      ? (data['verifiedTotal'] != null && !connectionOnly
            ? '$eligibleCount / ${data['verifiedTotal']}'
            : '$eligibleCount곳')
      : status == 'supported'
      ? '모든 역'
      : label;
  String summaryLabelFor({required bool english}) => !english
      ? summaryLabel
      : switch (status) {
          'partial' => 'Eligible stations',
          'supported' => 'Coverage',
          _ => 'Support',
        };
  String summaryValueFor({required bool english}) => !english
      ? summaryValue
      : status == 'partial'
      ? (data['verifiedTotal'] != null && !connectionOnly
            ? '$eligibleCount / ${data['verifiedTotal']}'
            : '$eligibleCount')
      : labelFor(english: true);
  bool matches(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return true;
    final names = [
      name,
      nameJa,
      operatorName,
      nameFor(english: true),
      operatorNameFor(english: true),
      ...strings('aliases'),
      for (final alias in [...lineAliases, ...operatorAliases]) ...[
        alias.ko,
        alias.ja,
      ],
    ];
    if (RegExp(r'^[ㄱ-ㅎ]+$').hasMatch(q)) {
      return names.any((s) => _initials(_normalize(s)).contains(q));
    }
    if (names.any((s) => _normalize(s).contains(q))) return true;
    final englishQuery = englishStationSearchKey(query);
    if (englishQuery.isNotEmpty &&
        [
          nameFor(english: true),
          operatorNameFor(english: true),
        ].any((name) => englishStationSearchKey(name).contains(englishQuery))) {
      return true;
    }
    return records('stations').any((station) {
      final name = station['name'];
      final stationId = station['id'];
      if (name is! String || stationId is! String) return false;
      final korean = contactlessStationKoreanName(id, stationId, name);
      if (_normalize(name).contains(q) ||
          (korean != null && _normalize(korean).contains(q))) {
        return true;
      }
      final english = contactlessStationEnglishName(id, stationId, name);
      return english != null &&
          englishQuery.isNotEmpty &&
          englishStationSearchKey(english).contains(englishQuery);
    });
  }
}

/// Common-year MLIT ridership is a discoverability proxy, not a popularity score.
/// Unknown operators remain visible after ranked operators, with stable ties.
int compareContactlessOperators(ContactlessLine a, ContactlessLine b) {
  final aPassengers = a.operatorAnnualPassengersThousand;
  final bPassengers = b.operatorAnnualPassengersThousand;
  if (aPassengers != null && bPassengers != null) {
    final byPassengers = bPassengers.compareTo(aPassengers);
    if (byPassengers != 0) return byPassengers;
  } else if (aPassengers != null) {
    return -1;
  } else if (bPassengers != null) {
    return 1;
  }
  final byName = a.operatorName.compareTo(b.operatorName);
  return byName != 0 ? byName : a.operatorId.compareTo(b.operatorId);
}

String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');
String _initials(String s) {
  const initials = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
  return String.fromCharCodes(
    s.runes.map(
      (r) => r >= 0xAC00 && r <= 0xD7A3
          ? initials.codeUnitAt((r - 0xAC00) ~/ 588)
          : r,
    ),
  );
}

class ContactlessCatalog {
  ContactlessCatalog(
    this.lines, {
    required this.attribution,
    required this.releaseReviewPending,
  });
  final List<ContactlessLine> lines;
  final String attribution;
  final bool releaseReviewPending;
  factory ContactlessCatalog.fromJson(Map<String, dynamic> data) {
    if (data['schema'] != 1) {
      throw const FormatException('Unknown contactless schema');
    }
    final lines = (data['lines'] as List)
        .map((l) => ContactlessLine(l as Map<String, dynamic>))
        .toList(growable: false);
    if (lines.isEmpty ||
        lines.map((l) => l.id).toSet().length != lines.length) {
      throw const FormatException('Invalid contactless catalog');
    }
    return ContactlessCatalog(
      lines,
      attribution: data['attribution'] as String,
      releaseReviewPending: data['releaseReviewPending'] != false,
    );
  }
  List<ContactlessLine> search(String query, String? region) => lines
      .where(
        (l) =>
            !l.archived &&
            (region == null || l.strings('regions').contains(region)) &&
            l.matches(query),
      )
      .toList(growable: false);
}
