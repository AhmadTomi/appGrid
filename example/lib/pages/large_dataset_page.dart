import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class LargeDatasetPage extends StatefulWidget {
  const LargeDatasetPage({super.key});

  @override
  State<LargeDatasetPage> createState() => _LargeDatasetPageState();
}

typedef LargeDatasetDemo = LargeDatasetPage;

class _LargeDatasetPageState extends State<LargeDatasetPage> {
  late final AppGridController<int> _controller;

  @override
  void initState() {
    super.initState();
    final columns = List.generate(
      50,
      (c) => GridColumn(
        id: 'col_$c',
        label: 'Field $c',
        initialWidth: 110,
        pin: c == 0 ? GridColumnPin.left : GridColumnPin.none,
        valueGetter: (row) => c == 0 ? row : (row * (c + 1) % 10007),
      ),
    );

    _controller = AppGridController<int>(
      initialData: List.generate(100000, (i) => (i * 7919 + 104729) % 100000),
      columns: columns,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDemoHeader(
            title: '100,000 Rows x 50 Columns',
            subtitle: 'AC-01 2D Virtualization: Smooth 60 FPS scrolling with only visible cells (~150) in the widget tree. Fast sorting of 100k rows with zero UI freeze.',
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final sortCrit = _controller.sortCriteria;
              final sortText = sortCrit != null && sortCrit.direction != SortDirection.none
                  ? 'Active Sort: ${sortCrit.columnId} (${sortCrit.direction.name.toUpperCase()})'
                  : 'Unsorted • Click any header to sort';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_controller.isSorting) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Sorting 100,000 rows...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        sortCrit != null ? Icons.sort : Icons.bolt,
                        color: sortCrit != null ? Colors.blue : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dataset: 100k rows • 50 cols • Total: 5M cells • $sortText',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<int>(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }
}

const String largeDatasetSnippet = '''// AC-01: 2D Virtualization for 100,000 Rows x 50 Columns
final controller = AppGridController<int>(
  initialData: List.generate(100000, (i) => i),
  columns: List.generate(
    50,
    (c) => GridColumn(
      id: 'col_\$c',
      label: 'Column \$c',
      initialWidth: 110,
      pin: c == 0 ? GridColumnPin.left : GridColumnPin.none,
      valueGetter: (row) => 'R\$row col_\$c',
    ),
  ),
);

// Only visible rows (+1 buffer) exist in the Flutter widget tree.
AppGrid<int>(
  controller: controller,
  rowHeight: 40.0,
);''';
