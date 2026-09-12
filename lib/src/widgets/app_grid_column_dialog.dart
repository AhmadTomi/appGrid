import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/app_grid_controller.dart';
import '../models/grid_column.dart';

/// Opens the in-grid column visibility panel on the provided [controller].
///
/// Unlike global dialogs, this does NOT push a route to Navigator and only
/// overlays the target [AppGrid] table area.
void showColumnVisibilityDialog<T>(
  BuildContext context,
  AppGridController<T> controller,
) {
  controller.openColumnChooser();
}

/// In-grid modal overlay scoped exclusively to [AppGrid] to manage column visibility
/// without blocking the global navigator or parent application UI.
class AppGridColumnChooserOverlay<T> extends StatelessWidget {
  final AppGridController<T> controller;
  final VoidCallback? onClose;

  const AppGridColumnChooserOverlay({
    super.key,
    required this.controller,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = math.min(360.0, math.max(200.0, constraints.maxWidth - 32.0));
            final maxH = math.min(420.0, math.max(180.0, constraints.maxHeight - 32.0));

            final allColumns = controller.columns;
            final visibleCols = controller.visibleColumns;
            final visibleIds = visibleCols.map((c) => c.id).toSet();
            final canHideMore = visibleCols.length > 1;

            // Display columns in active order if available
            final orderedIds = controller.exportState().columnOrder;
            final colMap = {for (final c in allColumns) c.id: c};
            final orderedColumns = <GridColumn>[];
            for (final id in orderedIds) {
              if (colMap.containsKey(id)) {
                orderedColumns.add(colMap[id]!);
              }
            }
            for (final col in allColumns) {
              if (!orderedColumns.contains(col)) {
                orderedColumns.add(col);
              }
            }

            final allVisible = visibleIds.length == allColumns.length;
            final closeHandler = onClose ?? controller.closeColumnChooser;

            return Stack(
              children: [
                // Scoped modal barrier covering strictly the table viewport area
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: closeHandler,
                    child: Container(
                      color: Colors.black.withAlpha(isDark ? 160 : 100),
                    ),
                  ),
                ),
                // Centered modal dialog card
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {}, // Prevent taps inside card from dismissing
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        width: maxW,
                        height: maxH,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header title & close button
                            Row(
                              children: [
                                Icon(Icons.view_column_outlined, color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Manage Columns',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  splashRadius: 16,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: closeHandler,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Visibility summary & Show All button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${visibleCols.length} of ${allColumns.length} visible',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                ),
                                if (!allVisible)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: () {
                                      for (final col in allColumns) {
                                        controller.setColumnVisibility(col.id, true);
                                      }
                                    },
                                    icon: const Icon(Icons.select_all, size: 16),
                                    label: const Text('Show All', style: TextStyle(fontSize: 12)),
                                  ),
                              ],
                            ),
                            const Divider(height: 12),
                            // Scrollable list of columns with checkboxes
                            Expanded(
                              child: ListView.builder(
                                itemCount: orderedColumns.length,
                                itemBuilder: (context, index) {
                                  final col = orderedColumns[index];
                                  final isVisible = visibleIds.contains(col.id);
                                  final isOnlyVisible = isVisible && !canHideMore;
                                  final cannotHide = !col.canHide;
                                  final isCheckboxDisabled = cannotHide || isOnlyVisible;

                                  return CheckboxListTile(
                                    value: isVisible,
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    title: Text(
                                      col.label,
                                      style: TextStyle(
                                        fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                                        color: isCheckboxDisabled ? theme.disabledColor : null,
                                      ),
                                    ),
                                    subtitle: cannotHide
                                        ? Text(
                                            'Required column (cannot be hidden)',
                                            style: TextStyle(fontSize: 11, color: theme.disabledColor),
                                          )
                                        : (isOnlyVisible
                                            ? Text(
                                                'At least one column must be visible',
                                                style: TextStyle(fontSize: 11, color: theme.disabledColor),
                                              )
                                            : null),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: isCheckboxDisabled
                                        ? null
                                        : (val) {
                                            if (val != null) {
                                              controller.setColumnVisibility(col.id, val);
                                            }
                                          },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Done button
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onPressed: closeHandler,
                                child: const Text('Done'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
