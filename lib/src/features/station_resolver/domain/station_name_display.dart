enum StationNameDisplayMode { japanese, korean, both, english, japaneseEnglish }

extension StationNameDisplayModeLabel on StationNameDisplayMode {
  String get label => switch (this) {
    StationNameDisplayMode.japanese => '일본어',
    StationNameDisplayMode.korean => '한국어',
    StationNameDisplayMode.both => '함께 표시',
    StationNameDisplayMode.english => '영어',
    StationNameDisplayMode.japaneseEnglish => '일본어 + 영어',
  };
}

String displayStationName({
  required String japanese,
  required String? korean,
  String? english,
  required StationNameDisplayMode mode,
}) {
  if (mode == StationNameDisplayMode.english) {
    return english == null || english.trim().isEmpty ? japanese : english;
  }
  if (mode == StationNameDisplayMode.japaneseEnglish) {
    final translated = english?.trim();
    return translated == null || translated.isEmpty || translated == japanese
        ? japanese
        : '$japanese ($translated)';
  }
  if (korean == null ||
      korean.isEmpty ||
      mode == StationNameDisplayMode.japanese) {
    return japanese;
  }
  return switch (mode) {
    StationNameDisplayMode.japanese ||
    StationNameDisplayMode.japaneseEnglish ||
    StationNameDisplayMode.english => japanese,
    StationNameDisplayMode.korean => korean,
    StationNameDisplayMode.both => '$korean ($japanese)',
  };
}
