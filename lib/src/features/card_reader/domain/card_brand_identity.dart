/// Optional, session-only visual identity. Never a card or product identifier.
enum CardBrandIdentity {
  /// The observed pattern also occurs on regional cards such as KURURU.
  suicaFamily,
  kitaca,
  manaca,
  sugoca,
  pasmo,
  icoca,
  toica,
  nimoca,
  hayakaken,
  ica;

  String get label => switch (this) {
    // Display shorthand only; regional Suica-family products remain unresolved.
    suicaFamily => '스이카',
    kitaca => '키타카',
    manaca => '마나카',
    sugoca => '스고카',
    pasmo => '파스모',
    icoca => '이코카',
    toica => '토이카',
    nimoca => '니모카',
    hayakaken => '하야카켄',
    ica => 'ICa',
  };
}
