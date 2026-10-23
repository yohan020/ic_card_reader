import 'package:flutter/material.dart';

/// Keep the calculation's limits visible next to its verdict.
class PassResultScopeNote extends StatelessWidget {
  const PassResultScopeNote({this.detail, super.key});

  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      '입력한 교통 이용 기준의 예상 비교입니다.'
      '${detail == null ? '' : '\n$detail'}',
      style: TextStyle(
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
