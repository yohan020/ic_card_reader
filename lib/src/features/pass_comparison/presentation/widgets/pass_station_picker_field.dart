import 'package:flutter/material.dart';

import '../../../../core/design/app_theme.dart';
import '../pass_strings.dart';

/// The fixed station-field layout used throughout transport-pass planning.
///
/// Do not replace this with [OutlinedButton]. Its internal padding and minimum
/// size change the vertical rhythm of the three text rows on Android.
class PassStationPickerField extends StatelessWidget {
  const PassStationPickerField({
    required this.label,
    required this.stationName,
    required this.onTap,
    this.operatorLabel,
    this.emptyLabel = '역 선택',
    this.semanticLabel,
    super.key,
  });

  final String label;
  final String? stationName;
  final String? operatorLabel;
  final String emptyLabel;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final selected = stationName != null;
    final radius = BorderRadius.circular(14);

    return Semantics(
      button: true,
      label: semanticLabel == null
          ? strings(context).passSearchStation(passText(context, label))
          : passText(context, semanticLabel!),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.fieldSurface(context),
              borderRadius: radius,
              border: Border.all(color: AppColors.outline(context)),
            ),
            child: SizedBox(
              height: selected ? 76 : 60,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        passText(context, label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stationName ?? passText(context, emptyLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.accent(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (selected && operatorLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          passText(context, operatorLabel!),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
