import 'dart:math' as math;
import 'grid_column.dart';

/// Represents a visual column group in [AppGrid].
///
/// When `compactMode` is disabled, each column forms an independent single-column group.
/// When `compactMode` is enabled, two adjacent columns with `canCompact == true` within the same
/// pin pane are merged into a paired group with a [topColumn] and [bottomColumn].
class CompactColumnGroup {
  /// The primary (upper) column in this group.
  final GridColumn topColumn;

  /// The secondary (lower) column if this group is merged as a compact pair; otherwise `null`.
  final GridColumn? bottomColumn;

  const CompactColumnGroup({
    required this.topColumn,
    this.bottomColumn,
  });

  /// Whether this group consists of two merged compact columns.
  bool get isPair => bottomColumn != null;

  /// Unique composite identifier for this group.
  String get id => isPair ? '${topColumn.id}__${bottomColumn!.id}' : topColumn.id;

  /// All column IDs participating in this group.
  List<String> get columnIds => [
        topColumn.id,
        if (bottomColumn != null) bottomColumn!.id,
      ];

  /// All columns in this group.
  List<GridColumn> get columns => [
        topColumn,
        if (bottomColumn != null) bottomColumn!,
      ];

  /// The pin location of the columns in this group.
  GridColumnPin get pin => topColumn.pin;

  /// Combined minimum width: max of both columns' minWidth.
  double get minWidth =>
      isPair ? math.max(topColumn.minWidth, bottomColumn!.minWidth) : topColumn.minWidth;

  /// Combined initial width: max of both columns' initialWidth.
  double get initialWidth =>
      isPair ? math.max(topColumn.initialWidth, bottomColumn!.initialWidth) : topColumn.initialWidth;

  /// Combined maximum width cap: max of both columns' maxWidth (or whichever is specified).
  double? get maxWidth {
    if (!isPair) return topColumn.maxWidth;
    if (topColumn.maxWidth != null && bottomColumn!.maxWidth != null) {
      return math.max(topColumn.maxWidth!, bottomColumn!.maxWidth!);
    }
    return topColumn.maxWidth ?? bottomColumn!.maxWidth;
  }

  /// Resolves the effective rendered width for this group given a map of individual column widths.
  double resolveWidth(Map<String, double> widths) {
    final topW = widths[topColumn.id] ?? topColumn.initialWidth;
    if (!isPair) return topW;
    final bottomW = widths[bottomColumn!.id] ?? bottomColumn!.initialWidth;
    return math.max(topW, bottomW);
  }

  /// Groups visible columns into [CompactColumnGroup]s based on [compactMode].
  ///
  /// Columns are grouped greedily from left to right within each pin section.
  /// Adjacent columns are merged if and only if:
  /// 1. [compactMode] is true.
  /// 2. Both columns have `canCompact == true`.
  /// 3. Both columns share the same `pin` placement.
  static List<CompactColumnGroup> buildGroups({
    required List<GridColumn> columns,
    required bool compactMode,
  }) {
    if (!compactMode || columns.isEmpty) {
      return columns.map((col) => CompactColumnGroup(topColumn: col)).toList();
    }

    final groups = <CompactColumnGroup>[];
    var i = 0;
    while (i < columns.length) {
      final current = columns[i];
      if (current.canCompact && i + 1 < columns.length) {
        final next = columns[i + 1];
        if (next.canCompact && current.pin == next.pin) {
          groups.add(CompactColumnGroup(topColumn: current, bottomColumn: next));
          i += 2;
          continue;
        }
      }
      groups.add(CompactColumnGroup(topColumn: current));
      i += 1;
    }

    return groups;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompactColumnGroup &&
          runtimeType == other.runtimeType &&
          topColumn == other.topColumn &&
          bottomColumn == other.bottomColumn;

  @override
  int get hashCode => topColumn.hashCode ^ (bottomColumn?.hashCode ?? 0);

  @override
  String toString() =>
      isPair ? 'CompactColumnGroup(pair: ${topColumn.id} / ${bottomColumn!.id})' : 'CompactColumnGroup(single: ${topColumn.id})';
}
