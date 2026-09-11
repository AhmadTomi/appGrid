import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class ColumnFreezingPage extends StatefulWidget {
  const ColumnFreezingPage({super.key});

  @override
  State<ColumnFreezingPage> createState() => _ColumnFreezingPageState();
}

typedef ColumnFreezingDemo = ColumnFreezingPage;

class _ColumnFreezingPageState extends State<ColumnFreezingPage> {
  late final AppGridController<Map<String, dynamic>> _controller;

  @override
  void initState() {
    super.initState();
    final data = List.generate(30, (i) => {
      'id': 'ID-$i',
      'name': 'Client $i',
      for (var c = 1; c <= 10; c++) 'metric_$c': (i * c * 13) % 100,
      'actions': 'Action $i',
    });

    _controller = AppGridController<Map<String, dynamic>>(
      initialData: data,
      columns: [
        GridColumn(id: 'id', label: 'Frozen ID', initialWidth: 100, pin: GridColumnPin.left, valueGetter: (r) => r['id']),
        GridColumn(id: 'name', label: 'Frozen Name', initialWidth: 140, pin: GridColumnPin.left, valueGetter: (r) => r['name']),
        for (var c = 1; c <= 10; c++)
          GridColumn(id: 'metric_$c', label: 'Metric #$c', initialWidth: 120, valueGetter: (r) => r['metric_$c']),
        GridColumn(
          id: 'actions',
          label: 'Frozen Action',
          initialWidth: 130,
          pin: GridColumnPin.right,
          valueGetter: (r) => r['actions'],
          cellBuilder: (context, row, info) => Container(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('View', style: TextStyle(fontSize: 11)),
            ),
          ),
        ),
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
            title: 'Column Freezing (Left & Right Panes)',
            subtitle: 'REQ-COL-01: Freeze left columns and right columns while horizontally scrolling the center pane.',
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

const String columnFreezingSnippet = '''// REQ-COL-01: Freeze left or right columns
final columns = [
  // Pinned to left: stays static during horizontal scroll
  GridColumn(
    id: 'id',
    label: 'ID',
    pin: GridColumnPin.left,
    initialWidth: 90,
  ),
  GridColumn(
    id: 'name',
    label: 'Name',
    pin: GridColumnPin.left,
    initialWidth: 150,
  ),

  // Scrollable center columns
  GridColumn(id: 'col1', label: 'Field 1', initialWidth: 120),
  GridColumn(id: 'col2', label: 'Field 2', initialWidth: 120),

  // Pinned to right: stays static during horizontal scroll
  GridColumn(
    id: 'actions',
    label: 'Actions',
    pin: GridColumnPin.right,
    initialWidth: 110,
  ),
];''';
