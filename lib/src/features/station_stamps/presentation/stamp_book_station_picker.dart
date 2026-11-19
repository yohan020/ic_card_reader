import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../domain/station_stamp_session.dart';
import 'stamp_book_style.dart';

/// Station selection scoped to the illustrated book; no collection mutation.
class StampBookStationPicker extends StatelessWidget {
  const StampBookStationPicker({
    required this.names,
    required this.line,
    required this.session,
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final List<String> names;
  final StampLine line;
  final StationStampSession session;
  final int selected;
  final ValueChanged<int> onSelected;

  Future<void> _choose(BuildContext context) async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: StampBookColors(context).paper,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheet) => FractionallySizedBox(
        heightFactor: .75,
        child: _StationSheet(
          names: names,
          line: line,
          session: session,
          selected: selected,
        ),
      ),
    );
    if (context.mounted && choice != null) onSelected(choice);
  }

  @override
  Widget build(BuildContext context) {
    final c = StampBookColors(context);
    return Material(
      color: c.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('stamp-book-station-picker'),
        onTap: () => _choose(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  session.collected.contains(line.stations[selected].id)
                      ? Icons.check_circle_outline_rounded
                      : Icons.circle_outlined,
                  color: c.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localized(context, '역 선택', 'Select station'),
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      names[selected],
                      style: TextStyle(
                        color: c.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: Icon(Icons.expand_more_rounded, color: c.teal, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationSheet extends StatefulWidget {
  const _StationSheet({
    required this.names,
    required this.line,
    required this.session,
    required this.selected,
  });
  final List<String> names;
  final StampLine line;
  final StationStampSession session;
  final int selected;
  @override
  State<_StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends State<_StationSheet> {
  final _selectedKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _selectedKey.currentContext;
      if (mounted && target != null) {
        Scrollable.ensureVisible(target, alignment: .4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = StampBookColors(context);
    return SafeArea(
      top: false,
      child: Column(
        key: const ValueKey('stamp-book-station-sheet'),
        children: [
          const SizedBox(height: 10),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: c.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      localized(context, '역 선택', 'Select station'),
                      style: TextStyle(
                        color: c.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('stamp-book-station-sheet-close'),
                  tooltip: localized(context, '닫기', 'Close'),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: c.teal,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.session,
              builder: (context, _) => SingleChildScrollView(
                key: const ValueKey('stamp-book-station-sheet-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    for (var i = 0; i < widget.names.length; i++)
                      Padding(
                        key: i == widget.selected ? _selectedKey : null,
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Semantics(
                          selected: i == widget.selected,
                          child: Material(
                            color: i == widget.selected ? c.line : c.paper,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('stamp-book-station-option-$i'),
                              onTap: () => Navigator.pop(context, i),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      ExcludeSemantics(
                                        child: Icon(
                                          widget.session.collected.contains(
                                                widget.line.stations[i].id,
                                              )
                                              ? Icons
                                                    .check_circle_outline_rounded
                                              : Icons.circle_outlined,
                                          color: c.teal,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.names[i],
                                              style: TextStyle(
                                                color: c.ink,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              localized(
                                                context,
                                                widget.session.collected
                                                        .contains(
                                                          widget
                                                              .line
                                                              .stations[i]
                                                              .id,
                                                        )
                                                    ? '수집 완료'
                                                    : '미수집',
                                                widget.session.collected
                                                        .contains(
                                                          widget
                                                              .line
                                                              .stations[i]
                                                              .id,
                                                        )
                                                    ? 'Collected'
                                                    : 'Not collected',
                                              ),
                                              style: TextStyle(
                                                color: c.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (i == widget.selected)
                                        ExcludeSemantics(
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: c.teal,
                                            size: 20,
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
