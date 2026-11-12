import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_ui.dart';
import '../domain/card_diagnostics.dart';
import '../domain/card_reader.dart';
import '../domain/card_scan_result.dart';
import 'card_brand_picker_page.dart';

class CardDiagnosticsPage extends StatefulWidget {
  const CardDiagnosticsPage({required this.reader, super.key});
  final CardReader reader;

  @override
  State<CardDiagnosticsPage> createState() => _CardDiagnosticsPageState();
}

class _CardDiagnosticsPageState extends State<CardDiagnosticsPage> {
  String? _brand;
  bool _consent = false;
  bool _busy = false;
  bool _cancelled = false;
  String? _report;
  String? _message;
  DiagnosticBrandResult? _identification;

  @override
  void dispose() {
    _cancelled = true;
    if (_busy) unawaited(widget.reader.cancel().catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _chooseBrand() async {
    final brand = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CardBrandPickerPage()),
    );
    if (!mounted || brand == null) return;
    setState(() {
      _brand = brand;
      _consent = false;
      _report = null;
      _message = null;
      _identification = null;
    });
  }

  Future<void> _scan() async {
    if (!cardDiagnosticsEnabled || _busy || !_consent) return;
    final reader = widget.reader;
    if (reader is! DiagnosticCardReader) {
      setState(() => _message = '이 읽기 방식에서는 진단을 지원하지 않아요.');
      return;
    }
    final brand = _brand;
    setState(() {
      _busy = true;
      _cancelled = false;
      _report = null;
      _identification = null;
      _message = '카드 한 장을 기기 뒷면 NFC 위치에 대 주세요.';
    });
    try {
      final result = await (reader as DiagnosticCardReader).scanDiagnostics();
      if (!mounted || _cancelled) return;
      final text = result.formatForTerminal(brand);
      debugPrint(text);
      setState(() {
        _report = text;
        _identification = result.experimentalBrand;
        _message = '실험 결과를 개발 터미널에 출력했어요. 카드에 적힌 실제 브랜드와 비교해 주세요.';
      });
    } on CardScanException catch (error) {
      if (mounted && !_cancelled) {
        setState(
          () => _message = switch (error.kind) {
            CardScanFailureKind.unsupportedTag => 'NFC-F 메타데이터를 확인할 수 없는 카드예요.',
            CardScanFailureKind.nfcUnavailable => '기기의 NFC 설정을 확인해 주세요.',
            CardScanFailureKind.timedOut => '시간이 초과됐어요. 다시 시도해 주세요.',
            _ => '진단을 완료하지 못했어요. 카드를 다시 대 주세요.',
          },
        );
      }
    } catch (_) {
      if (mounted && !_cancelled) {
        setState(() => _message = '진단을 완료하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    _cancelled = true;
    await widget.reader.cancel();
    if (mounted) setState(() => _message = '진단을 취소했어요.');
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) {
        _cancelled = true;
        if (_busy) unawaited(widget.reader.cancel().catchError((Object _) {}));
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('카드 브랜드 진단 (개발용)')),
      body: !cardDiagnosticsEnabled
          ? const Center(child: Text('개발용 진단이 활성화되지 않았어요.'))
          : AppPage(
              children: [
                Text(
                  '카드 브랜드 판별 테스트',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  '브랜드를 선택하지 않아도 바로 스캔할 수 있어요. 실제 브랜드 입력은 결과 대조용 선택 사항이에요.',
                ),
                const SizedBox(height: 20),
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _chooseBrand,
                        icon: const Icon(Icons.credit_card_rounded),
                        label: Text(_brand ?? '실제 브랜드 입력 (선택 사항)'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '시스템 코드·PMm과 일부 서비스의 존재 여부를 확인해요. 서비스 내용은 읽지 않아요. IDm·카드 번호·잔액·이용내역은 출력하거나 서버로 전송하지 않아요. 개발 터미널의 로그는 별도로 남을 수 있어요.',
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _consent,
                        onChanged: _busy
                            ? null
                            : (value) =>
                                  setState(() => _consent = value ?? false),
                        title: const Text('메타데이터를 개발 터미널에 출력하는 데 동의해요.'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy || !_consent ? null : _scan,
                        child: Text(_busy ? '카드 확인 중…' : '카드 스캔 및 판별 테스트'),
                      ),
                      if (_busy) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                        TextButton(onPressed: _cancel, child: const Text('취소')),
                      ],
                    ],
                  ),
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_message!),
                  ),
                if (_identification case final identification?) ...[
                  AppSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_brand != null) ...[
                          Text('실제 브랜드 (직접 선택): $_brand'),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          '자동 판별 후보: ${identification.label}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(identification.explanation),
                        const SizedBox(height: 8),
                        const Text('개발용 후보 표시이며 일반 스캔의 지원 범위와 다를 수 있어요.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_report != null)
                  AppSurface(
                    child: SelectableText(
                      _report!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
    ),
  );
}
