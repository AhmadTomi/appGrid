import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class AutoStretchPage extends StatefulWidget {
  const AutoStretchPage({super.key});

  @override
  State<AutoStretchPage> createState() => _AutoStretchPageState();
}

typedef AutoStretchDemo = AutoStretchPage;

class _AutoStretchPageState extends State<AutoStretchPage> {
  bool _wideColumnsMode = false;
  Key _gridKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final List<GridColumn> columns = _wideColumnsMode
        ? [
            GridColumn(id: 'col1', label: 'Field 1 (min 300)', minWidth: 300, initialWidth: 300, valueGetter: (r) => r['col1']),
            GridColumn(id: 'col2', label: 'Field 2 (min 300)', minWidth: 300, initialWidth: 300, valueGetter: (r) => r['col2']),
            GridColumn(id: 'col3', label: 'Field 3 (min 300)', minWidth: 300, initialWidth: 300, valueGetter: (r) => r['col3']),
            GridColumn(id: 'col4', label: 'Field 4 (min 300)', minWidth: 300, initialWidth: 300, valueGetter: (r) => r['col4']),
          ]
        : [
            GridColumn(id: 'col1', label: 'Column 1 (min 100)', minWidth: 100, initialWidth: 100, valueGetter: (r) => r['col1']),
            GridColumn(id: 'col2', label: 'Column 2 (min 150)', minWidth: 150, initialWidth: 150, valueGetter: (r) => r['col2']),
            GridColumn(id: 'col3', label: 'Column 3 (min 150)', minWidth: 150, initialWidth: 150, valueGetter: (r) => r['col3']),
          ];

    final controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'col1': 'Alpha', 'col2': 'Beta', 'col3': 'Gamma', 'col4': 'Delta'},
        {'col1': 'Epsilon', 'col2': 'Zeta', 'col3': 'Eta', 'col4': 'Theta'},
      ],
      columns: columns,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDemoHeader(
            title: 'Auto-Stretch Layout (REQ-COL-05 & AC-06)',
            subtitle: 'Stretches ONLY when sum(minWidth) < Screen. Exceeding sum triggers horizontal scroll. Manual resize disables auto-stretch.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _wideColumnsMode = !_wideColumnsMode;
                    _gridKey = UniqueKey();
                  });
                },
                icon: Icon(_wideColumnsMode ? Icons.compress : Icons.pan_tool_alt),
                label: Text(
                  _wideColumnsMode
                      ? 'Switch to Few Columns (sum < Screen: Auto-Stretch)'
                      : 'Switch to Wide Columns (sum > Screen: Horizontal Scroll)',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _gridKey = UniqueKey();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Widths reset & auto-stretch re-engaged!'), duration: Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Manual Resizes'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _wideColumnsMode ? Colors.amber.withAlpha(40) : Colors.blue.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(_wideColumnsMode ? Icons.swap_horiz : Icons.fullscreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _wideColumnsMode
                        ? 'Total minWidth (1200px) exceeds screen: Auto-stretch inhibited, horizontal scroll active.'
                        : 'Total minWidth (400px) is lower than screen: Auto-stretched proportionally. Try dragging right edge of a column to manually resize and disable auto-stretch!',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              key: _gridKey,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

const String autoStretchSnippet = '''// REQ-COL-05 & AC-06: Auto-Stretch Rules
// 1. Auto-stretch ONLY runs when sum(minWidth) < ScreenWidth:
//    Columns stretch proportionally to fill 100% of the viewport.
// 2. If sum(minWidth) >= ScreenWidth:
//    Auto-stretch is inhibited to allow natural horizontal scrolling.
// 3. If user manually resizes any column:
//    Auto-stretch is immediately DISABLED, preserving manual widths!

final columns = [
  GridColumn(id: 'c1', label: 'Col 1', minWidth: 100, initialWidth: 100),
  GridColumn(id: 'c2', label: 'Col 2', minWidth: 150, initialWidth: 150),
  GridColumn(id: 'c3', label: 'Col 3', minWidth: 150, initialWidth: 150),
];

// sum(minWidth) = 400px.
// If screen is 1000px, remaining 600px is distributed proportionally.
// If user drags to resize a column, auto-stretch disables automatically.''';
