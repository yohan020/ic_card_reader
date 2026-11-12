import 'package:flutter/services.dart';
import '../domain/coin_locker_catalog.dart';

/// No NFC, session data, device location, or user input is added to the URL.
class CoinLockerLinkOpener {
  const CoinLockerLinkOpener();
  static const channel = MethodChannel('app.iccardreader/coin_locker_links');

  Future<bool> open(Uri uri) async {
    if (!isAllowedCoinLockerUri(uri)) return false;
    try {
      return await channel.invokeMethod<bool>('open', {
            'url': uri.toString(),
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
