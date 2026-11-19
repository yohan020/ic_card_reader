import 'dart:async';

import '../../../../core/localization/app_strings.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/widgets/app_ui.dart';
import '../../../station_resolver/data/station_coordinate_repository.dart';
import '../../../station_resolver/data/station_map_network.dart';
import '../../../station_resolver/domain/station_name_display.dart';
import '../../../station_resolver/domain/station_resolution.dart';

typedef StationMapBuilder =
    Widget Function(
      StationCoordinate boarding,
      StationCoordinate alighting,
      String boardingName,
      String alightingName,
    );

typedef StationGroupMapBuilder =
    Widget Function(
      StationMapLocations boarding,
      StationMapLocations alighting,
      String boardingName,
      String alightingName,
    );

enum _MapMessage {
  offline,
  unknownStations,
  configUnavailable,
  preparationFailed,
}

class HistoryStationMap extends StatefulWidget {
  const HistoryStationMap({
    required this.stations,
    required this.displayMode,
    super.key,
    this.loadCoordinates,
    this.checkConfiguration,
    this.checkNetwork,
    this.networkChanges,
    this.mapBuilder,
    this.groupMapBuilder,
  });

  final ResolvedStationPair? stations;
  final StationNameDisplayMode displayMode;
  final Future<StationCoordinateRepository> Function()? loadCoordinates;
  final Future<bool> Function()? checkConfiguration;
  final Future<bool> Function()? checkNetwork;
  final Stream<bool>? networkChanges;
  final StationMapBuilder? mapBuilder;
  final StationGroupMapBuilder? groupMapBuilder;

  @override
  State<HistoryStationMap> createState() => _HistoryStationMapState();
}

class _HistoryStationMapState extends State<HistoryStationMap> {
  bool _opening = true;
  bool _visible = false;
  int _request = 0;
  _MapMessage? _message;
  StationMapLocations? _boarding;
  StationMapLocations? _alighting;
  StreamSubscription<bool>? _networkSubscription;
  bool? _online;

  @override
  void initState() {
    super.initState();
    _listenToNetwork();
    _scheduleOpen();
  }

  void _listenToNetwork({bool includeDefault = false}) {
    if (widget.networkChanges == null && !includeDefault) return;
    _networkSubscription = (widget.networkChanges ?? StationMapNetwork.changes)
        .listen(
          _networkChanged,
          onError: (Object error) => _networkChanged(false),
        );
  }

  void _networkChanged(bool online) {
    if (!mounted) return;
    if (_online == online && !online && !_visible && !_opening) return;
    _online = online;
    if (online) return; // Reconnection requires the user's refresh action.
    _request++;
    setState(() {
      _visible = false;
      _opening = false;
      _message = _MapMessage.offline;
    });
  }

