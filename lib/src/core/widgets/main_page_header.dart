import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

import '../design/app_theme.dart';

/// The approved A minimal header shared by the four main tabs.
class MainPageHeader extends StatelessWidget {
  const MainPageHeader({required this.title, super.key, this.onScan});

  static const pagePadding = EdgeInsets.fromLTRB(20, 12, 20, 28);

  final String title;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          if (onScan != null) ...[
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 48,
              child: IconButton(
                onPressed: onScan,
                tooltip: strings(context).scanCard,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.accent(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.nfc_rounded, size: 23),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
