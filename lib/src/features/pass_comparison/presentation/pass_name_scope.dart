import 'package:flutter/widgets.dart';

import '../../station_resolver/domain/station_name_display.dart';
import '../data/pass_named_place.dart';
import 'pass_strings.dart';

/// Lives above the Navigator so every pushed pass/search/result route observes
/// the setting without changing selected IDs or calculator inputs.
class PassNameScope extends InheritedWidget {
  const PassNameScope({required this.mode, required super.child, super.key});
  final StationNameDisplayMode mode;

  static StationNameDisplayMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PassNameScope>()?.mode ??
      StationNameDisplayMode.korean;

  @override
  bool updateShouldNotify(PassNameScope oldWidget) => mode != oldWidget.mode;
}

extension PassPlacePresentation on PassNamedPlace {
  String passName(BuildContext context) => displayStationName(
    japanese: nameJa,
    korean: nameKo.replaceFirst(RegExp(r'역$'), ''),
    english: nameEn,
    mode: PassNameScope.of(context),
  );

  String passSecondary(BuildContext context) => secondaryLabel
      .split(' · ')
      .map((part) => passText(context, part))
      .join(' · ');
}
