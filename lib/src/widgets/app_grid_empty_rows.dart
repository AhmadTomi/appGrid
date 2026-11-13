import 'package:flutter/material.dart';

import '../column_layout/column_layout_manager.dart';
import '../models/app_grid_style.dart';

/// Blank placeholder rows shown when a grid has no data and
/// [AppGridStyle.fillEmptyRows] is on.
///
/// Rows use the same stripes ([AppGridStyle.evenRowColor] /
/// [AppGridStyle.oddRowColor]) and grid lines as real rows, and the vertical
/// lines follow the computed column widths, so the body reads as an empty
/// table rather than blank space.
class AppGridEmptyRows extends StatelessWidget {
  final ComputedGridLayout layout;
  final AppGridStyle style;
  final double rowHeight;

  const AppGridEmptyRows({
    super.key,
    required this.layout,
    required this.style,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultLine =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000);
    final horizontalLine = style.gridLineColor ?? defaultLine;
    final verticalLine =
        style.verticalGridLineColor ?? style.gridLineColor ?? defaultLine;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: CustomPaint(
            key: const ValueKey('app_grid_empty_rows'),
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _EmptyRowsPainter(
              columnEdges: _columnEdges(constraints.maxWidth),
              rowHeight: rowHeight,
              evenRowColor: style.evenRowColor,
              oddRowColor: style.oddRowColor,
              horizontalLineColor:
                  style.showHorizontalGridLines ? horizontalLine : null,
              verticalLineColor:
                  style.showVerticalGridLines ? verticalLine : null,
            ),
          ),
        );
      },
    );
  }

  /// Right edge x of every column, matching the header: left pane from 0,
  /// center pane after it, right pane flush to the right edge.
  List<double> _columnEdges(double width) {
    final edges = <double>[];
    double paneEdges(ComputedPaneLayout pane, double start) {
      var x = start;
      for (final group in pane.groups) {
        x += pane.widths[group.topColumn.id] ?? group.initialWidth;
        edges.add(x);
      }
      return x;
    }

    final leftEnd = paneEdges(layout.leftPane, 0);
    paneEdges(layout.centerPane, leftEnd);
    paneEdges(layout.rightPane, width - layout.rightPane.totalWidth);
    return edges;
  }
}

class _EmptyRowsPainter extends CustomPainter {
  final List<double> columnEdges;
  final double rowHeight;
  final Color? evenRowColor;
  final Color? oddRowColor;
  final Color? horizontalLineColor;
  final Color? verticalLineColor;

  _EmptyRowsPainter({
    required this.columnEdges,
    required this.rowHeight,
    required this.evenRowColor,
    required this.oddRowColor,
    required this.horizontalLineColor,
    required this.verticalLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rowHeight <= 0) return;
    final rowCount = (size.height / rowHeight).ceil();

    for (var i = 0; i < rowCount; i++) {
      final top = i * rowHeight;
      final color = i.isOdd ? oddRowColor : evenRowColor;
      if (color != null) {
        canvas.drawRect(
          Rect.fromLTWH(0, top, size.width, rowHeight),
          Paint()..color = color,
        );
      }
      if (horizontalLineColor != null) {
        canvas.drawRect(
          Rect.fromLTWH(0, top + rowHeight - 1, size.width, 1),
          Paint()..color = horizontalLineColor!,
        );
      }
    }

    if (verticalLineColor != null) {
      final paint = Paint()..color = verticalLineColor!;
      for (final x in columnEdges) {
        if (x <= 0 || x >= size.width) continue;
        canvas.drawRect(Rect.fromLTWH(x - 1, 0, 1, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_EmptyRowsPainter old) =>
      old.rowHeight != rowHeight ||
      old.evenRowColor != evenRowColor ||
      old.oddRowColor != oddRowColor ||
      old.horizontalLineColor != horizontalLineColor ||
      old.verticalLineColor != verticalLineColor ||
      !_listEquals(old.columnEdges, columnEdges);

  static bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
