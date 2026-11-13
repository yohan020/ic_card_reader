import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../domain/contactless_catalog.dart';

class ContactlessRepository {
  ContactlessRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  static Future<ContactlessCatalog>? _shared;
  Future<ContactlessCatalog>? _local;
  Future<ContactlessCatalog> load() {
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

  Future<ContactlessCatalog> _read() async {
    final bytes = await _bundle.load('assets/data/contactless/catalog.bin');
    return compute(
      _decode,
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }
}

ContactlessCatalog _decode(Uint8List bytes) => ContactlessCatalog.fromJson(
  jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>,
);
