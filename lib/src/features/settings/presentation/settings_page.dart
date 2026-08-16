import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../app_update/domain/app_update_service.dart';
import '../../card_reader/domain/card_scan_result.dart';
import '../../station_resolver/domain/station_name_display.dart';
import 'privacy_policy_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onClearSession,
    required this.stationNameDisplayMode,
    required this.onStationNameDisplayModeChanged,
    super.key,
    this.result,
    this.appUpdateStatus = const AppUpdateStatus.unknown(),
    this.isCheckingForUpdate = false,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onClearSession;
  final StationNameDisplayMode stationNameDisplayMode;
  final ValueChanged<StationNameDisplayMode> onStationNameDisplayModeChanged;
  final CardScanResult? result;
  final AppUpdateStatus appUpdateStatus;
  final bool isCheckingForUpdate;

  @override
  Widget build(BuildContext context) => AppPage(
    children: [
      Text('설정', style: Theme.of(context).appBarTheme.titleTextStyle),
      const SizedBox(height: 22),
      const SectionLabel('화면'),
      AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('테마', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              key: const ValueKey('station-name-display-selector'),
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('시스템'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('라이트'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('다크'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) =>
                    onThemeModeChanged(selection.first),
                showSelectedIcon: false,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('역명 표기', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              '한국어 표기가 확인된 역에만 적용됩니다.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<StationNameDisplayMode>(
                segments: const [
                  ButtonSegment(
                    value: StationNameDisplayMode.japanese,
                    icon: Icon(Icons.translate_rounded),
                    label: Text('일본어'),
                  ),
                  ButtonSegment(
                    value: StationNameDisplayMode.korean,
                    icon: Icon(Icons.language_rounded),
                    label: Text('한국어'),
                  ),
                  ButtonSegment(
                    value: StationNameDisplayMode.both,
                    label: Text('함께 표시'),
                  ),
                ],
                selected: {stationNameDisplayMode},
                onSelectionChanged: (selection) =>
                    onStationNameDisplayModeChanged(selection.first),
                showSelectedIcon: false,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const SectionLabel('앱 정보'),
      AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: '앱 버전',
              trailing: '1.0.0',
            ),
            const Divider(),
            _SettingsTile(
              icon: Icons.system_update_rounded,
              title: '앱 업데이트',
              subtitle: _updateSubtitle(
                appUpdateStatus,
                isChecking: isCheckingForUpdate,
              ),
              trailingWidget: isCheckingForUpdate
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            const Divider(),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: '오픈소스 라이선스',
              onTap: () => showLicensePage(
                context: context,
                applicationName: '일본 교통카드 리더',
                applicationVersion: '1.0.0',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const SectionLabel('개인정보 및 데이터'),
      AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.policy_outlined,
              title: '개인정보처리방침',
              subtitle: 'NFC와 오류 제보 데이터 처리 안내',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyPage(),
                ),
              ),
            ),
            const Divider(),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: '현재 이용내역 지우기',
              subtitle: result == null
                  ? '지울 세션 데이터가 없습니다.'
                  : '${result!.blocks.length}개의 읽기 결과가 있습니다.',
              iconColor: Theme.of(context).colorScheme.error,
              onTap: result == null ? null : () => _confirmClear(context),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Text(
          '일본 전국호환 교통계 IC 카드',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ClearHistoryDialog(
        onCancel: () => Navigator.pop(dialogContext, false),
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (confirmed == true) onClearSession();
  }
}

String _updateSubtitle(AppUpdateStatus status, {required bool isChecking}) {
  if (isChecking) return '업데이트 정보를 확인하고 있습니다.';
  return switch (status.availability) {
    AppUpdateAvailability.unknown => '앱을 열면 자동으로 업데이트를 확인합니다.',
    AppUpdateAvailability.latest => '현재 최신 버전을 사용 중입니다.',
    AppUpdateAvailability.updateAvailable => '새 버전이 홈 화면에 안내됩니다.',
    AppUpdateAvailability.unavailable => '지금은 업데이트 정보를 확인할 수 없습니다.',
  };
}

class _ClearHistoryDialog extends StatelessWidget {
  const _ClearHistoryDialog({required this.onCancel, required this.onConfirm});

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      key: const ValueKey('clear-history-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 34,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '현재 이용내역을 지울까요?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              '이번에 읽은 이용내역과 원본 기록이\n앱 화면에서 삭제됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.skySoft.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? .14
                      : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.skyDark.withValues(alpha: .22),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    color: AppColors.skyDark,
                    size: 21,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      '실물 카드 안의 데이터는 변경되지 않습니다.',
                      style: TextStyle(
                        color: AppColors.skyDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('confirm-clear-history'),
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('이용내역 지우기'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('cancel-clear-history'),
                onPressed: onCancel,
                child: const Text('취소'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingWidget,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 3),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (iconColor ?? AppColors.skyDark).withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor ?? AppColors.skyDark, size: 21),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing:
        trailingWidget ??
        (trailing != null
            ? Text(
                trailing!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : onTap != null
            ? const Icon(Icons.chevron_right_rounded)
            : null),
    onTap: onTap,
  );
}
