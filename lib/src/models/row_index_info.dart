/// Represents the dual-index mapping for a row in [AppGrid].
///
/// [originalIndex] corresponds to the raw position in the input dataset.
/// [displayIndex] corresponds to the visual position after active sorting and filtering.
class RowIndexInfo {
  /// The index of the row in the original, unsorted, unfiltered dataset.
  final int originalIndex;

  /// The active visual index of the row after sorting and filtering are applied.
  final int displayIndex;

  const RowIndexInfo({
    required this.originalIndex,
    required this.displayIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RowIndexInfo &&
          runtimeType == other.runtimeType &&
          originalIndex == other.originalIndex &&
          displayIndex == other.displayIndex;

  @override
  int get hashCode => originalIndex.hashCode ^ displayIndex.hashCode;

  @override
  String toString() =>
      'RowIndexInfo(originalIndex: $originalIndex, displayIndex: $displayIndex)';
}
