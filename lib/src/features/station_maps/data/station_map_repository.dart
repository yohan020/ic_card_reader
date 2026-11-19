import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../coin_locker/data/coin_locker_repository.dart';
import '../domain/station_map_catalog.dart';

Map<String, dynamic> _decodeMaps(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

class StationMapRepository {
  StationMapRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  static Future<StationMapCatalog>? _shared;
  Future<StationMapCatalog>? _local;
  Future<StationMapCatalog> load() {
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

  Future<StationMapCatalog> _read() async {
    final names = await CoinLockerRepository(bundle: _bundle).load();
    final text = await _bundle.loadString(
      'assets/data/station_maps/catalog.json',
    );
    final json = await compute(_decodeMaps, text);
    return StationMapCatalog.fromJson(json, names);
  }
}

class StationMapLinkOpener {
  const StationMapLinkOpener();
  Future<bool> open(Uri uri) async {
    if (!isAllowedStationMapUri(uri)) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
