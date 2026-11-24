import 'sort_criteria.dart';

/// User-adjustable column layout of an [AppGrid] for persistence:
/// column order, column visibility and the active sort.
///
/// Unlike [GridState], it never carries compact mode, and column widths
/// are never part of it.
class GridColumnLayout {
  /// Ordered list of column IDs in display sequence.
  final List<String> columnOrder;

  /// Visibility flag for each column keyed by its ID.
  final Map<String, bool> columnVisibility;

  /// Active sort, or null when the grid is unsorted.
  final SortCriteria? sortCriteria;

  const GridColumnLayout({
    required this.columnOrder,
    required this.columnVisibility,
    this.sortCriteria,
  });

  /// Serializes the layout to a JSON-compatible map.
  Map<String, dynamic> toMap() => {
        'columnOrder': List<String>.from(columnOrder),
        'columnVisibility': Map<String, bool>.from(columnVisibility),
        'sortCriteria': sortCriteria?.toJson(),
      };

  /// Deserializes a layout, ignoring missing or wrong-typed fields.
  factory GridColumnLayout.fromMap(Map<String, dynamic> map) {
    final rawOrder = map['columnOrder'];
    final rawVisibility = map['columnVisibility'];
    final rawSort = map['sortCriteria'];

    final order = rawOrder is List
        ? rawOrder.whereType<String>().toList()
        : <String>[];

    final visibility = <String, bool>{};
    if (rawVisibility is Map) {
      for (final entry in rawVisibility.entries) {
        if (entry.key is String && entry.value is bool) {
          visibility[entry.key as String] = entry.value as bool;
        }
      }
    }

    SortCriteria? sort;
    if (rawSort is Map &&
        rawSort['columnId'] is String &&
        rawSort['direction'] is String) {
      sort = SortCriteria(
        columnId: rawSort['columnId'] as String,
        direction: SortDirection.fromJson(rawSort['direction'] as String),
      );
    }

    return GridColumnLayout(
      columnOrder: order,
      columnVisibility: visibility,
      sortCriteria: sort,
    );
  }

  /// Returns this layout merged onto a previously [stored] one, keeping the
  /// stored order and visibility of columns that this layout does not contain.
  ///
  /// The sort always comes from this layout.
  GridColumnLayout mergedOnto(GridColumnLayout? stored) {
    if (stored == null) return this;

    final order = List<String>.from(columnOrder);
    for (var i = 0; i < stored.columnOrder.length; i++) {
      final id = stored.columnOrder[i];
      if (order.contains(id)) continue;
      var insertAt = 0;
      for (var j = i - 1; j >= 0; j--) {
        final previous = order.indexOf(stored.columnOrder[j]);
        if (previous != -1) {
          insertAt = previous + 1;
          break;
        }
      }
      order.insert(insertAt, id);
    }

    return GridColumnLayout(
      columnOrder: order,
      columnVisibility: {...stored.columnVisibility, ...columnVisibility},
      sortCriteria: sortCriteria,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GridColumnLayout) return false;
    if (sortCriteria != other.sortCriteria) return false;
    if (columnOrder.length != other.columnOrder.length) return false;
    for (var i = 0; i < columnOrder.length; i++) {
      if (columnOrder[i] != other.columnOrder[i]) return false;
    }
    if (columnVisibility.length != other.columnVisibility.length) return false;
    for (final entry in columnVisibility.entries) {
      if (other.columnVisibility[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(columnOrder),
        Object.hashAllUnordered(
            columnVisibility.entries.map((e) => Object.hash(e.key, e.value))),
        sortCriteria,
      );

  @override
  String toString() =>
      'GridColumnLayout(columnOrder: $columnOrder, columnVisibility: $columnVisibility, sortCriteria: $sortCriteria)';
}
