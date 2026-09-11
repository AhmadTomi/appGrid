import 'package:flutter/material.dart';
import '../models/grid_column.dart';
import '../rendering_engine/grid_builders.dart';

/// Renders a column footer cell using [GridFooterBuilder].
class AppGridFooterCell extends StatelessWidget {
  final GridColumn column;
  final double width;
  final double height;
  final List<dynamic> currentVisibleData;
  final GridFooterBuilder? customFooterBuilder;

  const AppGridFooterCell({
    super.key,
    required this.column,
    required this.width,
    required this.height,
    required this.currentVisibleData,
    this.customFooterBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content;
    if (column.footerBuilder != null) {
      content = column.footerBuilder!(context, currentVisibleData);
    } else if (customFooterBuilder != null) {
      content = customFooterBuilder!(context, column, currentVisibleData);
    } else {
      content = Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(
          'Total: ${currentVisibleData.length}',
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
            width: 1.0,
          ),
          top: BorderSide(
            color: isDark ? const Color(0x3FFFFFFF) : const Color(0x3F000000),
            width: 1.5,
          ),
        ),
      ),
      child: content,
    );
  }
}
