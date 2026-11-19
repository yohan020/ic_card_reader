import 'package:flutter/services.dart';

abstract interface class HistoryCsvSaver {
  /// False means that the user cancelled the system save dialog.
  Future<bool> save({required String filename, required Uint8List bytes});
}

class AndroidHistoryCsvSaver implements HistoryCsvSaver {
  const AndroidHistoryCsvSaver();

  static const channel = MethodChannel('app.iccardreader/history_csv');

  @override
  Future<bool> save({
    required String filename,
    required Uint8List bytes,
  }) async =>
      await channel.invokeMethod<bool>('save', {
        'filename': filename,
        'bytes': bytes,
      }) ??
      false;
}
