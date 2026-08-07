import 'package:flutter/material.dart';

import '../data/nfc_manager_card_reader.dart';
import '../domain/card_reader.dart';
import '../domain/card_scan_result.dart';

class CardReaderPage extends StatefulWidget {
  const CardReaderPage({super.key, this.reader});

  final CardReader? reader;

  @override
  State<CardReaderPage> createState() => _CardReaderPageState();
}

class _CardReaderPageState extends State<CardReaderPage> {
  late final CardReader _reader = widget.reader ?? NfcManagerCardReader();
  CardScanResult? _result;
  String? _message;
  bool _isScanning = false;

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _message = null;
    });
    try {
      final result = await _reader.scan();
      if (!mounted) return;
      setState(() => _result = result);
    } on CardScanException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = '예상하지 못한 오류가 발생했습니다. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _cancelScan() => _reader.cancel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IC 카드 리더 · 개발자 PoC')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '카드 데이터는 이 기기에서만 처리합니다',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '현재 화면은 Phase 1 검증용입니다. 카드 IDm은 저장하거나 표시하지 않으며, 원시 16바이트 이용내역만 확인합니다.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: const Icon(Icons.nfc),
              label: Text(_isScanning ? '카드를 기다리는 중…' : 'IC 카드 스캔'),
            ),
            if (_isScanning) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _cancelScan,
                child: const Text('스캔 취소'),
              ),
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('30초 후 자동으로 종료됩니다.'),
            ],
            if (_message != null) ...[
              const SizedBox(height: 20),
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_message!),
                ),
              ),
            ],
            if (_result case final result?) ...[
              const SizedBox(height: 28),
              Text(
                '원시 이용내역 ${result.blocks.length}개',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text('아래 값에는 카드 IDm이 포함되지 않습니다.'),
              const SizedBox(height: 12),
              for (final block in result.blocks)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${block.index + 1}')),
                    title: SelectableText(
                      block.hexadecimal,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    subtitle: const Text('16 bytes'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
