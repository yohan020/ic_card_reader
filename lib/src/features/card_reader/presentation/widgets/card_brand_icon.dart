import 'package:flutter/material.dart';

import '../../../../core/design/app_theme.dart';
import '../../domain/card_brand_identity.dart';
import 'card_brand_icon_frame.dart';
import 'hayakaken_card_icon.dart';
import 'ica_card_icon.dart';
import 'icoca_card_icon.dart';
import 'kitaca_card_icon.dart';
import 'manaca_card_icon.dart';
import 'nimoca_card_icon.dart';
import 'pasmo_card_icon.dart';
import 'sugoca_card_icon.dart';
import 'suica_card_icon.dart';
import 'toica_card_icon.dart';

/// Only approved display identities. PiTaPa is deliberately not activated.
class CardBrandIcon extends StatelessWidget {
  const CardBrandIcon({this.identity, this.prominent = false, super.key});

  final CardBrandIdentity? identity;
  final bool prominent;

  @override
  Widget build(BuildContext context) =>
      prominent ? CardBrandIconBalanceScope(child: _buildIcon()) : _buildIcon();

  Widget _buildIcon() => switch (identity) {
    CardBrandIdentity.suicaFamily => const SuicaCardIcon(),
    CardBrandIdentity.kitaca => const KitacaCardIcon(),
    CardBrandIdentity.manaca => const ManacaCardIcon(),
    CardBrandIdentity.sugoca => const SugocaCardIcon(),
    CardBrandIdentity.pasmo => const PasmoCardIcon(),
    CardBrandIdentity.icoca => const IcocaCardIcon(),
    CardBrandIdentity.toica => const ToicaCardIcon(),
    CardBrandIdentity.nimoca => const NimocaCardIcon(),
    CardBrandIdentity.hayakaken => const HayakakenCardIcon(),
    CardBrandIdentity.ica => const IcaCardIcon(),
    null when prominent => SizedBox.fromSize(
      size: cardBrandBalanceSize,
      child: const Icon(
        Icons.account_balance_wallet_outlined,
        size: 66,
        color: AppColors.skyDark,
      ),
    ),
    null => Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.skySoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.account_balance_wallet_outlined,
        color: AppColors.skyDark,
      ),
    ),
  };
}
