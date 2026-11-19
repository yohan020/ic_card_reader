import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/card_reader.dart';
import '../domain/card_scan_result.dart';

class NfcStatusView extends StatelessWidget {
  const NfcStatusView({
    required this.availability,
    required this.onOpenSettings,
    required this.onRefresh,
    this.showActions = true,
    super.key,
  });

  final CardReaderAvailability? availability;
  final VoidCallback onOpenSettings;
  final VoidCallback onRefresh;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final label = switch (availability) {
      null => strings(context).checkingNfc,
      CardReaderAvailability.enabled => strings(context).nfcOn,
      CardReaderAvailability.disabled => strings(context).turnNfcOn,
      CardReaderAvailability.unsupported => strings(context).nfcUnsupported,
      CardReaderAvailability.unknown => strings(context).nfcUnknown,
    };
    final color = switch (availability) {
      CardReaderAvailability.enabled =>
        AppColors.isDark(context) ? const Color(0xFF79D6B2) : AppColors.success,
      CardReaderAvailability.disabled =>
        AppColors.isDark(context) ? const Color(0xFFF3BF78) : AppColors.warning,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final icon = switch (availability) {
      null => Icons.hourglass_top_rounded,
      CardReaderAvailability.enabled => Icons.nfc_rounded,
      CardReaderAvailability.disabled => Icons.nfc_rounded,
      CardReaderAvailability.unsupported => Icons.mobile_off_rounded,
      CardReaderAvailability.unknown => Icons.help_outline_rounded,
    };
    return Column(
      children: [
        Align(
          child: Container(
            key: const ValueKey('nfc-status-badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showActions && availability == CardReaderAvailability.disabled)
          TextButton(
            onPressed: onOpenSettings,
            child: Text(strings(context).openNfcSettings),
          ),
        if (showActions && availability == CardReaderAvailability.unknown)
          TextButton(
            onPressed: onRefresh,
            child: Text(strings(context).checkAgain),
          ),
      ],
    );
  }
}

class ScanFailureView extends StatelessWidget {
  const ScanFailureView({
    required this.kind,
    required this.availability,
    required this.onRetry,
    required this.onHelp,
    required this.onOpenSettings,
    this.onClose,
    super.key,
  });

  final CardScanFailureKind kind;
  final CardReaderAvailability? availability;
  final VoidCallback onRetry;
  final VoidCallback onHelp;
  final VoidCallback onOpenSettings;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    if (kind == CardScanFailureKind.cancelled) return const SizedBox.shrink();
    final (title, description) = switch (kind) {
      CardScanFailureKind.nfcUnavailable => (
        strings(context).couldNotStartNfc,
        availability == CardReaderAvailability.unsupported
            ? strings(context).nfcUnsupportedHint
            : strings(context).nfcEnabledHint,
      ),
      CardScanFailureKind.unsupportedTag => (
        strings(context).checkCardSupport,
        strings(context).checkCardSupportHint,
      ),
      CardScanFailureKind.timedOut => (
        strings(context).scanTimedOut,
        strings(context).scanTimedOutHint,
      ),
      CardScanFailureKind.tagLost => (
        strings(context).cardConnectionLost,
        strings(context).cardConnectionLostHint,
      ),
      CardScanFailureKind.invalidResponse => (
        strings(context).couldNotReadCard,
        strings(context).couldNotReadCardHint,
      ),
      CardScanFailureKind.noHistory => (
        strings(context).noReadableHistory,
        strings(context).noReadableHistoryHint,
      ),
      _ => (strings(context).scanFailed, strings(context).scanFailedHint),
    };
    final unsupported = availability == CardReaderAvailability.unsupported;
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    final helpButton = OutlinedButton(
      key: const ValueKey('scan-failure-help'),
      style: buttonStyle.copyWith(
        foregroundColor: WidgetStatePropertyAll(AppColors.accent(context)),
        side: WidgetStatePropertyAll(
          BorderSide(color: AppColors.accent(context)),
        ),
      ),
      onPressed: onHelp,
      child: Text(strings(context).scanHelp),
    );
    final showSettings =
        kind == CardScanFailureKind.nfcUnavailable &&
        availability != CardReaderAvailability.enabled &&
        !unsupported;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              key: const ValueKey('scan-failure-icon'),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.softSurface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                kind == CardScanFailureKind.noHistory
                    ? Icons.info_outline_rounded
                    : Icons.contactless_outlined,
                color: AppColors.accent(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (onClose != null)
              IconButton(
                onPressed: onClose,
                tooltip: strings(context).dismissNotice,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        if (unsupported)
          helpButton
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: helpButton),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('scan-failure-primary'),
                    style: buttonStyle.copyWith(
                      backgroundColor: const WidgetStatePropertyAll(
                        AppColors.skyDark,
                      ),
                      foregroundColor: const WidgetStatePropertyAll(
                        Colors.white,
                      ),
                    ),
                    onPressed: showSettings ? onOpenSettings : onRetry,
                    child: Text(
                      showSettings
                          ? strings(context).openNfcSettings
                          : strings(context).scanAgain,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

enum ScanFailureAction { retry, help, settings }

Future<ScanFailureAction?> showScanFailure(
  BuildContext context, {
  required CardScanFailureKind kind,
  required CardReaderAvailability? availability,
}) async {
  ModalRoute<dynamic>? sheetRoute;
  final action = await showModalBottomSheet<ScanFailureAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .9,
    ),
    builder: (context) {
      sheetRoute = ModalRoute.of(context);
      return _SheetBody(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ScanFailureView(
          kind: kind,
          availability: availability,
          onRetry: () => Navigator.pop(context, ScanFailureAction.retry),
          onHelp: () => Navigator.pop(context, ScanFailureAction.help),
          onOpenSettings: () =>
              Navigator.pop(context, ScanFailureAction.settings),
          onClose: () => Navigator.pop(context),
        ),
      );
    },
  );
  // Do not open help or a retry underneath the outgoing sheet animation.
  await sheetRoute?.completed;
  return action;
}

Future<void> showScanHelp(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * .9,
  ),
  builder: (context) => _SheetBody(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings(context).howToScan,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: strings(context).closeHelp,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          strings(context).holdOneCard,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const _CardPlacementDiagram(),
        const SizedBox(height: 20),
        _HelpStep(
          number: '1',
          title: strings(context).prepareOneCard,
          text: strings(context).prepareOneCardHint,
        ),
        _HelpStep(
          number: '2',
          title: strings(context).tapScanHold,
          text: strings(context).tapScanHoldHint,
        ),
        _HelpStep(
          number: '3',
          title: strings(context).waitForScan,
          text: strings(context).waitForScanHint,
        ),
        AppSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings(context).supportedCards,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(strings(context).supportedCardsHint),
              const SizedBox(height: 12),
              Text(
                strings(context).deviceRequirements,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(strings(context).felicaRequired),
              const SizedBox(height: 10),
              Text(
                strings(context).pitapaLimit,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings(context).readOnlyPhysicalCard,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings(context).close),
        ),
      ],
    ),
  ),
);

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 24),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(padding: padding, child: child),
  );
}

