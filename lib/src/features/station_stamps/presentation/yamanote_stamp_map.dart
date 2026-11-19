import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../domain/station_stamp_session.dart';
import '../domain/stamp_book_catalog.dart';
import 'stamp_book_style.dart';
import 'two_finger_diagram.dart';

/// Derived from the existing CC0 station coordinate asset, Tokyo-first order.
/// Coordinates connect station locations, not the actual railway track shape.
const yamanoteStampCoordinates = <(double, double)>[
  (35.681236, 139.767125),
  (35.69177, 139.770875),
  (35.698535, 139.773045),
  (35.707327777, 139.774847222),
  (35.71322, 139.775855),
  (35.721299833, 139.7783),
  (35.727986666, 139.77119),
  (35.732175, 139.766715),
  (35.7379, 139.761254),
  (35.736615, 139.747258),
  (35.73372, 139.74035),
  (35.731438888, 139.728691666),
  (35.7302, 139.71116),
  (35.720994444, 139.706880555),
  (35.7133125, 139.703965),
  (35.701063888, 139.700227777),
  (35.690833333, 139.700277777),
  (35.683827777, 139.702319444),
  (35.670233333, 139.702680555),
  (35.657954, 139.701742),
  (35.64668, 139.710125),
  (35.633405714, 139.715727142),
  (35.62606, 139.723696),
  (35.6197, 139.72855),
  (35.628135, 139.738535),
  (35.6355, 139.7407),
  (35.6456, 139.748),
  (35.655230555, 139.757627777),
  (35.66639, 139.7582),
  (35.67504, 139.76326),
];

String stampStationName(StampStation station, StationNameDisplayMode mode) =>
    displayStationName(
      japanese: station.japanese,
      korean: stampBookStationKorean(station),
      english: station.english,
      mode: mode,
    );

/// Real, isotropic local equirectangular projection. North is up.
List<Offset> projectYamanote(Size size) {
  const latitude = 35.6871128236;
  final raw = yamanoteStampCoordinates
      .map((c) => Offset(c.$2 * math.cos(latitude * math.pi / 180), -c.$1))
      .toList();
  final minX = raw.map((p) => p.dx).reduce(math.min),
      maxX = raw.map((p) => p.dx).reduce(math.max);
  final minY = raw.map((p) => p.dy).reduce(math.min),
      maxY = raw.map((p) => p.dy).reduce(math.max);
  final scale = math.min(
    (size.width - 170) / (maxX - minX),
    (size.height - 85) / (maxY - minY),
  );
  final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
  return raw
      .map(
        (p) => (p - center) * scale + Offset(size.width / 2, size.height / 2),
      )
      .toList();
}

/// Same north-up, isotropic coordinate projection for the open Mitaka–Chiba route.
List<Offset> projectChuoSobu(Size size) {
  const latitude = 35.69;
  final raw = chuoSobuBookCoordinates
      .map((c) => Offset(c.$2 * math.cos(latitude * math.pi / 180), -c.$1))
      .toList();
  final minX = raw.map((p) => p.dx).reduce(math.min),
      maxX = raw.map((p) => p.dx).reduce(math.max);
  final minY = raw.map((p) => p.dy).reduce(math.min),
      maxY = raw.map((p) => p.dy).reduce(math.max);
  final factor = math.min(
    (size.width - 400) / (maxX - minX),
    (size.height - 400) / (maxY - minY),
  );
  final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
  return raw
      .map(
        (p) => (p - center) * factor + Offset(size.width / 2, size.height / 2),
      )
      .toList();
}

