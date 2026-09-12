import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/app_grid_controller.dart';
import '../models/data_fetch_mode.dart';

/// Pre-built, production-ready pagination toolbar for [AppGrid].
class AppGridPaginationBar<T> extends StatelessWidget {
  final AppGridController<T> controller;
  final List<int> pageSizeOptions;
  final void Function(int targetPage, int pageSize)? onPageChanged;
  final bool showPageSizeSelector;
  final EdgeInsetsGeometry padding;

  const AppGridPaginationBar({
    super.key,
    required this.controller,
    this.pageSizeOptions = const [5, 10, 20, 25, 50, 100],
    this.onPageChanged,
    this.showPageSizeSelector = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final info = controller.paginationInfo ??
            GridPaginationInfo(
              page: 1,
              limit: math.max(1, controller.displayRowCount),
              totalCount: controller.displayRowCount,
            );

        final totalPages = math.max(1, info.totalPages);
        final currentPage = info.page.clamp(1, totalPages);
        final limit = info.limit;
        final totalCount = info.totalCount;

        final startItem = totalCount == 0 ? 0 : (currentPage - 1) * limit + 1;
        final endItem = math.min(currentPage * limit, totalCount);

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
                width: 1.0,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Showing $startItem–$endItem of $totalCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                ),
                if (showPageSizeSelector) ...[
                  const SizedBox(width: 20),
                  Text(
                    'Rows per page:',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: pageSizeOptions.contains(limit) ? limit : pageSizeOptions.first,
                    isDense: true,
                    underline: const SizedBox(),
                    items: pageSizeOptions.map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size', style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (newSize) {
                      if (newSize != null) {
                        onPageChanged?.call(1, newSize);
                      }
                    },
                  ),
                ],
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.first_page, size: 20),
                  tooltip: 'First Page',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: currentPage > 1
                      ? () => onPageChanged?.call(1, limit)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  tooltip: 'Previous Page',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: currentPage > 1
                      ? () => onPageChanged?.call(currentPage - 1, limit)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Page $currentPage of $totalPages',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  tooltip: 'Next Page',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged?.call(currentPage + 1, limit)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page, size: 20),
                  tooltip: 'Last Page',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged?.call(totalPages, limit)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
