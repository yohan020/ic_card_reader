import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../card_reader/domain/card_scan_result.dart';
import 'privacy_policy_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onClearSession,
    super.key,
    this.result,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onClearSession;
  final CardScanResult? result;

  @override
  Widget build(BuildContext context) => AppPage(
    children: [
      Text('설정', style: Theme.of(context).appBarTheme.titleTextStyle),
      const SizedBox(height: 22),
      const SectionLabel('개인정보 및 데이터'),
      AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const _SettingsTile(
              icon: Icons.shield_outlined,
              title: '기본 처리는 기기 안에서',
              subtitle: '오류 제보는 동의한 이용내역 1건만 전송합니다.',
            ),
            const Divider(),
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
      const SizedBox(height: 24),
      const SectionLabel('화면'),
      AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('테마', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
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
              icon: Icons.description_outlined,
              title: '오픈소스 라이선스',
              onTap: () => showLicensePage(
                context: context,
                applicationName: '일본 교통카드 리더',
                applicationVersion: '1.0.0',
              ),
            ),
            const Divider(),
            _SettingsTile(
              icon: Icons.developer_mode_rounded,
              title: '개발자 정보',
              subtitle: '원본 16바이트 블록 확인',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DeveloperPage(result: result),
                ),
              ),
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
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('현재 이용내역을 지울까요?'),
        content: const Text('이번 실행 중 읽은 이용내역과 원본 블록을 화면에서 제거합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (confirmed == true) onClearSession();
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
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
    trailing: trailing != null
        ? Text(
            trailing!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        : onTap != null
        ? const Icon(Icons.chevron_right_rounded)
        : null,
    onTap: onTap,
  );
}

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({required this.result, super.key});

  final CardScanResult? result;

  @override
  Widget build(BuildContext context) {
    final joined =
        result?.blocks
            .map(
              (block) => 'IC_CARD_BLOCK[${block.index}]=${block.hexadecimal}',
            )
            .join('\n') ??
        '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('개발자 정보'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: StatusPill(label: 'DEV', icon: Icons.code_rounded),
            ),
          ),
        ],
      ),
      body: AppPage(
        children: [
          const NoticeBanner(
            title: '민감 정보 제외',
            text: '이 화면에는 카드 IDm이 포함되지 않습니다. 원본 이용내역 블록은 디버깅 용도로만 확인하세요.',
            tone: NoticeTone.warning,
          ),
          const SizedBox(height: 18),
          AppSurface(
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: '읽은 블록',
                    value: '${result?.blocks.length ?? 0}개',
                  ),
                ),
                const SizedBox(height: 42, child: VerticalDivider()),
                Expanded(
                  child: _Metric(
                    label: '스캔 시각',
                    value: result == null
                        ? '-'
                        : formatDateTime(result!.scannedAt),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionLabel(
            '원본 블록',
            trailing: TextButton.icon(
              onPressed: result == null
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: joined));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('원본 블록을 복사했습니다.')),
                        );
                      }
                    },
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('모두 복사'),
            ),
          ),
          if (result == null)
            const AppSurface(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 26),
                child: Center(child: Text('먼저 IC 카드를 스캔해 주세요.')),
              ),
            )
          else
            for (final block in result!.blocks) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(label: '#${block.index + 1}'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              block.hexadecimal,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '16 bytes',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '복사',
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: block.hexadecimal),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 19),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ],
  );
}
