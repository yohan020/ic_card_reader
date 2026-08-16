enum StationNameDisplayMode { japanese, korean, both }

extension StationNameDisplayModeLabel on StationNameDisplayMode {
  String get label => switch (this) {
    StationNameDisplayMode.japanese => '일본어',
    StationNameDisplayMode.korean => '한국어',
    StationNameDisplayMode.both => '함께 표시',
  };
}

String displayStationName({
  required String japanese,
  required String? korean,
  required StationNameDisplayMode mode,
}) {
  if (korean == null ||
      korean.isEmpty ||
      mode == StationNameDisplayMode.japanese) {
    return japanese;
  }
  return switch (mode) {
    StationNameDisplayMode.japanese => japanese,
    StationNameDisplayMode.korean => korean,
    StationNameDisplayMode.both => '$korean ($japanese)',
  };
}
