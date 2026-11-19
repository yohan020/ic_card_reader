import 'dart:async';

import 'enoden_noriorikun_pass_data.dart';
import 'enokama_pass_data.dart';
import 'fukuoka_city_subway_pass_data.dart';
import 'sapporo_subway_pass_data.dart';
import 'hakone_freepass_data.dart';
import 'hankyu_1day_pass_data.dart';
import 'hiroden_pass_data.dart';
import 'hokkaido_rail_pass_data.dart';
import 'kintetsu_rail_pass_5day_data.dart';
import 'kyoto_subway_bus_pass_data.dart';
import 'kyoto_subway_1day_pass_data.dart';
import 'nagasaki_electric_tramway_pass_data.dart';
import 'osaka_pass_station_data.dart';
import 'okayama_kurashiki_gururin_pass_data.dart';
import 'yui_rail_pass_data.dart';
import 'pass_transit_data.dart';

/// The groups shown in the pass region list.
///
/// Keeping these independent prevents one large dataset from blocking the
/// transition into the region selection UI.
enum PassComparisonDataGroup {
  hokkaido,
  kanto,
  kansai,
  chugoku,
  kyushu,
  okinawa,
}

/// Warms a selected region first, then prepares other regions sequentially.
///
/// Individual repositories own their typed cache, so a pass page always awaits
/// the same work instead of loading and parsing its assets a second time.
class PassComparisonDataPreloader {
  const PassComparisonDataPreloader._();

  static final Map<PassComparisonDataGroup, Future<void>> _regionWarmUps =
      <PassComparisonDataGroup, Future<void>>{};
  static final Map<PassComparisonDataGroup, Future<void>> _remainingWarmUps =
      <PassComparisonDataGroup, Future<void>>{};

  /// Starts only the data needed by [group]. This method never waits on other
  /// regions, so the selected region remains the highest priority.
  static void warmUpRegion(PassComparisonDataGroup group) =>
      unawaited(_regionWarmUps.putIfAbsent(group, () => _loadGroup(group)));

  /// Lets the selected region finish first, then warms the rest one at a time
  /// after the region list has had time to render.
  static void warmUpRemainingAfter(PassComparisonDataGroup selected) {
    unawaited(
      _remainingWarmUps.putIfAbsent(selected, () async {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        for (final group in PassComparisonDataGroup.values) {
          if (group == selected) continue;
          await _regionWarmUps.putIfAbsent(group, () => _loadGroup(group));
          await Future<void>.delayed(const Duration(milliseconds: 32));
        }
      }),
    );
  }

  static Future<void> _loadGroup(PassComparisonDataGroup group) async {
    try {
      await switch (group) {
        PassComparisonDataGroup.hokkaido => Future.wait([
          const HokkaidoRailPassDataRepository().load(),
          const SapporoSubwayPassDataRepository().load(),
        ]),
        PassComparisonDataGroup.kanto => Future.wait([
          const PassTransitDataRepository().load(),
          const EnokamaPassDataRepository().load(),
          const EnodenNoriorikunPassDataRepository().load(),
          const HakoneFreepassDataRepository().load(),
        ]),
        PassComparisonDataGroup.kansai => Future.wait([
          const PassTransitDataRepository().load(),
          const OsakaPassStationDataRepository().load(),
          const KyotoSubwayBusPassDataRepository().load(),
          const KyotoSubway1DayPassDataRepository().load(),
          const Hankyu1DayPassDataRepository().load(),
          const KintetsuRailPass5DayDataRepository().load(),
        ]),
        PassComparisonDataGroup.chugoku => Future.wait([
          const OkayamaKurashikiGururinPassDataRepository().load(),
          const HirodenPassDataRepository().load(),
        ]),
        PassComparisonDataGroup.kyushu => Future.wait([
          const FukuokaCitySubwayPassDataRepository().load(),
          const NagasakiElectricTramwayPassDataRepository().load(),
        ]),
        PassComparisonDataGroup.okinawa =>
          const YuiRailPassDataRepository().load(),
      };
    } catch (_) {
      // A destination page retains responsibility for showing its retry UI.
    }
  }
}
