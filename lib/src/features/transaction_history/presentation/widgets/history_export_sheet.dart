import 'package:flutter/material.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/localization/app_strings.dart';

enum HistoryExportScope { all, filtered }

Future<HistoryExportScope?> showHistoryExportSheet(
  BuildContext context, {
  required int allCount,
  required int filteredCount,
  required String filterLabel,
}) => showModalBottomSheet<HistoryExportScope>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    strings(context).exportCsv,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: strings(context).close,
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings(context).exportCsvNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          for (final scope in HistoryExportScope.values) ...[
            const Divider(height: 1),
            ListTile(
              key: ValueKey('export-scope-${scope.name}'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              minTileHeight: 56,
              enabled: scope == HistoryExportScope.all || filteredCount > 0,
              title: Text(
                scope == HistoryExportScope.all
                    ? '${strings(context).exportAll} ($allCount)'
                    : '${strings(context).exportFiltered} ($filteredCount)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: scope == HistoryExportScope.filtered
                  ? Text(filterLabel)
                  : null,
              trailing: const ExcludeSemantics(
                child: Icon(Icons.chevron_right_rounded),
              ),
              onTap: scope == HistoryExportScope.all || filteredCount > 0
                  ? () => Navigator.pop(context, scope)
                  : null,
            ),
          ],
        ],
      ),
    ),
  ),
);
