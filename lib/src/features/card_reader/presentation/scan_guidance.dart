import 'package:flutter/material.dart';

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
      null => 'NFC 상태 확인 중',
      CardReaderAvailability.enabled => 'NFC가 켜져 있어요',
      CardReaderAvailability.disabled => 'NFC를 켜 주세요',
      CardReaderAvailability.unsupported => '이 기기는 NFC 읽기를 지원하지 않아요',
      CardReaderAvailability.unknown => 'NFC 상태를 확인하지 못했어요',
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
          TextButton(onPressed: onOpenSettings, child: const Text('NFC 설정 열기')),
        if (showActions && availability == CardReaderAvailability.unknown)
          TextButton(onPressed: onRefresh, child: const Text('다시 확인')),
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
        'NFC 읽기를 시작하지 못했어요',
        availability == CardReaderAvailability.unsupported
            ? '이 기기는 NFC 읽기를 지원하지 않습니다. NFC-F/FeliCa 읽기를 지원하는 Android 기기를 이용해 주세요.'
            : 'NFC가 켜져 있는지 확인해 주세요. Samsung 기기는 NFC를 기본 모드로 설정한 뒤 다시 시도해 주세요.',
      ),
      CardScanFailureKind.unsupportedTag => (
        '지원하는 교통카드인지 확인해 주세요',
        'Suica·PASMO·ICOCA 등 일본 전국호환 교통계 IC 카드를 한 장만 대 주세요. NFC-F/FeliCa 읽기를 지원하는 기기가 필요합니다.',
      ),
      CardScanFailureKind.timedOut => (
        '시간 안에 스캔을 완료하지 못했어요',
        '카드를 지갑에서 꺼내 휴대폰 뒷면의 위치를 조금씩 바꿔 다시 시도해 주세요. 카드 종류나 기기의 NFC-F 지원 여부도 영향을 줄 수 있습니다.',
      ),
      CardScanFailureKind.tagLost => (
        '카드와 통신을 완료하지 못했어요',
        '카드 한 장을 NFC 위치에 가까이 대고 완료될 때까지 움직이지 말아 주세요.',
      ),
      CardScanFailureKind.invalidResponse => (
        '카드 정보를 읽지 못했어요',
        '카드를 다시 대 주세요. 이 메시지만으로 카드 고장이나 잔액 이상을 의미하지는 않습니다.',
      ),
      CardScanFailureKind.noHistory => (
        '읽을 수 있는 이용내역이 없어요',
        '카드에서 표시할 이용내역을 찾지 못했습니다. 카드 종류나 기록 상태에 따라 읽을 수 있는 정보가 다를 수 있습니다.',
      ),
      _ => (
        '스캔을 완료하지 못했어요',
        '카드를 잠시 떼었다가 다시 시도해 주세요. 계속되면 NFC 설정과 지원 카드 안내를 확인해 주세요.',
      ),
    };
    final unsupported = availability == CardReaderAvailability.unsupported;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.softSurface(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                kind == CardScanFailureKind.noHistory
                    ? Icons.info_outline_rounded
                    : Icons.contactless_outlined,
                color: AppColors.accent(context),
              ),
            ),
            const Spacer(),
            if (onClose != null)
              IconButton(
                onPressed: onClose,
                tooltip: '안내 닫기',
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (kind == CardScanFailureKind.nfcUnavailable &&
            availability != CardReaderAvailability.enabled &&
            !unsupported)
          FilledButton(
            onPressed: onOpenSettings,
            child: const Text('NFC 설정 열기'),
          )
        else if (!unsupported)
          FilledButton(onPressed: onRetry, child: const Text('다시 스캔')),
        const SizedBox(height: 6),
        TextButton(onPressed: onHelp, child: const Text('스캔 도움말')),
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
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .9,
    ),
    builder: (context) {
      sheetRoute = ModalRoute.of(context);
      return _SheetBody(
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
                '카드 스캔 방법',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: '도움말 닫기',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '휴대폰 뒷면에 교통카드 한 장을 대 주세요.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const _CardPlacementDiagram(),
        const SizedBox(height: 20),
        const _HelpStep(
          number: '1',
          title: '카드 한 장 준비',
          text: '지갑에서 실물 교통카드 한 장을 꺼내 주세요. Samsung 기기는 NFC 기본 모드를 확인해 주세요.',
        ),
        const _HelpStep(
          number: '2',
          title: '스캔을 누르고 뒷면에 대기',
          text: '스캔 화면이 열리면 카드를 휴대폰 뒷면 NFC 위치에 대 주세요. NFC 위치는 기기마다 다릅니다.',
        ),
        const _HelpStep(
          number: '3',
          title: '완료될 때까지 고정',
          text: '반응이 없으면 카드 위치를 조금씩 바꾸거나 두꺼운 케이스·금속 부착물을 분리한 뒤 다시 시도해 주세요.',
        ),
        AppSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '지원 카드',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('Suica · PASMO · ICOCA 등 일본 전국호환 교통계 IC 카드'),
              const SizedBox(height: 12),
              const Text(
                '기기 조건',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'NFC-F/FeliCa 읽기 지원이 필요합니다. NFC 켜짐 표시만으로 지원이 확인되는 것은 아닙니다.',
              ),
              const SizedBox(height: 10),
              Text(
                'PiTaPa 포스트페이 및 일부 거래는 지원되지 않을 수 있습니다.',
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
          '실물 카드 스캔 기준입니다. 카드 충전이나 기록 변경은 하지 않습니다.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    ),
  ),
);

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: child,
    ),
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
          label: '휴대폰 뒷면에 실물 교통카드 한 장을 가까이 대는 예시',
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
          'NFC 위치는 기기마다 달라요',
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