/// Place names beside station dots, not at the far end of long leader lines.
/// Alternate nearby above/below positions, then try small offsets only when
/// another name or station dot would overlap. Coordinates never move.
List<Rect> layoutChuoSobuLabels(
  List<Offset> points,
  List<Size> labels,
  Size canvas,
) {
  assert(points.length == labels.length);
  final occupied = <Rect>[];
  final nodes = points
      .map((p) => Rect.fromCircle(center: p, radius: 7))
      .toList();
  for (var i = 0; i < points.length; i++) {
    final p = points[i], label = labels[i];
    Rect? chosen;
    for (final gap in [9.0, 14.0, 22.0, 34.0, 50.0]) {
      for (final above in [i.isEven, !i.isEven]) {
        for (final dx in [-label.width / 2, -label.width + 8, -8.0]) {
          final r = Rect.fromLTWH(
            p.dx + dx,
            above ? p.dy - gap - label.height : p.dy + gap,
            label.width,
            label.height,
          );
          if (r.left < 3 ||
              r.right > canvas.width - 3 ||
              r.top < 3 ||
              r.bottom > canvas.height - 3) {
            continue;
          }
          if (occupied.any((other) => other.inflate(3).overlaps(r)) ||
              nodes.any((node) => node.overlaps(r))) {
            continue;
          }
          chosen = r;
          break;
        }
        if (chosen != null) {
          break;
        }
      }
      if (chosen != null) {
        break;
      }
    }
    occupied.add(
      chosen ??
          Rect.fromLTWH(
            p.dx + 9,
            p.dy - label.height / 2,
            label.width,
            label.height,
          ),
    );
  }
  return occupied;
}

enum StampBookDiagramKind {
  yamanote,
  chuoSobu,
  midosuji,
  osakaLoop;

  static StampBookDiagramKind forLine(StampLine line) => switch (line.id) {
    'yamanote' => yamanote,
    'service:jr-east:chuo-sobu-local' => chuoSobu,
    'N02-7693ee9aa33e' => midosuji,
    'N02-239d98587238' => osakaLoop,
    _ => throw ArgumentError.value(line.id, 'line', 'No diagram profile'),
  };

  List<StampStation> get stations => switch (this) {
    yamanote => yamanoteStampStations,
    chuoSobu => chuoSobuBookStations,
    midosuji => midosujiBookStations,
    osakaLoop => osakaLoopBookStations,
  };

  Color get color => switch (this) {
    yamanote => StampBookRouteColors.yamanote,
    chuoSobu => StampBookRouteColors.chuoSobu,
    midosuji => StampBookRouteColors.midosuji,
    osakaLoop => StampBookRouteColors.osakaLoop,
  };

  bool get focusesStation => this == chuoSobu;
  bool get closed => this == yamanote || this == osakaLoop;
  double get minimumScale => focusesStation ? .02 : .2;

  List<Offset> project(Size size) => switch (this) {
    yamanote => projectYamanote(size),
    chuoSobu => projectChuoSobu(size),
    midosuji => projectMidosuji(size),
    osakaLoop => _projectOsaka(osakaLoopBookCoordinates, size),
  };
}

List<Offset> projectMidosuji(Size size) =>
    _projectOsaka(midosujiBookCoordinates, size);

bool _segmentTouchesLabel(Offset a, Offset b, Rect label) {
  final bounds = Rect.fromPoints(a, b).inflate(.01);
  if (!bounds.overlaps(label)) return false;
  final delta = b - a;
  final sides =
      [label.topLeft, label.topRight, label.bottomLeft, label.bottomRight].map((
        corner,
      ) {
        final point = corner - a;
        return delta.dx * point.dy - delta.dy * point.dx;
      });
  return sides.any((side) => side <= 0) && sides.any((side) => side >= 0);
}

bool _loopTouchesLabel(List<Offset> points, Rect label) {
  for (var i = 0; i < points.length; i++) {
    if (_segmentTouchesLabel(
      points[i],
      points[(i + 1) % points.length],
      label,
    )) {
      return true;
    }
  }
  return false;
}

List<Offset> _projectOsaka(List<(double, double)> coordinates, Size size) {
  final longitudeScale = math.cos(34.68 * math.pi / 180);
  final points = coordinates
      .map((p) => Offset(p.$2 * longitudeScale, -p.$1))
      .toList(growable: false);
  final minX = points.map((p) => p.dx).reduce(math.min);
  final maxX = points.map((p) => p.dx).reduce(math.max);
  final minY = points.map((p) => p.dy).reduce(math.min);
  final maxY = points.map((p) => p.dy).reduce(math.max);
  final scale = math.min(
    (size.width - 170) / (maxX - minX),
    (size.height - 70) / (maxY - minY),
  );
  final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
  return points
      .map((p) => (p - center) * scale + size.center(Offset.zero))
      .toList();
}

