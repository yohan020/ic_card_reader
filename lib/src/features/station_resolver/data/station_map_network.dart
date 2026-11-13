import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Read Android's validated default network; never contact a probe server.
class StationMapNetwork {
  static const _channel = MethodChannel('app.iccardreader/maps');
  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // A shared broadcast stream keeps one native callback for all detail pages.
  static final Stream<bool> _changes = const EventChannel(
    'app.iccardreader/maps_network',
  ).receiveBroadcastStream().map((event) => event == true).distinct();

  static Stream<bool> get changes =>
      _supported ? _changes : const Stream<bool>.empty();

  static Future<bool> isOnline() async {
    if (!_supported) return false;
    try {
      return await _channel
              .invokeMethod<bool>('isNetworkAvailable')
              .timeout(const Duration(seconds: 3)) ==
          true;
    } catch (_) {
      return false;
    }
  }
}
