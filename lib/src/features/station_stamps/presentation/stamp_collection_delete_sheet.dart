import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';

Future<bool?> confirmClearStationStamps(
  BuildContext context,
) => showModalBottomSheet<bool>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            localized(
              context,
              '역 스탬프를 모두 삭제할까요?',
              'Delete all station stamps?',
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            localized(
              context,
              '수집한 역 스탬프만 삭제하며 복구할 수 없어요. 현재 스캔 내역과 다른 설정은 유지돼요.',
              'Only collected stamps will be deleted and cannot be restored. Your current scan and other settings stay unchanged.',
            ),
            style: const TextStyle(fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('stamps-confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(localized(context, '전체 삭제', 'Delete all')),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localized(context, '취소', 'Cancel')),
          ),
        ],
      ),
    ),
  ),
);
