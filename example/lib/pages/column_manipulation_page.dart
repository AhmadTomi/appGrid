import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class ColumnManipulationPage extends StatefulWidget {
  const ColumnManipulationPage({super.key});

  @override
  State<ColumnManipulationPage> createState() => _ColumnManipulationPageState();
}

typedef ColumnManipulationDemo = ColumnManipulationPage;

class _ColumnManipulationPageState extends State<ColumnManipulationPage> {
  late final AppGridController<Map<String, dynamic>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'code': 'A1', 'title': 'Introduction to Flutter Architecture', 'author': 'Google DeepMind Team', 'rating': 4.9},
        {'code': 'B2', 'title': 'High Performance 2D Graphics', 'author': 'Dart Team', 'rating': 4.8},
        {'code': 'C3', 'title': 'Spec-Driven Engineering in Practice', 'author': 'Antigravity Lead', 'rating': 5.0},
      ],
      columns: [
        GridColumn(id: 'code', label: 'Code', initialWidth: 90, minWidth: 60, valueGetter: (r) => r['code']),
        GridColumn(id: 'title', label: 'Title (Double click resize handle to Auto-Fit)', initialWidth: 160, minWidth: 100, valueGetter: (r) => r['title']),
        GridColumn(id: 'author', label: 'Author', initialWidth: 150, minWidth: 100, valueGetter: (r) => r['author']),
        GridColumn(id: 'rating', label: 'Rating', initialWidth: 100, minWidth: 70, valueGetter: (r) => r['rating']),
      ],
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
            title: 'Interactive Column Manipulation',
            subtitle: '1. Drag header to reorder • 2. Drag right handle to resize • 3. Double-click handle to auto-fit!',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }
}

const String columnManipulationSnippet = '''// REQ-COL-02 & REQ-COL-03:
// 1. Drag header to reorder columns.
// 2. Drag right edge of header cell to resize.
// 3. Double-click resize handle to auto-fit longest content!

GridColumn(
  id: 'title',
  label: 'Book Title',
  initialWidth: 160,
  minWidth: 100,
  maxWidth: 400,
  isResizable: true,    // enables drag-resize handle
  isReorderable: true,  // enables drag-and-drop header reorder
  isSortable: true,     // enables header click sort toggle
);''';
