import 'dart:convert';
import 'sort_criteria.dart';

/// Selective snapshot of [AppGrid] layout state for persistence.
///
/// STRICT SPECIFICATION:
/// In accordance with REQ-STATE-02 and REQ-STATE-03, this serialization
/// ONLY includes [columnOrder], [sortCriteria], and [columnVisibility].
/// Under NO circumstances may column widths be serialized or persisted.
class GridState {
  /// Ordered list of column IDs representing active column placement.
  final List<String> columnOrder;

  /// Active column sorting criteria (or null if unsorted).
  final SortCriteria? sortCriteria;

  /// Visibility flag for each column keyed by its ID.
  final Map<String, bool> columnVisibility;

  /// Whether the table is in compact mode.
  final bool compactMode;

  const GridState({
    required this.columnOrder,
    this.sortCriteria,
    required this.columnVisibility,
    this.compactMode = false,
  });

  /// Serializes the state to a map.
  ///
  /// Strictly contains only columnOrder, sortCriteria, columnVisibility, and compactMode.
  /// Column widths are never serialized.
  Map<String, dynamic> toMap() {
    return {
      'columnOrder': List<String>.from(columnOrder),
      'sortCriteria': sortCriteria?.toJson(),
      'columnVisibility': Map<String, bool>.from(columnVisibility),
      'compactMode': compactMode,
    };
  }

  /// Exports the state as a JSON string.
  String toJson() => jsonEncode(toMap());

  /// Deserializes a [GridState] from a map.
  factory GridState.fromMap(Map<String, dynamic> map) {
    return GridState(
      columnOrder: (map['columnOrder'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sortCriteria: map['sortCriteria'] != null
          ? SortCriteria.fromJson(map['sortCriteria'] as Map<String, dynamic>)
          : null,
      columnVisibility: (map['columnVisibility'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v as bool),
          ) ??
          const {},
      compactMode: (map['compactMode'] as bool?) ?? false,
    );
  }

  /// Deserializes a [GridState] from a JSON string.
  factory GridState.fromJson(String source) =>
      GridState.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GridState) return false;

    if (compactMode != other.compactMode) return false;

    if (columnOrder.length != other.columnOrder.length) return false;
    for (var i = 0; i < columnOrder.length; i++) {
      if (columnOrder[i] != other.columnOrder[i]) return false;
    }

    if (sortCriteria != other.sortCriteria) return false;

    if (columnVisibility.length != other.columnVisibility.length) return false;
    for (final entry in columnVisibility.entries) {
      if (other.columnVisibility[entry.key] != entry.value) return false;
    }

    return true;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(columnOrder), sortCriteria, Object.hashAll(columnVisibility.entries), compactMode);

  @override
  String toString() =>
      'GridState(columnOrder: $columnOrder, sortCriteria: $sortCriteria, columnVisibility: $columnVisibility, compactMode: $compactMode)';
}
