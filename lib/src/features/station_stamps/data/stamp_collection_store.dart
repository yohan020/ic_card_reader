import 'package:shared_preferences/shared_preferences.dart';
import '../domain/station_stamp_session.dart';

/// Only derived station IDs. No history, timestamps, card IDs or balances.
class PreferencesStampCollectionStore implements StampCollectionStore {
  static const key = 'station_stamps.collected_ids.v1';
  @override
  Future<List<String>> read() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return preferences.getStringList(key) ?? const [];
  }

  @override
  Future<void> write(List<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setStringList(key, ids)) {
      throw StateError('stamp collection write rejected');
    }
  }
}
