import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';

import '../../../../core/design/app_theme.dart';

/// Clears only the in-memory comparison list, never a physical card.
class CardComparisonClearDialog extends StatelessWidget {
  const CardComparisonClearDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final actionTextStyle = theme.textTheme.labelLarge!.copyWith(fontSize: 14);
    final buttonStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: actionTextStyle.copyWith(fontWeight: FontWeight.w600),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 300),
      backgroundColor: theme.cardTheme.color,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        key: const ValueKey('comparison-clear-content'),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ExcludeSemantics(
                      child: Container(
                        key: const ValueKey('comparison-clear-icon'),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.softSurface(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.filter_none_rounded,
                          color: AppColors.accent(context),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    namesRoute: true,
                    header: true,
                    child: Text(
                      strings(context).clearComparisonQuestion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings(context).clearComparisonHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: foreground,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings(context).balancesUnchanged,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mutedText(context),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextButton(
                      key: const ValueKey('comparison-clear-cancel'),
                      style: buttonStyle.copyWith(
                        foregroundColor: WidgetStatePropertyAll(foreground),
                        backgroundColor: WidgetStatePropertyAll(
                          AppColors.isDark(context)
                              ? AppColors.fieldSurface(context)
                              : AppColors.canvas,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(strings(context).cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('comparison-clear-confirm'),
                      style: buttonStyle.copyWith(
                        foregroundColor: const WidgetStatePropertyAll(
                          Colors.white,
                        ),
                        backgroundColor: const WidgetStatePropertyAll(
                          Color(0xFFB94C58),
                        ),
                        textStyle: WidgetStatePropertyAll(
                          actionTextStyle.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(strings(context).deleteAll),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
