import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/main_page_header.dart';

/// The compact A refinement of the existing two-column tools hub.
class ToolsPage extends StatelessWidget {
  const ToolsPage({
    super.key,
    required this.onOpenPassComparison,
    required this.onOpenContactless,
    required this.onOpenCoinLocker,
    this.onOpenStationMaps,
  });

  final VoidCallback onOpenPassComparison;
  final VoidCallback onOpenContactless;
  final VoidCallback onOpenCoinLocker;
  final VoidCallback? onOpenStationMaps;

  @override
  Widget build(BuildContext context) => AppPage(
    padding: MainPageHeader.pagePadding,
    children: [
      MainPageHeader(title: strings(context).tools),
      LayoutBuilder(
        builder: (context, constraints) {
          final tiles = [
            _ToolTile(
              key: const ValueKey('tools-pass-comparison'),
              icon: Icons.local_activity_outlined,
              title: strings(context).comparePasses,
              description: strings(context).comparePassesHint,
              onTap: onOpenPassComparison,
            ),
            _ToolTile(
              key: const ValueKey('tools-contactless'),
              icon: Icons.contactless_outlined,
              title: strings(context).contactlessRoutes,
              description: strings(context).contactlessRoutesHint,
              onTap: onOpenContactless,
            ),
            _ToolTile(
              key: const ValueKey('tools-coin-locker'),
              icon: Icons.luggage_outlined,
              title: strings(context).findLockers,
              description: strings(context).findLockersHint,
              onTap: onOpenCoinLocker,
            ),
            if (onOpenStationMaps != null)
              _ToolTile(
                key: const ValueKey('tools-station-maps'),
                icon: Icons.map_outlined,
                title: localized(context, '역 구내도', 'Station maps'),
                description: localized(
                  context,
                  '운영사별 공식 구내도\n외부 안내 연결',
                  'Official station maps\nby operator',
                ),
                onTap: onOpenStationMaps!,
              ),
          ];
          final oneColumn =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(16) > 22.4;
          if (oneColumn) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  tiles[i],
                ],
              ],
            );
          }
          return Column(
            children: [
              for (var i = 0; i < tiles.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tiles[i]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: i + 1 < tiles.length
                            ? tiles[i + 1]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ],
  );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    hint: description.replaceAll('\n', ' '),
    onTap: onTap,
    excludeSemantics: true,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 176),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.softSurface(context),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      size: 27,
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
