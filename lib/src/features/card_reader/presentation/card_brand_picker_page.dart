import 'package:flutter/material.dart';

import '../domain/card_brand_catalog.dart';

/// Returns a manually declared brand; never infers it from a card scan.
class CardBrandPickerPage extends StatefulWidget {
  const CardBrandPickerPage({super.key});

  @override
  State<CardBrandPickerPage> createState() => _CardBrandPickerPageState();
}

class _CardBrandPickerPageState extends State<CardBrandPickerPage> {
  String _query = '';

  Future<void> _manualEntry() async {
    final route = DialogRoute<String>(
      context: context,
      builder: (_) => const _ManualBrandDialog(),
    );
    final value = await Navigator.of(context).push(route);
    if (value != null && mounted) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final matches = cardBrandCatalog
        .where((brand) => brand.matches(_query))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('카드 브랜드 선택')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '카드에 적힌 브랜드를 선택해 주세요.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '진단용 목록이며, 자동 식별·잔액·이용내역 지원 목록은 아니에요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: '브랜드 검색 (한국어·영문·일본어)',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _manualEntry,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('직접 입력'),
                ),
              ],
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? const Center(child: Text('검색 결과가 없어요. 직접 입력해 주세요.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final brand = matches[index];
                      final showHeader =
                          index == 0 || matches[index - 1].group != brand.group;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 8,
                              ),
                              child: Text(
                                brand.group,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ListTile(
                            key: ValueKey('brand-${brand.id}'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            title: Text(brand.name),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.pop(context, brand.name),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ManualBrandDialog extends StatefulWidget {
  const _ManualBrandDialog();
  @override
  State<_ManualBrandDialog> createState() => _ManualBrandDialogState();
}

class _ManualBrandDialogState extends State<_ManualBrandDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = validateCardBrandLabel(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('브랜드 직접 입력'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 40,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: '브랜드 이름',
        helperText: '카드 번호·이름 등 개인정보는 입력하지 마세요.',
        helperMaxLines: 3,
        errorText: _error,
        errorMaxLines: 3,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      TextButton(onPressed: _submit, child: const Text('선택')),
    ],
  );
}
