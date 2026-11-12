import '../../../core/localization/app_strings.dart';
import '../domain/card_brand_identity.dart';

String cardBrandName(CardBrandIdentity brand, AppLocalizations l10n) {
  if (l10n.localeName != 'en') return brand.label;
  return switch (brand) {
    CardBrandIdentity.suicaFamily => 'Suica',
    CardBrandIdentity.kitaca => 'Kitaca',
    CardBrandIdentity.manaca => 'manaca',
    CardBrandIdentity.sugoca => 'SUGOCA',
    CardBrandIdentity.pasmo => 'PASMO',
    CardBrandIdentity.icoca => 'ICOCA',
    CardBrandIdentity.toica => 'TOICA',
    CardBrandIdentity.nimoca => 'nimoca',
    CardBrandIdentity.hayakaken => 'Hayakaken',
    CardBrandIdentity.ica => 'ICa',
  };
}
