import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'card_brand_catalog.dart';

/// Release/profile builds cannot enable this, even with the define supplied.
const cardDiagnosticsEnabled =
    kDebugMode && bool.fromEnvironment('ENABLE_CARD_DIAGNOSTICS');

/// Small diagnostic sample, not a full external rule table.
/// Public service identifiers and provenance: IC_CARD_BRAND_IDENTIFICATION_RESEARCH.md.
const diagnosticServiceCodes = <int>[
  0x1A48,
  0x1A88,
  0x9608,
  0x1E08,
  0x1E48,
  0x1E8B,
  0x1F48,
  0x1FC8,
  0x2008,
  0x1CC8,
  0x1D08,
  0x1808,
  0x18C8,
  0x2448,
  0x2488,
  // Public metadata corroborated in UNOWNED_IC_CARD_BRAND_RESEARCH.md.
  // No external implementation or filesystem dataset is imported.
  0x208B,
  0x20CB,
  0x9888,
  0x98CC,
];
const diagnosticServicesPerQuery = 5;

/// Normal scanning only. Keep the consented support-report allowlist unchanged.
/// Public provenance: SUGOCA_PITAPA_RECHECK_2026-10-26.md.
const normalScanBrandServiceCodes = <int>[
  ...diagnosticServiceCodes,
  0x21C8,
  0x2208,
];

enum DiagnosticQueryIssue {
  timedOut('timed_out'),
  platformError('platform_error'),
  invalidResponse('invalid_response'),
  systemNotSelected('system_not_selected'),
  systemQueryFailed('system_query_failed'),
  other('other');

  const DiagnosticQueryIssue(this.code);
  final String code;
}

/// A null value means unknown, never absent. Key versions are discarded.
class CardServiceProbeReport {
  CardServiceProbeReport({
    required this.status,
    this.issue,
    Map<int, bool?> presence = const {},
  }) : presence = Map.unmodifiable(presence);

  final String status;
  final DiagnosticQueryIssue? issue;
  final Map<int, bool?> presence;

  Map<String, Object?> toLogFields() => {
    'target_system_code': '0003',
    'status': status,
    'issue': issue?.code,
    'presence': {
      for (final code in diagnosticServiceCodes)
        code
            .toRadixString(16)
            .padLeft(4, '0')
            .toUpperCase(): switch (presence[code]) {
          true => 'present',
          false => 'absent',
          null => 'unknown',
        },
    },
  };
}

enum DiagnosticBrand {
  icoca('ICOCA'),
  toica('TOICA'),
  nimoca('nimoca'),
  pasmo('PASMO'),
  suicaFamily('Suica 계열'),
  hayakaken('하야카켄'),
  kitaca('키타카'),
  manaca('마나카'),
  sugoca('스고카'),
  ica('ICa (가나자와)');

  const DiagnosticBrand(this.label);
  final String label;
}

enum DiagnosticBrandReason {
  observedServicePattern,
  publicServicePattern,
  observedSystemCode,
  systemQueryFailed,
  systemNotSupported,
  incompleteProbe,
  conflictingServices,
  unmatchedPattern,
}

/// Experimental candidates, never proof of an issuer or product variant.
class DiagnosticBrandResult {
  const DiagnosticBrandResult({required this.reason, this.brand});

  final DiagnosticBrand? brand;
  final DiagnosticBrandReason reason;

  String get label => brand?.label ?? '확인 불가';

  String get explanation => switch (reason) {
    DiagnosticBrandReason.publicServicePattern =>
      '공개 자료의 서비스 조합과 일치해요. 우리 실물 카드로는 아직 검증하지 않았어요.',
    DiagnosticBrandReason.observedServicePattern =>
      brand == DiagnosticBrand.suicaFamily
          ? '실측한 서비스 조합과 일치해요. KURURU 등 지역연계형과 개별 상품은 구분하지 못해요.'
          : '실측한 서비스 조합과 일치해요. 다른 세대·파생 카드까지 검증된 결과는 아니에요.',
    DiagnosticBrandReason.observedSystemCode =>
      '실측한 ICa 시스템 코드와 일치해요. 모든 카드에 대한 고유성은 검증되지 않았어요.',
    DiagnosticBrandReason.systemQueryFailed => '시스템 정보를 정상적으로 확인하지 못했어요.',
    DiagnosticBrandReason.systemNotSupported => '현재 실험 규칙에서 다루지 않는 시스템이에요.',
    DiagnosticBrandReason.incompleteProbe => '서비스 정보가 불완전해요. 카드를 다시 대 주세요.',
    DiagnosticBrandReason.conflictingServices => '서로 다른 브랜드의 특징이 함께 발견됐어요.',
    DiagnosticBrandReason.unmatchedPattern => '현재 실측 조합과 일치하지 않아요. 추측하지 않아요.',
  };

