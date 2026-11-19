part 'contactless_alias_data.g.dart';

class ContactlessAlias {
  const ContactlessAlias({
    required this.ko,
    required this.ja,
    required this.label,
    this.section,
  });
  final String ko;
  final String ja;
  final String label;
  final String? section;
}

List<ContactlessAlias> contactlessOperatorAliases(String id) =>
    _operatorAliases[id] ?? const [];
List<ContactlessAlias> contactlessLineAliases(String id) =>
    _lineAliases[id] ?? const [];

String withContactlessAliases(String base, List<ContactlessAlias> aliases) {
  final normalized = base.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final labels = <String>{};
  for (final alias in aliases) {
    final name = alias.ko.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (normalized.contains(name)) continue;
    labels.add(alias.section == null ? alias.label : '일부: ${alias.label}');
  }
  return labels.isEmpty ? base : '$base(${labels.join(' · ')})';
}