class YamanoteStampMap extends StatefulWidget {
  const YamanoteStampMap({
    required this.collected,
    required this.mode,
    required this.selected,
    required this.controller,
    this.chuoSobu = false,
    this.kind,
    this.fitWhole = false,
    super.key,
  });
  final Set<String> collected;
  final StationNameDisplayMode mode;
  final int selected;
  final TransformationController controller;
  final bool chuoSobu;
  final StampBookDiagramKind? kind;
  final bool fitWhole;
  @override
  State<YamanoteStampMap> createState() => _YamanoteStampMapState();
}

class _YamanoteStampMapState extends State<YamanoteStampMap> {
  Size? _lastCanvas;
  double? _lastViewport;
  @override
  Widget build(BuildContext context) {
    final colors = StampBookColors(context);
    final mode = widget.mode,
        collected = widget.collected,
        selected = widget.selected,
        controller = widget.controller;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final kind =
        widget.kind ??
        (widget.chuoSobu
            ? StampBookDiagramKind.chuoSobu
            : StampBookDiagramKind.yamanote);
    final stations = kind.stations;
    final bilingual =
        mode == StationNameDisplayMode.both ||
        mode == StationNameDisplayMode.japaneseEnglish;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: colors.paper,
        child: SizedBox(
          height: 520,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = kind.focusesStation
                  ? math.max(constraints.maxWidth, 2800.0 * math.max(1, scale))
                  : math.max(
                          constraints.maxWidth,
                          bilingual
                              ? 640.0
                              : mode == StationNameDisplayMode.english
                              ? 480.0
                              : 360.0,
                        ) *
                        math.max(1, scale / 1.3);
              final size = Size(
                width,
                kind.focusesStation
                    ? 1000.0 * math.max(1, scale)
                    : math.max(520.0, width * 1.42),
              );
              if (size != _lastCanvas ||
                  constraints.maxWidth != _lastViewport) {
                _lastCanvas = size;
                _lastViewport = constraints.maxWidth;
                final fit = kind.focusesStation && !widget.fitWhole
                    ? .85
                    : math.min(
                        constraints.maxWidth / size.width,
                        520 / size.height,
                      );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final point = kind.focusesStation && !widget.fitWhole
                        ? kind.project(size)[selected]
                        : null;
                    controller.value = Matrix4.identity()
                      ..translateByDouble(
                        point == null
                            ? (constraints.maxWidth - size.width * fit) / 2
                            : constraints.maxWidth * .35 - point.dx * fit,
                        point == null
                            ? (520 - size.height * fit) / 2
                            : 260 - point.dy * fit,
                        0,
                        1,
                      )
                      ..scaleByDouble(fit, fit, 1, 1);
                  }
                });
              }
              return Semantics(
                label: stations
                    .map(
                      (s) =>
                          '${stampStationName(s, mode)}: ${localized(context, collected.contains(s.id) ? '수집 완료' : '미수집', collected.contains(s.id) ? 'Collected' : 'Not collected')}',
                    )
                    .join(', '),
                child: TwoFingerDiagram(
                  controller: controller,
                  minimumScale: kind.minimumScale,
                  sceneSize: size,
                  child: CustomPaint(
                    size: size,
                    painter: YamanoteStampMapPainter(
                      collected: collected,
                      mode: mode,
                      selected: selected,
                      colors: colors,
                      textScaler: MediaQuery.textScalerOf(context),
                      textStyle:
                          Theme.of(context).textTheme.bodySmall ??
                          const TextStyle(),
                      kind: kind,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class YamanoteStampMapPainter extends CustomPainter {
  YamanoteStampMapPainter({
    required this.collected,
    required this.mode,
    required this.selected,
    required this.colors,
    required this.textScaler,
    required this.textStyle,
    this.chuoSobu = false,
    this.kind,
  });
  final Set<String> collected;
  final StationNameDisplayMode mode;
  final int selected;
  final StampBookColors colors;
  final TextScaler textScaler;
  final TextStyle textStyle;
  final bool chuoSobu;
  final StampBookDiagramKind? kind;
  StampBookDiagramKind get _profile =>
      kind ??
      (chuoSobu
          ? StampBookDiagramKind.chuoSobu
          : StampBookDiagramKind.yamanote);
  Color get routeColor => _profile.color;
  TextPainter _label(StampStation station) =>
      TextPainter(
        text: TextSpan(
          text: stampStationName(station, mode),
          style: textStyle.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(
        maxWidth:
            _profile == StampBookDiagramKind.midosuji ||
                _profile == StampBookDiagramKind.osakaLoop
            ? textScaler.scale(
                mode == StationNameDisplayMode.japaneseEnglish
                    ? 180
                    : mode == StationNameDisplayMode.english
                    ? 150
                    : 120,
              )
            : mode == StationNameDisplayMode.japaneseEnglish
            ? 180
            : 120,
      );
  @override
  void paint(Canvas canvas, Size size) {
    final profile = _profile;
    final points = profile.project(size);
    final stations = profile.stations;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (profile.closed) path.close();
    // A single route-colored stroke, without an outer casing.
    canvas.drawPath(
      path,
      Paint()
        ..color = routeColor
        ..strokeWidth = 3.0
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final labels = stations.map(_label).toList();
    final chuoLabels = profile.focusesStation
        ? layoutChuoSobuLabels(
            points,
            labels.map((tp) => tp.size).toList(),
            size,
          )
        : null;
    final occupied = <Rect>[];
    final nodeRects = points
        .map((p) => Rect.fromCircle(center: p, radius: 6))
        .toList();
    for (var i = 0; i < points.length; i++) {
      final p = points[i], station = stations[i];
      final acquired = collected.contains(station.id);
      final tp = labels[i];
      final left = profile == StampBookDiagramKind.midosuji
          ? i.isEven
          : p.dx < size.width / 2;
      Rect? chosen;
      final candidates = <Rect>[];
      if (chuoLabels != null) {
        chosen = chuoLabels[i];
      } else {
        for (final shift in [
          0.0,
          -14.0,
          14.0,
          -28.0,
          28.0,
          -42.0,
          42.0,
          -56.0,
          56.0,
        ]) {
          for (final side in [left, !left]) {
            candidates.add(
              Rect.fromLTWH(
                side ? p.dx - tp.width - 9 : p.dx + 9,
                p.dy - tp.height / 2 + shift,
                tp.width,
                tp.height,
              ),
            );
          }
        }
      }
      for (final r in candidates) {
        if (r.left < 3 ||
            r.right > size.width - 3 ||
            r.top < 3 ||
            r.bottom > size.height - 3) {
          continue;
        }
        if (occupied.any((o) => o.inflate(2).overlaps(r)) ||
            nodeRects.any((o) => o.overlaps(r))) {
          continue;
        }
        if (profile == StampBookDiagramKind.osakaLoop &&
            _loopTouchesLabel(points, r.inflate(2))) {
          continue;
        }
        chosen = r;
        break;
      }
      final rect =
          chosen ??
          Rect.fromLTWH(p.dx + 9, p.dy - tp.height / 2, tp.width, tp.height);
      occupied.add(rect);
      if (profile.closed && (rect.center.dy - p.dy).abs() > 8) {
        canvas.drawLine(
          p,
          Offset(
            rect.center.dx < p.dx ? rect.right : rect.left,
            rect.center.dy,
          ),
          Paint()
            ..color = colors.muted.withValues(alpha: .4)
            ..strokeWidth = .6,
        );
      }
      tp.paint(canvas, rect.topLeft);
      canvas.drawCircle(
        p,
        selected == i ? 6 : 4,
        Paint()..color = acquired ? colors.teal : colors.paper,
      );
      canvas.drawCircle(
        p,
        selected == i ? 6 : 4,
        Paint()
          ..color = selected == i ? colors.stamp : colors.ink
          ..strokeWidth = selected == i ? 2.3 : 1.2
          ..style = PaintingStyle.stroke,
      );
      if (acquired) {
        canvas.drawPath(
          Path()
            ..moveTo(p.dx - 2, p.dy)
            ..lineTo(p.dx - .4, p.dy + 1.5)
            ..lineTo(p.dx + 2.5, p.dy - 1.8),
          Paint()
            ..color = colors.onTeal
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
    for (final label in labels) {
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(YamanoteStampMapPainter oldDelegate) =>
      _profile != oldDelegate._profile ||
      collected != oldDelegate.collected ||
      mode != oldDelegate.mode ||
      selected != oldDelegate.selected ||
      colors.dark != oldDelegate.colors.dark ||
      textScaler != oldDelegate.textScaler ||
      textStyle != oldDelegate.textStyle;
}