  Map<String, Object?> toLogFields() => {
    'rule_version': 'service-pattern-v2',
    'status': brand == null ? 'unknown' : 'candidate',
    'brand': brand?.name,
    'label': label,
    'reason': reason.name,
  };
}

// User-supplied, sanitized physical/mobile observations dated 2026-10-24.
// Require each configured pattern; the two public pairs are labelled separately.
// No external classifier code or full dataset is imported.
const _observedBrandServices = <DiagnosticBrand, Set<int>>{
  DiagnosticBrand.icoca: {0x1A48, 0x1A88, 0x9608},
  DiagnosticBrand.toica: {0x1E08, 0x1E48, 0x1E8B},
  DiagnosticBrand.nimoca: {0x1F48, 0x1FC8, 0x2008},
  DiagnosticBrand.pasmo: {0x1CC8, 0x1D08},
  DiagnosticBrand.suicaFamily: {0x1808, 0x18C8},
  DiagnosticBrand.hayakaken: {0x2448, 0x2488},
  // Publicly corroborated pairs, not user-owned physical observations.
  DiagnosticBrand.kitaca: {0x208B, 0x20CB},
  DiagnosticBrand.manaca: {0x9888, 0x98CC},
};

DiagnosticBrandResult _identifyDiagnosticBrand(CardDiagnosticReport report) {
  if (report.systemCodeStatus != 'ok' || report.systemCodeIssue != null) {
    return const DiagnosticBrandResult(
      reason: DiagnosticBrandReason.systemQueryFailed,
    );
  }
  if (report.initialSystemCode == '80EF' &&
      report.systemCodes.length == 1 &&
      report.systemCodes.single == '80EF') {
    return const DiagnosticBrandResult(
      brand: DiagnosticBrand.ica,
      reason: DiagnosticBrandReason.observedSystemCode,
    );
  }
  if (report.initialSystemCode != '0003' ||
      !report.systemCodes.contains('0003')) {
    return const DiagnosticBrandResult(
      reason: DiagnosticBrandReason.systemNotSupported,
    );
  }
  return identifyObservedServiceBrand(report.serviceProbe);
}

/// Shared observed-pattern classifier. The caller must have selected system
/// 0003. Unknown/partial/conflicting evidence never identifies a brand.
DiagnosticBrandResult identifyObservedServiceBrand(
  CardServiceProbeReport? probe, {
  bool includeSugoca = false,
}) {
  final codes = includeSugoca
      ? normalScanBrandServiceCodes
      : diagnosticServiceCodes;
  if (probe == null ||
      probe.status != 'ok' ||
      probe.issue != null ||
      codes.any((code) => probe.presence[code] == null)) {
    return const DiagnosticBrandResult(
      reason: DiagnosticBrandReason.incompleteProbe,
    );
  }
  final patterns = <DiagnosticBrand, Set<int>>{
    ..._observedBrandServices,
    if (includeSugoca) DiagnosticBrand.sugoca: {0x21C8, 0x2208},
  };
  final candidates = patterns.entries
      .where((entry) => entry.value.any((code) => probe.presence[code] == true))
      .toList();
  if (candidates.length > 1) {
    return const DiagnosticBrandResult(
      reason: DiagnosticBrandReason.conflictingServices,
    );
  }
  if (candidates.length == 1) {
    final candidate = candidates.single;
    // 18C8 differs between physical Suica, mobile Suica and regional cards.
    final requiredCodes = candidate.key == DiagnosticBrand.suicaFamily
        ? const {0x1808}
        : candidate.value;
    if (requiredCodes.every((code) => probe.presence[code] == true)) {
      return DiagnosticBrandResult(
        brand: candidate.key,
        reason:
            candidate.key == DiagnosticBrand.kitaca ||
                candidate.key == DiagnosticBrand.manaca ||
                candidate.key == DiagnosticBrand.sugoca
            ? DiagnosticBrandReason.publicServicePattern
            : DiagnosticBrandReason.observedServicePattern,
      );
    }
  }
  return const DiagnosticBrandResult(
    reason: DiagnosticBrandReason.unmatchedPattern,
  );
}

