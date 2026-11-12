import 'package:flutter/material.dart';
import '../pass_strings.dart';

/// Keeps a removable journey header the same 28dp height as a single segment.
///
/// A default [IconButton] has a 48dp minimum size. In a multi-segment card
/// that silently enlarged the first header row, making its top inset differ
/// from the single-segment state.
class PassSegmentRemoveButton extends StatelessWidget {
  const PassSegmentRemoveButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('pass-segment-remove-button'),
    width: 28,
    height: 28,
    child: IconButton(
      onPressed: onPressed,
      tooltip: strings(context).passRemoveSegment,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.close_rounded, size: 22),
    ),
  );
}
