import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/coin_locker_catalog.dart';

class CoinLockerRepository {
  CoinLockerRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  static Future<CoinLockerCatalog>? _shared;
  Future<CoinLockerCatalog>? _local;

  Future<CoinLockerCatalog> load() {
    if (identical(_bundle, rootBundle)) {
      return _shared ??= _read().catchError((Object error) {
        _shared = null;
        throw error;
      });
    }
    return _local ??= _read().catchError((Object error) {
      _local = null;
      throw error;
    });
  }

  Future<CoinLockerCatalog> _read() async => CoinLockerCatalog.fromJson(
    jsonDecode(await _bundle.loadString('assets/data/coin_locker/catalog.json'))
        as Map<String, dynamic>,
  );
}