/// Whitelist only. Never store a tag, IDm, history, balance or raw response here.
class CardDiagnosticReport {
  CardDiagnosticReport({
    required this.initialSystemCode,
    required this.pmm,
    required List<String> systemCodes,
    required this.systemCodeStatus,
    this.systemCodeIssue,
    this.serviceProbe,
  }) : systemCodes = List.unmodifiable(systemCodes);

  final String? initialSystemCode;
  final String? pmm;
  final List<String> systemCodes;
  final String systemCodeStatus;
  final DiagnosticQueryIssue? systemCodeIssue;
  final CardServiceProbeReport? serviceProbe;

  /// Diagnostic-screen only. Does not use PMm or the manually selected label.
  DiagnosticBrandResult get experimentalBrand => _identifyDiagnosticBrand(this);

  String formatForTerminal([String? manualBrand]) {
    if (!cardDiagnosticsEnabled) throw StateError('Diagnostics disabled');
    if (manualBrand != null && validateCardBrandLabel(manualBrand) != null) {
      throw ArgumentError('Invalid brand label');
    }
    final payload = {
      'schema': 3,
      'manual_brand': manualBrand?.trim(),
      'technology': 'NFC-F',
      'initial_system_code': initialSystemCode,
      'pmm': pmm,
      'system_code_status': systemCodeStatus,
      'system_code_issue': systemCodeIssue?.code,
      'system_codes': systemCodes,
      'service_probe': serviceProbe?.toLogFields(),
      'experimental_identification': experimentalBrand.toLogFields(),
    };
    return '[CARD_DIAGNOSTICS] ${jsonEncode(payload)}';
  }
}

/// Read-only metadata commands: 0C and 02. No writes, auth or block reads.
class CardDiagnosticProtocol {
  static List<int> requestSystemCodes(List<int> idm) {
    if (idm.length != 8) throw ArgumentError('Invalid NFC-F identifier length');
    return [10, 0x0C, ...idm];
  }

  static List<String>? parseSystemCodes(List<int> response, List<int> idm) {
    if (idm.length != 8 ||
        response.length < 11 ||
        response[0] != response.length ||
        response[1] != 0x0D) {
      return null;
    }
    for (var i = 0; i < 8; i++) {
      if (response[i + 2] != idm[i]) return null;
    }
    final count = response[10];
    if (count < 1 || response.length != 11 + count * 2) return null;
    return List.generate(
      count,
      (i) => hex(response.sublist(11 + i * 2, 13 + i * 2)),
    );
  }

  static List<int> requestServices(List<int> idm, List<int> codes) {
    if (idm.length != 8 ||
        codes.isEmpty ||
        codes.length > diagnosticServicesPerQuery ||
        codes.any((code) => !normalScanBrandServiceCodes.contains(code))) {
      throw ArgumentError('Invalid diagnostic service request');
    }
    return [
      11 + codes.length * 2,
      0x02,
      ...idm,
      codes.length,
      for (final code in codes) ...[code & 0xFF, code >> 8],
    ];
  }

  static Map<int, bool>? parseServicePresence(
    List<int> response,
    List<int> idm,
    List<int> codes,
  ) {
    if (idm.length != 8 ||
        codes.isEmpty ||
        codes.length > diagnosticServicesPerQuery ||
        codes.any((code) => !normalScanBrandServiceCodes.contains(code)) ||
        response.length != 11 + codes.length * 2 ||
        response[0] != response.length ||
        response[1] != 0x03 ||
        response[10] != codes.length) {
      return null;
    }
    for (var i = 0; i < 8; i++) {
      if (response[i + 2] != idm[i]) return null;
    }
    return {
      for (var i = 0; i < codes.length; i++)
        codes[i]:
            !(response[11 + i * 2] == 0xFF && response[12 + i * 2] == 0xFF),
    };
  }

  static String hex(List<int> bytes) => bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
}
