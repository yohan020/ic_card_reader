import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../pass_comparison/presentation/pass_name_scope.dart';
import '../domain/station_stamp_session.dart';
import '../domain/stamp_book_catalog.dart';
import 'stamp_book_style.dart';
import 'yamanote_stamp_art.dart';
import 'yamanote_stamp_map.dart';

/// The Japanese lettering is part of the seal; the separate caption follows
/// the user's station-name setting. It stays crisp independently of the art.
class StampBookSeal extends StatelessWidget {
  const StampBookSeal({required this.index, required this.collected, super.key})
    : _station = null;
  const StampBookSeal.station({
    required StampStation station,
    required this.collected,
    super.key,
  }) : index = -1,
       _station = station;
  final int index;
  final bool collected;
  final StampStation? _station;
  @override
  Widget build(BuildContext context) {
    final c = StampBookColors(context),
        station = _station ?? yamanoteStampStations[index];
    final sharedIndex = yamanoteStampStations.indexWhere(
      (s) => s.id == station.id,
    );
    final name = stampStationName(station, PassNameScope.of(context));
    final newArt = stampBookArtByStation[station.id];
    final motif = sharedIndex >= 0
        ? (
            ko: yamanoteStampMotifs[sharedIndex].ko,
            en: yamanoteStampMotifs[sharedIndex].en,
          )
        : (ko: newArt!.ko, en: newArt.en);
    final color = collected ? c.stamp : c.muted;
    return Semantics(
      label:
          '$name, ${station.japanese}, ${localized(context, motif.ko, motif.en)}, ${localized(context, collected ? '수집 완료' : '미수집', collected ? 'Collected' : 'Not collected')}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = constraints.maxWidth;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(
                                alpha: collected ? 1 : .5,
                              ),
                              width: collected ? 1.6 : 1,
                            ),
                            color: collected ? c.paper : Colors.transparent,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(side * .065),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(
                                  alpha: collected ? .55 : .25,
                                ),
                                width: .7,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: side * .18,
                        left: side * .19,
                        right: side * .19,
                        height: side * .4,
                        child: sharedIndex >= 0
                            ? YamanoteStampArt(
                                index: sharedIndex,
                                color: color.withValues(
                                  alpha: collected ? 1 : .5,
                                ),
                              )
                            : Image.asset(
                                'assets/images/stamp_book_simple/${newArt!.asset}.webp',
                                key: ValueKey(
                                  'stamp-generated-art-${station.id}',
                                ),
                                fit: BoxFit.contain,
                                color: color.withValues(
                                  alpha: collected ? 1 : .5,
                                ),
                                colorBlendMode: BlendMode.srcIn,
                                cacheWidth: 384,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, _, _) =>
                                    Icon(Icons.train_outlined, color: color),
                              ),
                      ),
                      Positioned(
                        left: side * .12,
                        right: side * .12,
                        top: side * .59,
                        bottom: side * .13,
                        child: Center(
                          child: Text(
                            station.japanese == '高輪ゲートウェイ'
                                ? '高輪\nゲートウェイ'
                                : station.japanese,
                            key: ValueKey('stamp-japanese-${station.id}'),
                            textAlign: TextAlign.center,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: color,
                              fontSize: station.japanese == '高輪ゲートウェイ'
                                  ? (side * .095).clamp(6.0, 16.0)
                                  : (side * .135).clamp(10.0, 22.0),
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      if (collected)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              color: c.stamp,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.background, width: 2),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: c.paper,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              key: ValueKey('stamp-caption-${station.id}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: c.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