  Future<bool> _checkNetwork() async {
    try {
      return await (widget.checkNetwork ?? StationMapNetwork.isOnline)()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _request++;
    _networkSubscription?.cancel();
    super.dispose();
  }

  void _scheduleOpen() {
    final scheduled = _request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scheduled == _request) _open();
    });
  }

  @override
  void didUpdateWidget(covariant HistoryStationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkChanges != widget.networkChanges) {
      _networkSubscription?.cancel();
      _networkSubscription = null;
      _listenToNetwork();
    }
    if (!_sameResolution(
          oldWidget.stations?.boarding,
          widget.stations?.boarding,
        ) ||
        !_sameResolution(
          oldWidget.stations?.alighting,
          widget.stations?.alighting,
        )) {
      _request++;
      _visible = false;
      _opening = true;
      _message = null;
      _boarding = null;
      _alighting = null;
      _scheduleOpen();
    }
  }

  static bool _sameResolution(StationResolution? a, StationResolution? b) =>
      a?.requestedCode == b?.requestedCode &&
      a?.strategy == b?.strategy &&
      a?.station?.code == b?.station?.code &&
      a?.station?.stationName == b?.station?.stationName &&
      a?.station?.operatorName == b?.station?.operatorName &&
      a?.station?.lineName == b?.station?.lineName;

  bool _current(int request) => mounted && request == _request;

  Future<void> _open() async {
    final request = ++_request;
    final stations = widget.stations;
    setState(() {
      _opening = true;
      _visible = false;
      _message = null;
    });
    try {
      if (stations?.boarding.station == null ||
          stations?.alighting.station == null) {
        setState(() => _message = _MapMessage.unknownStations);
        return;
      }
      final online = await _checkNetwork();
      if (!_current(request)) return;
      _online = online;
      if (!online) {
        setState(() => _message = _MapMessage.offline);
        return;
      }
      if (_networkSubscription == null) _listenToNetwork(includeDefault: true);
      final repository =
          await (widget.loadCoordinates ?? StationCoordinateRepository.load)();
      if (!_current(request)) return;
      final boarding = repository.findLocations(stations?.boarding);
      final alighting = repository.findLocations(stations?.alighting);
      if (boarding == null || alighting == null) {
        if (_current(request)) {
          setState(() => _message = _MapMessage.unknownStations);
        }
        return;
      }
      final configured = await (widget.checkConfiguration ?? _isConfigured)();
      if (!_current(request)) return;
      if (!configured) {
        setState(() => _message = _MapMessage.configUnavailable);
        return;
      }
      // The network may have changed while coordinates/configuration loaded.
      final stillOnline = await _checkNetwork();
      if (!_current(request)) return;
      _online = stillOnline;
      if (!stillOnline) {
        setState(() => _message = _MapMessage.offline);
        return;
      }
      setState(() {
        _boarding = boarding;
        _alighting = alighting;
        _visible = true;
      });
    } catch (_) {
      if (_current(request)) {
        setState(() => _message = _MapMessage.preparationFailed);
      }
    } finally {
      if (_current(request)) setState(() => _opening = false);
    }
  }

  static Future<bool> _isConfigured() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    return await const MethodChannel(
          'app.iccardreader/maps',
        ).invokeMethod<bool>('isConfigured') ??
        false;
  }

  String _name(StationResolution? resolution) {
    final station = resolution?.station;
    if (station == null) return strings(context).unknown;
    return displayStationName(
      japanese: station.stationName,
      korean: station.stationNameKorean,
      english: station.stationNameEnglish,
      mode: widget.displayMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = strings(context);
    final boardingName = _name(widget.stations?.boarding);
    final alightingName = _name(widget.stations?.alighting);
    final grouped =
        (_boarding?.isGroup ?? false) || (_alighting?.isGroup ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings(context).stationLocations,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        AppSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_visible) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    key: const ValueKey('history-station-map-viewport'),
                    height: 220,
                    // A refresh replaces the platform view instead of reusing a blank map.
                    child: KeyedSubtree(
                      key: ValueKey(_request),
                      child: grouped
                          ? (widget.groupMapBuilder ??
                                (a, b, from, to) => buildStationGroupGoogleMap(
                                  a,
                                  b,
                                  from,
                                  to,
                                  l10n: l10n,
                                  englishStationNames:
                                      widget.displayMode ==
                                      StationNameDisplayMode.english,
                                  bilingualStationNames:
                                      widget.displayMode ==
                                      StationNameDisplayMode.japaneseEnglish,
                                ))(
                              _boarding!,
                              _alighting!,
                              boardingName,
                              alightingName,
                            )
                          : (widget.mapBuilder ??
                                (a, b, from, to) => buildStationGoogleMap(
                                  a,
                                  b,
                                  from,
                                  to,
                                  l10n: l10n,
                                ))(
                              _boarding!.points.single,
                              _alighting!.points.single,
                              boardingName,
                              alightingName,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings(context).mapLegend,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (grouped) ...[
                  const SizedBox(height: 4),
                  Text(
                    strings(context).mapCandidates,
                    key: const ValueKey('history-station-map-candidates'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else if (_opening) ...[
                SizedBox(
                  height: 220,
                  key: const ValueKey('history-station-map-loading'),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings(context).mapLoading,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                if (_message != null) ...[
                  Text(
                    switch (_message!) {
                      _MapMessage.offline => l10n.mapOffline,
                      _MapMessage.unknownStations =>
                        l10n.mapStationsUnavailable,
                      _MapMessage.configUnavailable =>
                        l10n.mapConfigUnavailable,
                      _MapMessage.preparationFailed =>
                        l10n.mapPreparationFailed,
                    },
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              if (!_opening &&
                  !_visible &&
                  _message == _MapMessage.offline) ...[
                const SizedBox(height: 8),
                Center(
                  child: OutlinedButton.icon(
                    key: const ValueKey('history-station-map-refresh'),
                    onPressed: _open,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(144, 40),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary, width: 1.3),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(strings(context).refreshMap),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              Text(
                strings(context).mapAttribution,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// No Map ID, advanced markers, geocoding, routes, or device location.
final _korean = AppLocalizationsKo();

GoogleMap buildStationGoogleMap(
  StationCoordinate boarding,
  StationCoordinate alighting,
  String boardingName,
  String alightingName, {
  AppLocalizations? l10n,
}) {
  final labels = l10n ?? _korean;
  final from = LatLng(boarding.latitude, boarding.longitude);
  final to = LatLng(alighting.latitude, alighting.longitude);
  final samePlace = from == to;
  return GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(
        (from.latitude + to.latitude) / 2,
        (from.longitude + to.longitude) / 2,
      ),
      zoom: samePlace ? 14 : 10,
    ),
    markers: {
      Marker(
        markerId: const MarkerId('boarding'),
        position: from,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: samePlace
              ? labels.mapBoth(boardingName)
              : labels.mapBoarding(boardingName),
        ),
      ),
      if (!samePlace)
        Marker(
          markerId: const MarkerId('alighting'),
          position: to,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(title: labels.mapAlighting(alightingName)),
        ),
    },
    myLocationEnabled: false,
    myLocationButtonEnabled: false,
    mapToolbarEnabled: false,
    compassEnabled: false,
    rotateGesturesEnabled: false,
    tiltGesturesEnabled: false,
    zoomControlsEnabled: false,
    onMapCreated: (controller) async {
      if (samePlace) return;
      try {
        await controller.moveCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                math.min(from.latitude, to.latitude),
                math.min(from.longitude, to.longitude),
              ),
              northeast: LatLng(
                math.max(from.latitude, to.latitude),
                math.max(from.longitude, to.longitude),
              ),
            ),
            36,
          ),
        );
      } catch (_) {
        /* The detail page may already have been closed. */
      }
    },
  );
}

/// Displays a reviewed set, never a synthetic midpoint or an inferred trip path.
GoogleMap buildStationGroupGoogleMap(
  StationMapLocations boarding,
  StationMapLocations alighting,
  String boardingName,
  String alightingName, {
  AppLocalizations? l10n,
  bool englishStationNames = false,
  bool bilingualStationNames = false,
}) {
  final labels = l10n ?? _korean;
  final places =
      <String, List<({bool boards, String role, StationCoordinate point})>>{};
  for (final side in [
    (
      locations: boarding,
      name: boardingName,
      role: labels.boarding,
      boards: true,
    ),
    (
      locations: alighting,
      name: alightingName,
      role: labels.alighting,
      boards: false,
    ),
  ]) {
    for (final point in side.locations.points) {
      final key = '${point.latitude}/${point.longitude}';
      (places[key] ??= []).add((
        boards: side.boards,
        role: side.locations.isGroup
            ? labels.mapCandidateRole(side.role)
            : side.role,
        point: StationCoordinate(
          point.latitude,
          point.longitude,
          name: bilingualStationNames
              ? switch (point.name) {
                  final japanese? => displayStationName(
                    japanese: japanese,
                    korean: null,
                    english: point.englishName,
                    mode: StationNameDisplayMode.japaneseEnglish,
                  ),
                  null => side.name,
                }
              : (englishStationNames
                        ? point.englishName ??
                              (side.locations.isGroup ? null : side.name)
                        : null) ??
                    point.name ??
                    side.name,
          description: point.description,
        ),
      ));
    }
  }
  final markers = <Marker>{};
  var south = 90.0;
  var north = -90.0;
  var west = 180.0;
  var east = -180.0;
  for (final entries in places.values) {
    final p = entries.first.point;
    south = math.min(south, p.latitude);
    north = math.max(north, p.latitude);
    west = math.min(west, p.longitude);
    east = math.max(east, p.longitude);
    markers.add(
      Marker(
        markerId: MarkerId('location_${markers.length}'),
        position: LatLng(p.latitude, p.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          entries.any((e) => e.boards)
              ? BitmapDescriptor.hueAzure
              : BitmapDescriptor.hueRose,
        ),
        infoWindow: InfoWindow(
          title:
              '${entries.map((e) => e.role).toSet().join('·')} · ${entries.map((e) => e.point.name).toSet().join(' / ')}',
          snippet: entries
              .map((e) => e.point.description)
              .whereType<String>()
              .toSet()
              .join(' / '),
        ),
      ),
    );
  }
  final bounds = LatLngBounds(
    southwest: LatLng(south, west),
    northeast: LatLng(north, east),
  );
  return GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng((south + north) / 2, (west + east) / 2),
      zoom: markers.length == 1 ? 14 : 10,
    ),
    markers: markers,
    myLocationEnabled: false,
    myLocationButtonEnabled: false,
    mapToolbarEnabled: false,
    compassEnabled: false,
    rotateGesturesEnabled: false,
    tiltGesturesEnabled: false,
    zoomControlsEnabled: false,
    onMapCreated: (controller) async {
      if (markers.length < 2) return;
      try {
        await controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, 36));
      } catch (_) {
        // The detail page may already have been closed.
      }
    },
  );
}
