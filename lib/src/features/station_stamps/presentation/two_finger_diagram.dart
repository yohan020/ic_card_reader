import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A two-touch-only viewport. Single-touch gestures stay in the surrounding
/// Scrollable's arena; after a two-touch gesture loses a finger we hand its
/// remaining vertical movement to that same scroll position without a jump.
class TwoFingerDiagram extends StatefulWidget {
  const TwoFingerDiagram({
    required this.controller,
    required this.sceneSize,
    required this.child,
    this.minimumScale = .2,
    super.key,
  });
  final TransformationController controller;
  final Size sceneSize;
  final Widget child;
  final double minimumScale;
  @override
  State<TwoFingerDiagram> createState() => _TwoFingerDiagramState();
}

class _TwoFingerDiagramState extends State<TwoFingerDiagram> {
  Offset _anchor = Offset.zero;
  double _startScale = 1, _startSpan = 1;
  Drag? _scrollDrag;
  Offset _handoffPoint = Offset.zero;
  void _cancelScroll() {
    _scrollDrag?.cancel();
    _scrollDrag = null;
  }

  void _start(List<Offset> p) {
    _cancelScroll();
    final center = (p[0] + p[1]) / 2;
    _anchor = widget.controller.toScene(center);
    // This is a planar, uniform transform. The unchanged z scale is 1 and
    // getMaxScaleOnAxis would incorrectly report 1 for every zoom below 1.
    _startScale = widget.controller.value.entry(0, 0).abs();
    _startSpan = math.max(1, (p[0] - p[1]).distance);
  }

  void _update(List<Offset> p) {
    final center = (p[0] + p[1]) / 2;
    final scale = (_startScale * (p[0] - p[1]).distance / _startSpan).clamp(
      widget.minimumScale,
      3.0,
    );
    final view = context.size!;
    final dx = (center.dx - _anchor.dx * scale).clamp(
      math.min(-80.0, view.width - widget.sceneSize.width * scale - 80),
      80.0,
    );
    final dy = (center.dy - _anchor.dy * scale).clamp(
      math.min(-80.0, view.height - widget.sceneSize.height * scale - 80),
      80.0,
    );
    widget.controller.value = Matrix4.identity()
      ..translateByDouble(dx.toDouble(), dy.toDouble(), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _handoffStart(Offset point) {
    _cancelScroll();
    _handoffPoint = point;
    final box = context.findRenderObject() as RenderBox;
    _scrollDrag = Scrollable.maybeOf(context)?.position.drag(
      DragStartDetails(
        localPosition: point,
        globalPosition: box.localToGlobal(point),
      ),
      () => _scrollDrag = null,
    );
  }

  void _handoffMove(Offset delta) {
    _handoffPoint += delta;
    final box = context.findRenderObject() as RenderBox;
    _scrollDrag?.update(
      DragUpdateDetails(
        globalPosition: box.localToGlobal(_handoffPoint),
        localPosition: _handoffPoint,
        delta: Offset(0, delta.dy),
        primaryDelta: delta.dy,
      ),
    );
  }

  @override
  void dispose() {
    _cancelScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    key: const ValueKey('stamp-book-diagram-gestures'),
    behavior: HitTestBehavior.opaque,
    gestures: {
      _TwoTouchRecognizer:
          GestureRecognizerFactoryWithHandlers<_TwoTouchRecognizer>(
            () => _TwoTouchRecognizer(),
            (r) => r
              ..onStart = _start
              ..onUpdate = _update
              ..onHandoffStart = _handoffStart
              ..onHandoffMove = _handoffMove
              ..onEnd = _cancelScroll,
          ),
    },
    child: ClipRect(
      child: AnimatedBuilder(
        animation: widget.controller,
        child: SizedBox.fromSize(size: widget.sceneSize, child: widget.child),
        builder: (context, child) => OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Transform(
            alignment: Alignment.topLeft,
            transform: widget.controller.value,
            child: child,
          ),
        ),
      ),
    ),
  );
}

class _TwoTouchRecognizer extends OneSequenceGestureRecognizer {
  final _points = <int, Offset>{};
  Offset? _oneStart;
  bool _accepted = false, _two = false;
  ValueChanged<List<Offset>>? onStart, onUpdate;
  ValueChanged<Offset>? onHandoffStart, onHandoffMove;
  VoidCallback? onEnd;
  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    _points[event.pointer] = event.localPosition;
    if (_points.length == 1) {
      _oneStart = event.localPosition;
    }
    if (_points.length == 2) {
      resolve(GestureDisposition.accepted);
      _two = true;
      onStart?.call(_points.values.toList());
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_points.containsKey(event.pointer)) return;
    if (event is PointerMoveEvent) {
      final before = _points[event.pointer]!;
      _points[event.pointer] = event.localPosition;
      if (_accepted && _points.length == 2 && _two) {
        onUpdate?.call(_points.values.toList());
      } else if (_accepted && _points.length == 1) {
        onHandoffMove?.call(event.localPosition - before);
      } else if (!_accepted &&
          _points.length == 1 &&
          (event.localPosition - _oneStart!).distance > kTouchSlop) {
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _points.remove(event.pointer);
      stopTrackingPointer(event.pointer);
      if (_accepted && _points.length == 2) {
        _two = true;
        onStart?.call(_points.values.toList());
      }
      if (_accepted && _points.length == 1 && _two) {
        _two = false;
        onHandoffStart?.call(_points.values.first);
      }
      if (_points.isEmpty) {
        onEnd?.call();
        _accepted = false;
        _two = false;
        _oneStart = null;
      }
    }
  }

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
  }

  @override
  void rejectGesture(int pointer) {
    _points.remove(pointer);
    stopTrackingPointer(pointer);
    if (_points.isEmpty) {
      onEnd?.call();
      _accepted = false;
      _two = false;
      _oneStart = null;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    resolve(GestureDisposition.rejected);
  }

  @override
  String get debugDescription => 'two-touch diagram';
}
