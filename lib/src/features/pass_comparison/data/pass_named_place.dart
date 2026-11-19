/// Stable station identity and names, independent of UI language and fares.
abstract interface class PassNamedPlace {
  String get nameJa;
  String get nameKo;
  String get nameEn;
  String get secondaryLabel;
}
