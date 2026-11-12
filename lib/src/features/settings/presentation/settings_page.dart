import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/main_page_header.dart';
import '../../app_update/domain/app_update_service.dart';
import '../../card_reader/domain/card_scan_result.dart';
import '../../card_reader/domain/card_diagnostics.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../../transaction_history/data/transit_history_parser.dart';
import '../domain/installed_app_version.dart';
import 'privacy_policy_page.dart';
import 'pass_data_sources_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onClearSession,
    required this.stationNameDisplayMode,
    required this.onStationNameDisplayModeChanged,
    super.key,
    this.appLanguage = AppLanguage.system,
    this.onAppLanguageChanged,
    this.result,
    this.appUpdateStatus = const AppUpdateStatus.unknown(),
    this.isCheckingForUpdate = false,
    this.onOpenCardDiagnostics,
    this.onOpenCardSupport,
  });

  final AppLanguage appLanguage;
  final ValueChanged<AppLanguage>? onAppLanguageChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onClearSession;
  final StationNameDisplayMode stationNameDisplayMode;
  final ValueChanged<StationNameDisplayMode> onStationNameDisplayModeChanged;
  final CardScanResult? result;
  final AppUpdateStatus appUpdateStatus;
  final bool isCheckingForUpdate;
  final VoidCallback? onOpenCardDiagnostics;
  final VoidCallback? onOpenCardSupport;

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: InstalledAppVersion.current,
    builder: (context, snapshot) => _buildPage(context, snapshot.data),
  );

  Widget _buildPage(BuildContext context, String? installedVersion) => AppPage(
    padding: MainPageHeader.pagePadding,
    children: [
      MainPageHeader(title: strings(context).settings),
      _SettingsSectionLabel(strings(context).displaySettings),
      AppSurface(
        key: const ValueKey('settings-language-group'),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings(context).theme,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _SettingsThemeSelector(
                    value: themeMode,
                    onChanged: onThemeModeChanged,
                  ),
                ],
              ),
            ),
            const _SettingsDivider(),
            if (onAppLanguageChanged case final onChanged?) ...[
              _SettingsChoice<AppLanguage>(
                title: strings(context).appLanguage,
                value: appLanguage,
                values: {
                  AppLanguage.system: strings(context).deviceLanguage,
                  AppLanguage.korean: '한국어',
                  AppLanguage.english: 'English',
                },
                onChanged: onChanged,
              ),
              const _SettingsDivider(),
            ],
            _SettingsChoice<StationNameDisplayMode>(
              title: strings(context).stationNames,
              description: strings(context).stationFallbackHint,
              value: stationNameDisplayMode,
              values: {
                StationNameDisplayMode.japanese: strings(context).japanese,
                StationNameDisplayMode.korean: strings(context).korean,
                StationNameDisplayMode.both:
                    '${strings(context).japanese} + ${strings(context).korean}',
                StationNameDisplayMode.english: strings(context).english,
                StationNameDisplayMode.japaneseEnglish:
                    '${strings(context).japanese} + ${strings(context).english}',
              },
              onChanged: onStationNameDisplayModeChanged,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _SettingsSectionLabel(strings(context).appInfo),
      AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: strings(context).appVersion,
              trailing: installedVersion ?? strings(context).unknown,
            ),
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.dataset_linked_outlined,
              title: strings(context).dataSources,
              subtitle: strings(context).dataSourcesHint,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PassDataSourcesPage(),
                ),
              ),
            ),
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.system_update_rounded,
              title: strings(context).appUpdate,
              subtitle: _updateSubtitle(
                strings(context),
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
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: strings(context).openSource,
              onTap: () => showLicensePage(
                context: context,
                applicationName: strings(context).appTitle,
                applicationVersion: installedVersion,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _SettingsSectionLabel(strings(context).privacyData),
      AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.policy_outlined,
              title: strings(context).privacyPolicy,
              subtitle: strings(context).privacyPolicyHint,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyPage(),
                ),
              ),
            ),
            const _SettingsDivider(),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: strings(context).clearCurrentHistory,
              subtitle: result == null
                  ? strings(context).nothingToClear
                  : strings(context).transactionCount(
                      const TransitHistoryParser().parse(result!.blocks).length,
                    ),
              iconColor: Theme.of(context).colorScheme.error,
              onTap: result == null ? null : () => _confirmClear(context),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      if (onOpenCardSupport != null) ...[
        _SettingsSectionLabel(strings(context).support),
        AppSurface(
          padding: EdgeInsets.zero,
          child: _SettingsTile(
            icon: Icons.contact_support_outlined,
            title: strings(context).cardSupport,
            subtitle: strings(context).cardSupportHint,
            onTap: onOpenCardSupport,
          ),
        ),
        const SizedBox(height: 18),
      ],
      if (cardDiagnosticsEnabled && onOpenCardDiagnostics != null) ...[
        _SettingsSectionLabel(strings(context).developerTools),
        AppSurface(
          padding: EdgeInsets.zero,
          child: _SettingsTile(
            icon: Icons.science_outlined,
            title: strings(context).cardDiagnostics,
            subtitle: strings(context).cardDiagnosticsHint,
            onTap: onOpenCardDiagnostics,
          ),
        ),
        const SizedBox(height: 18),
      ],
      Center(
        child: Text(
          strings(context).japanIcCards,
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

String _updateSubtitle(
  AppLocalizations l10n,
  AppUpdateStatus status, {
  required bool isChecking,
}) {
  if (isChecking) return l10n.checkingUpdates;
  return switch (status.availability) {
    AppUpdateAvailability.unknown => l10n.automaticUpdateCheck,
    AppUpdateAvailability.latest => l10n.appUpToDate,
    AppUpdateAvailability.updateAvailable => l10n.updateShownOnHome,
    AppUpdateAvailability.unavailable => l10n.updateStatusUnavailable,
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
              strings(context).clearHistoryQuestion,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              strings(context).clearHistoryHint,
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
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    color: AppColors.skyDark,
                    size: 21,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      strings(context).physicalCardUnchanged,
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
                label: Text(strings(context).clearHistory),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('cancel-clear-history'),
                onPressed: onCancel,
                child: Text(strings(context).cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsChoice<T> extends StatelessWidget {
  const _SettingsChoice({
    required this.title,
    this.description,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String title;
  final String? description;
  final T value;
  final Map<T, String> values;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: () => _choose(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Text(
                  values[value]!,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.mutedText(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _choose(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(17, 10, 17, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(sheet).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const SizedBox(width: 30, height: 4),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: Theme.of(sheet).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: strings(sheet).close,
                    onPressed: () => Navigator.pop(sheet),
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(48),
                      backgroundColor: Theme.of(
                        sheet,
                      ).colorScheme.surfaceContainerHigh,
                      foregroundColor: Theme.of(sheet).colorScheme.onSurface,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              if (description case final hint?) ...[
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: Theme.of(sheet).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText(sheet),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              for (final option in values.entries) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.outline(sheet),
                ),
                Material(
                  color: option.key == value
                      ? AppColors.softSurface(sheet)
                      : Colors.transparent,
                  child: ListTile(
                    key: ValueKey(option.key),
                    minTileHeight: 49,
                    minVerticalPadding: 8,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      option.value,
                      style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(
                        color: option.key == value
                            ? AppColors.accent(sheet)
                            : null,
                        fontWeight: option.key == value
                            ? FontWeight.w700
                            : null,
                      ),
                    ),
                    selected: option.key == value,
                    selectedColor: AppColors.accent(sheet),
                    trailing: option.key == value
                        ? const ExcludeSemantics(
                            child: Icon(Icons.check_rounded, size: 20),
                          )
                        : null,
                    onTap: () => Navigator.pop(sheet, option.key),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (context.mounted && selected != null && selected != value) {
      onChanged(selected);
    }
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    minTileHeight: 58,
    minLeadingWidth: 20,
    horizontalTitleGap: 12,
    leading: Icon(
      icon,
      color: iconColor ?? AppColors.accent(context),
      size: 20,
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    subtitle: subtitle == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.mutedText(context),
              ),
            ),
          ),
    trailing:
        trailingWidget ??
        (trailing != null
            ? Text(
                trailing!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText(context),
                ),
              )
            : onTap != null
            ? Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.mutedText(context),
              )
            : null),
    onTap: onTap,
  );
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: AppColors.mutedText(context),
      ),
    ),
  );
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, thickness: 1, color: AppColors.outline(context)),
  );
}

class _SettingsThemeSelector extends StatelessWidget {
  const _SettingsThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        ThemeMode.system,
        Icons.brightness_auto_rounded,
        strings(context).system,
      ),
      (ThemeMode.light, Icons.light_mode_outlined, strings(context).light),
      (ThemeMode.dark, Icons.dark_mode_outlined, strings(context).dark),
    ];
    return DecoratedBox(
      key: const ValueKey('theme-mode-selector'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < options.length; index++) ...[
                if (index > 0) const SizedBox(width: 4),
                Expanded(
                  child: Semantics(
                    selected: value == options[index].$1,
                    inMutuallyExclusiveGroup: true,
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        key: ValueKey(
                          'settings-theme-${options[index].$1.name}',
                        ),
                        borderRadius: BorderRadius.circular(9),
                        onTap: () {
                          if (value != options[index].$1) {
                            onChanged(options[index].$1);
                          }
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Ink(
                              key: ValueKey(
                                'settings-theme-fill-${options[index].$1.name}',
                              ),
                              decoration: BoxDecoration(
                                color: value == options[index].$1
                                    ? AppColors.softSurface(context)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Center(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Icon(
                                        options[index].$2,
                                        size: 17,
                                        color: value == options[index].$1
                                            ? AppColors.accent(context)
                                            : AppColors.mutedText(context),
                                      ),
                                      Text(
                                        options[index].$3,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: value == options[index].$1
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: value == options[index].$1
                                              ? AppColors.accent(context)
                                              : AppColors.mutedText(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
