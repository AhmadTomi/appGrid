import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class SelectionKeyboardPage extends StatefulWidget {
  const SelectionKeyboardPage({super.key});

  @override
  State<SelectionKeyboardPage> createState() => _SelectionKeyboardPageState();
}

typedef SelectionAndKeyboardDemo = SelectionKeyboardPage;

class _SelectionKeyboardPageState extends State<SelectionKeyboardPage> {
  late final AppGridController<Map<String, dynamic>> _controller;
  RowIndexInfo? _activeSelection;

  @override
  void initState() {
    super.initState();
    final data = List.generate(100, (i) => {
      'index': i,
      'title': 'Task #$i',
      'priority': (i * 7) % 5 + 1,
    });

    _controller = AppGridController<Map<String, dynamic>>(
      initialData: data,
      columns: [
        GridColumn(id: 'index', label: 'Raw Index', initialWidth: 120, valueGetter: (r) => r['index']),
        GridColumn(id: 'title', label: 'Task Title', initialWidth: 200, valueGetter: (r) => r['title']),
        GridColumn(id: 'priority', label: 'Priority', initialWidth: 120, valueGetter: (r) => r['priority']),
      ],
      onRowSelected: (info) {
        setState(() => _activeSelection = info);
      },
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
            title: 'Dual-Index Selection & Keyboard Navigation',
            subtitle: 'REQ-NAV-01 & AC-03/04: Click any row or use keyboard shortcuts (ArrowUp/Down, Home, End, PageUp/Down).',
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(Icons.arrow_upward, size: 16),
                label: Text('↑ / ↓ : Step row'),
              ),
              Chip(
                avatar: Icon(Icons.vertical_align_top, size: 16),
                label: Text('Home / End : Jump start/end'),
              ),
              Chip(
                avatar: Icon(Icons.swap_vert, size: 16),
                label: Text('PgUp / PgDn : Jump page'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            color: _activeSelection != null
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _activeSelection != null ? Icons.check_circle : Icons.keyboard,
                    color: _activeSelection != null ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _activeSelection != null
                        ? 'Visual (displayIndex): ${_activeSelection!.displayIndex}  |  Raw Data (originalIndex): ${_activeSelection!.originalIndex}'
                        : 'No row selected yet. Press ↓ or click any row to select & navigate with keyboard.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
              autofocus: true,
            ),
          ),
        ],
      ),
    );
  }
}

const String selectionAndKeyboardSnippet = '''// REQ-SEL-01, REQ-SEL-02 & REQ-NAV-01:
AppGrid<Task>(
  controller: controller,
  onRowSelected: (RowIndexInfo info) {
    // AC-03: Returns both originalIndex and active displayIndex
    print('Raw original index: \${info.originalIndex}');
    print('Visual display index: \${info.displayIndex}');
  },
);

// Keyboard Navigation:
// - ArrowUp / ArrowDown: Step selection by 1 row
// - Home: Jump to first row (displayIndex 0)
// - End: Jump to last row
// - PageUp / PageDown: Jump by visible row count (AC-04)''';
