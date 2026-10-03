import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_grid_style.dart';
import '../models/grid_column.dart';
import '../models/compact_column_group.dart';
import '../rendering_engine/grid_builders.dart';

/// Item representing a footer cell that may span multiple column groups horizontally.
class AppGridFooterSpanItem {
  final CompactColumnGroup group;
  final GridColumn column;
  final double width;
  final double offset;
  final int spanCount;

  const AppGridFooterSpanItem({
    required this.group,
    required this.column,
    required this.width,
    required this.offset,
    required this.spanCount,
  });

  /// Computes the spanned footer items for a list of column groups in a pane.
  static List<AppGridFooterSpanItem> computeSpanItems({
    required List<CompactColumnGroup> groups,
    required Map<String, double> widths,
    required Map<String, double> offsets,
  }) {
    final items = <AppGridFooterSpanItem>[];
    int i = 0;
    while (i < groups.length) {
      final grp = groups[i];
      final col = grp.topColumn;
      final requestedSpan = col.footerSpan;
      final actualSpan =
          math.max(1, math.min(requestedSpan, groups.length - i));

      double spanWidth = 0.0;
      for (int s = 0; s < actualSpan; s++) {
        final g = groups[i + s];
        spanWidth += (widths[g.topColumn.id] ?? 0.0);
      }

      final offset = offsets[col.id] ?? 0.0;

      items.add(AppGridFooterSpanItem(
        group: grp,
        column: col,
        width: spanWidth,
        offset: offset,
        spanCount: actualSpan,
      ));

      i += actualSpan;
    }
    return items;
  }
}

/// Renders a column footer cell using [GridFooterBuilder].
class AppGridFooterCell extends StatelessWidget {
  final GridColumn column;
  final CompactColumnGroup? group;
  final double width;
  final double height;
  final List<dynamic> currentVisibleData;
  final GridFooterBuilder? customFooterBuilder;
  final AppGridStyle style;

  const AppGridFooterCell({
    super.key,
    required this.column,
    this.group,
    required this.width,
    required this.height,
    required this.currentVisibleData,
    this.customFooterBuilder,
    this.style = const AppGridStyle(),
  });

  Widget _buildSingleFooter(
      BuildContext context, GridColumn col, ThemeData theme) {
    if (col.footerBuilder != null) {
      return Container(
        alignment: col.footerAlignment,
        child: col.footerBuilder!(context, currentVisibleData),
      );
    } else if (customFooterBuilder != null) {
      return Container(
        alignment: col.footerAlignment,
        child: customFooterBuilder!(context, col, currentVisibleData),
      );
    } else {
      return Container(
        alignment: col.footerAlignment,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(
          'Total: ${currentVisibleData.length}',
          style:
              theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final horizontalLineColor = style.gridLineColor ??
        (isDark ? const Color(0x3FFFFFFF) : const Color(0x3F000000));

    Widget content;
    if (group != null && group!.isPair) {
      content = Column(
        children: [
          Expanded(child: _buildSingleFooter(context, group!.topColumn, theme)),
          Container(height: 0.8, color: horizontalLineColor),
          Expanded(
              child: _buildSingleFooter(context, group!.bottomColumn!, theme)),
        ],
      );
    } else {
      content = _buildSingleFooter(context, column, theme);
    }

    final defaultBg =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE);
    final verticalDividerColor = style.verticalGridLineColor ??
        style.gridLineColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000));

    return Container(
      width: width,
      height: height,
      color: defaultBg,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                right: style.showVerticalGridLines ? 1.0 : 0.0,
                top: style.showHorizontalGridLines ? 1.5 : 0.0,
              ),
              child: content,
            ),
          ),
          // Horizontal top divider
          if (style.showHorizontalGridLines)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1.5,
              child: Container(
                color: horizontalLineColor,
              ),
            ),
          // Vertical right divider rendered on top of horizontal line
          if (style.showVerticalGridLines)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 1.0,
              child: Container(
                color: verticalDividerColor,
              ),
            ),
        ],
      ),
    );
  }
}
