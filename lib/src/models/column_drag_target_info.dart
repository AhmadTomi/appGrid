/// Information describing the active target column and drop orientation
/// during an ongoing column header drag-and-drop reorder operation.
class ColumnDragTargetInfo {
  /// The identifier of the column being hovered over as the potential drop target.
  final String targetColumnId;

  /// The identifier of the column (or joined IDs) currently being dragged.
  final String draggedColumnId;

  /// Whether the drop line indicator is located on the left edge (`true`)
  /// or right edge (`false`) of the target column.
  final bool isLeft;

  const ColumnDragTargetInfo({
    required this.targetColumnId,
    required this.draggedColumnId,
    required this.isLeft,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnDragTargetInfo &&
          runtimeType == other.runtimeType &&
          targetColumnId == other.targetColumnId &&
          draggedColumnId == other.draggedColumnId &&
          isLeft == other.isLeft;

  @override
  int get hashCode => Object.hash(targetColumnId, draggedColumnId, isLeft);

  @override
  String toString() =>
      'ColumnDragTargetInfo(target: $targetColumnId, dragged: $draggedColumnId, isLeft: $isLeft)';
}
