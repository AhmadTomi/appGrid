import 'dart:math' as math;
import '../models/grid_column.dart';
import '../models/compact_column_group.dart';

/// Range of indices currently visible within the virtualized viewport window.
class VirtualizedRange {
  final int startIndex;
  final int endIndex;

  const VirtualizedRange(this.startIndex, this.endIndex);

  int get count => (endIndex >= startIndex) ? (endIndex - startIndex + 1) : 0;

  bool contains(int index) => index >= startIndex && index <= endIndex;

  @override
  String toString() => 'VirtualizedRange($startIndex..$endIndex, count: $count)';
}

/// Helper algorithms calculating 2D virtualization windows (rows and columns)
/// with buffer limits to ensure DOM/Widget element bounds do not exceed visible + 1 buffer.
class VirtualizedGridLayout {
  const VirtualizedGridLayout();

  /// Computes the visible vertical row range given [scrollOffset] and [viewportHeight].
  ///
  /// Strictly enforces REQ-PERF-01, REQ-PERF-02, and AC-01:
  /// Element allocations never exceed the visible window plus [bufferRows] (default 1).
  static VirtualizedRange computeRowRange({
    required double scrollOffset,
    required double viewportHeight,
    required double rowHeight,
    required int totalRows,
    int bufferRows = 1,
  }) {
    if (totalRows <= 0 || rowHeight <= 0 || viewportHeight <= 0) {
      return const VirtualizedRange(0, -1);
    }

    final double effectiveOffset = math.max(0.0, scrollOffset);
    final int firstCalculated = (effectiveOffset / rowHeight).floor();
    final int visibleCount = (viewportHeight / rowHeight).ceil();

    final int start = math.max(0, firstCalculated - bufferRows);
    final int end = math.min(totalRows - 1, firstCalculated + visibleCount + bufferRows);

    return VirtualizedRange(start, end);
  }

  /// Computes the horizontal visible column range for unpinned scrollable columns.
  static VirtualizedRange computeColumnRange({
    required double scrollOffset,
    required double viewportWidth,
    required List<GridColumn> columns,
    required Map<String, double> widths,
    required Map<String, double> offsets,
  }) {
    if (columns.isEmpty || viewportWidth <= 0) {
      return const VirtualizedRange(0, -1);
    }

    final double startX = math.max(0.0, scrollOffset);
    final double endX = startX + viewportWidth;

    int startIndex = -1;
    int endIndex = -1;

    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      final colX = offsets[col.id] ?? 0.0;
      final colW = widths[col.id] ?? col.initialWidth;
      final colRight = colX + colW;

      // Check intersection between [colX, colRight] and [startX, endX]
      if (colRight > startX && colX < endX) {
        if (startIndex == -1) startIndex = i;
        endIndex = i;
      }
    }

    if (startIndex == -1) {
      return const VirtualizedRange(0, -1);
    }

    // Add 1 buffer column left and right if available
    final int bufferedStart = math.max(0, startIndex - 1);
    final int bufferedEnd = math.min(columns.length - 1, endIndex + 1);

    return VirtualizedRange(bufferedStart, bufferedEnd);
  }

  /// Computes the horizontal visible group range for unpinned scrollable column groups.
  static VirtualizedRange computeGroupRange({
    required double scrollOffset,
    required double viewportWidth,
    required List<CompactColumnGroup> groups,
    required Map<String, double> widths,
    required Map<String, double> offsets,
  }) {
    if (groups.isEmpty || viewportWidth <= 0) {
      return const VirtualizedRange(0, -1);
    }

    final double startX = math.max(0.0, scrollOffset);
    final double endX = startX + viewportWidth;

    int startIndex = -1;
    int endIndex = -1;

    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final colX = offsets[group.topColumn.id] ?? 0.0;
      final colW = widths[group.topColumn.id] ?? group.initialWidth;
      final colRight = colX + colW;

      // Check intersection between [colX, colRight] and [startX, endX]
      if (colRight > startX && colX < endX) {
        if (startIndex == -1) startIndex = i;
        endIndex = i;
      }
    }

    if (startIndex == -1) {
      return const VirtualizedRange(0, -1);
    }

    final int bufferedStart = math.max(0, startIndex - 1);
    final int bufferedEnd = math.min(groups.length - 1, endIndex + 1);

    return VirtualizedRange(bufferedStart, bufferedEnd);
  }
}
