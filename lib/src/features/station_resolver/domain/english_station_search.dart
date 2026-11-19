const _latinGroups = {
  'a': 'āáàâäãå',
  'e': 'ēéèêë',
  'i': 'īíìîï',
  'o': 'ōóòôöõ',
  'u': 'ūúùûü',
};
final _latinLetters = RegExp(r'[a-zāáàâäãåēéèêëīíìîïōóòôöõūúùûü]');
final _stationSuffix = RegExp(r'\s+(?:railway |train )?station$');
final _punctuation = RegExp(r"[\s\u0300-\u036f'’·・().（）–-]");
final _folding = {
  for (final group in _latinGroups.entries)
    for (final letter in group.value.split('')) letter: group.key,
};
final _accented = RegExp('[${_folding.keys.join()}]');

/// A station sign may use macrons or hyphens that users cannot easily type.
String englishStationSearchKey(String value) {
  final key = value.toLowerCase().trim();
  if (!_latinLetters.hasMatch(key)) return '';
  return key
      .replaceAllMapped(_accented, (m) => _folding[m[0]]!)
      .replaceFirst(_stationSuffix, '')
      .replaceAll(_punctuation, '');
}