class _CardPlacementDiagram extends StatelessWidget {
  const _CardPlacementDiagram();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.softSurface(context),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Semantics(
          label: strings(context).placementSemantics,
          image: true,
          child: SizedBox(
            height: 140,
            width: 260,
            child: CustomPaint(
              painter: _PlacementPainter(
                accent: AppColors.accent(context),
                surface: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings(context).nfcPlacementVaries,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _PlacementPainter extends CustomPainter {
  const _PlacementPainter({required this.accent, required this.surface});
  final Color accent;
  final Color surface;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 260, size.height / 140);
    final outline = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final phone = RRect.fromRectAndRadius(
      const Rect.fromLTWH(56, 4, 80, 132),
      const Radius.circular(14),
    );
    canvas.drawRRect(phone, Paint()..color = surface);
    canvas.drawRRect(phone, outline);
    canvas.drawCircle(const Offset(72, 20), 4, outline);
    canvas.drawCircle(const Offset(85, 20), 4, outline);
    canvas.drawLine(const Offset(84, 127), const Offset(108, 127), outline);
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(106, 55, 105, 66),
      const Radius.circular(10),
    );
    canvas.drawRRect(card, Paint()..color = accent);
    final white = Paint()
      ..color = surface
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(120, 100), const Offset(153, 100), white);
    canvas.drawLine(const Offset(120, 110), const Offset(177, 110), white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(120, 68, 17, 15),
        const Radius.circular(3),
      ),
      Paint()..color = surface,
    );
    for (final x in [158.0, 170.0, 182.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 15)
          ..quadraticBezierTo(x + 10, 29, x, 43),
        outline,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlacementPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.surface != surface;
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.title,
    required this.text,
  });
  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.softSurface(context),
          foregroundColor: AppColors.accent(context),
          child: Text(
            number,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
