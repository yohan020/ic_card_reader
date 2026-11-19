import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../domain/station_stamp_session.dart';
import '../domain/stamp_book_catalog.dart';
import 'stamp_book_style.dart';
import 'yamanote_stamp_art.dart';

/// Home ticket totals use the same released scope as the illustrated book.
class StampBookHomeCard extends StatelessWidget {
  const StampBookHomeCard({
    required this.session,
    required this.onTap,
    super.key,
  });
  final StationStampSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final c = StampBookColors(context);
      final count = session.ready
          ? stampBookCollectedCount(session)
          : session.previewCount;
      final total = stampBookStations.length;
      final title = localized(context, '역 스탬프', 'Station stamps');
      final action = localized(context, '스탬프 수첩 열기', 'Open stamp book');
      final state = count != null
          ? localized(
              context,
              '전체 $total개 중 $count개 역 수집',
              '$count of $total stations collected',
            )
          : localized(
              context,
              '수집 기록을 아직 확인할 수 없어요',
              'Collection is not available yet',
            );
      return Semantics(
        button: true,
        label: '$title. $state. $action',
        onTap: onTap,
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final large = MediaQuery.textScalerOf(context).scale(12) > 16;
              final stubWidth = constraints.maxWidth * (large ? .36 : .25);
              return Material(
                color: c.background,
                shape: _TicketShape(
                  side: BorderSide(color: c.ticketOutline),
                  split: 1 - stubWidth / constraints.maxWidth,
                ),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: _TicketInk(
                    stubColor: c.ticketStub,
                    lineColor: c.ticketOutline,
                    split: 1 - stubWidth / constraints.maxWidth,
                  ),
                  child: InkWell(
                    key: const ValueKey('home-stamp-book'),
                    onTap: onTap,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: c.ink,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    session.loadFailed
                                        ? localized(
                                            context,
                                            '수집 기록 확인 필요',
                                            'Check collection records',
                                          )
                                        : localized(
                                            context,
                                            '나의 철도 여행 수첩',
                                            'My railway travel journal',
                                          ),
                                    style: TextStyle(
                                      color: c.muted,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    key: const ValueKey(
                                      'home-stamp-ticket-action',
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.teal,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            action,
                                            style: TextStyle(
                                              color: c.onTeal,
                                              fontSize: 13,
                                              height: 1.3,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: c.onTeal,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            key: const ValueKey('home-stamp-ticket-stub'),
                            width: stubWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 11,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localized(context, '수집한 역', 'Collected'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: c.muted,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.end,
                                    spacing: 3,
                                    children: [
                                      Text(
                                        count?.toString() ?? '—',
                                        key: const ValueKey(
                                          'home-stamp-ticket-count',
                                        ),
                                        style: TextStyle(
                                          color: c.ink,
                                          fontSize: 32,
                                          height: 1.1,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 3,
                                        ),
                                        child: Text(
                                          '/ $total',
                                          key: const ValueKey(
                                            'home-stamp-ticket-total',
                                          ),
                                          style: TextStyle(
                                            color: c.ink,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _TicketSeal(colors: c),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _TicketSeal extends StatelessWidget {
  const _TicketSeal({required this.colors});
  final StampBookColors colors;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.17,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.paper,
        shape: BoxShape.circle,
        border: Border.all(color: colors.stamp),
      ),
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.stamp.withValues(alpha: .65),
            width: .6,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 29,
              height: 19,
              child: YamanoteStampArt(index: 0, color: colors.stamp),
            ),
            Text(
              '東京',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: colors.stamp,
                fontSize: 9,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TicketShape extends OutlinedBorder {
  const _TicketShape({required super.side, required this.split});
  final double split;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);
  @override
  _TicketShape copyWith({BorderSide? side}) =>
      _TicketShape(side: side ?? this.side, split: split);
  @override
  ShapeBorder scale(double t) =>
      _TicketShape(side: side.scale(t), split: split);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)));
    final cuts = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(rect.left + rect.width * split, rect.top),
          radius: 7,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(rect.left + rect.width * split, rect.bottom),
          radius: 7,
        ),
      );
    return Path.combine(PathOperation.difference, path, cuts);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      getOuterPath(rect.deflate(side.width / 2), textDirection: textDirection),
      side.toPaint(),
    );
  }
}

class _TicketInk extends Decoration {
  const _TicketInk({
    required this.stubColor,
    required this.lineColor,
    required this.split,
  });
  final Color stubColor, lineColor;
  final double split;
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _TicketInkPainter(this);
}

class _TicketInkPainter extends BoxPainter {
  _TicketInkPainter(this.decoration);
  final _TicketInk decoration;
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final x = offset.dx + size.width * decoration.split;
    canvas.drawRect(
      Rect.fromLTWH(
        x,
        offset.dy,
        size.width * (1 - decoration.split),
        size.height,
      ),
      Paint()..color = decoration.stubColor,
    );
    final pen = Paint()
      ..color = decoration.lineColor
      ..strokeWidth = 1;
    for (double y = 10; y < size.height - 10; y += 6) {
      canvas.drawLine(
        Offset(x, offset.dy + y),
        Offset(x, offset.dy + y + 3),
        pen,
      );
    }
  }
}
