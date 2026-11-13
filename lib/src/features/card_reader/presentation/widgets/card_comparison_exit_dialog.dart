import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';

import '../../../../core/design/app_theme.dart';

/// B-style exit confirmation. Only the confirmed action ends the session.
class CardComparisonExitDialog extends StatelessWidget {
  const CardComparisonExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    return Dialog(
      key: const ValueKey('comparison-exit-dialog'),
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 320),
      backgroundColor: theme.cardTheme.color,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        key: const ValueKey('comparison-exit-content'),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    key: const ValueKey('comparison-exit-icon'),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.softSurface(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 24,
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    namesRoute: true,
                    header: true,
                    child: Text(
                      strings(context).exitComparisonQuestion,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              strings(context).exitComparisonHint,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.mutedText(context),
              ),
            ),
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextButton(
                      key: const ValueKey('comparison-exit-cancel'),
                      style: buttonStyle.copyWith(
                        foregroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.onSurface,
                        ),
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
                      key: const ValueKey('comparison-exit-confirm'),
                      style: buttonStyle.copyWith(
                        foregroundColor: const WidgetStatePropertyAll(
                          Colors.white,
                        ),
                        backgroundColor: const WidgetStatePropertyAll(
                          Color(0xFFB94C58),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(strings(context).exit),
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
