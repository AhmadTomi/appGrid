import 'package:flutter/material.dart';
import '../models/app_grid_style.dart';
import '../models/grid_column.dart';
import '../models/compact_column_group.dart';
import '../rendering_engine/grid_builders.dart';

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
      return col.footerBuilder!(context, currentVisibleData);
    } else if (customFooterBuilder != null) {
      return customFooterBuilder!(context, col, currentVisibleData);
    } else {
      return Container(
        alignment: Alignment.centerLeft,
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
