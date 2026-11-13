import 'package:flutter/material.dart';
import '../pass_strings.dart';

/// Keep the calculation's limits visible next to its verdict.
class PassResultScopeNote extends StatelessWidget {
  const PassResultScopeNote({this.detail, super.key});

  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      '${strings(context).passEstimateNote}'
      '${detail == null ? '' : '\n${passText(context, detail!)}'}',
      style: TextStyle(
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
