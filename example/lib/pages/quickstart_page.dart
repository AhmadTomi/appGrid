import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class QuickstartPage extends StatefulWidget {
  const QuickstartPage({super.key});

  @override
  State<QuickstartPage> createState() => _QuickstartPageState();
}

typedef QuickstartDemo = QuickstartPage;

class _QuickstartPageState extends State<QuickstartPage> {
  late final AppGridController<Map<String, dynamic>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'id': 101, 'name': 'Sarah Connor', 'role': 'Security Lead', 'status': 'Active', 'salary': 95000},
        {'id': 102, 'name': 'John Reese', 'role': 'Field Agent', 'status': 'Active', 'salary': 88000},
        {'id': 103, 'name': 'Harold Finch', 'role': 'Chief Architect', 'status': 'Offline', 'salary': 120000},
        {'id': 104, 'name': 'Sameen Shaw', 'role': 'Operative', 'status': 'Active', 'salary': 91000},
        {'id': 105, 'name': 'Root', 'role': 'Analyst', 'status': 'Active', 'salary': 105000},
      ],
      columns: [
        GridColumn(id: 'id', label: 'ID', initialWidth: 80, minWidth: 60, valueGetter: (r) => r['id']),
        GridColumn(id: 'name', label: 'Employee Name', initialWidth: 160, minWidth: 120, valueGetter: (r) => r['name']),
        GridColumn(id: 'role', label: 'Role', initialWidth: 150, minWidth: 100, valueGetter: (r) => r['role']),
        GridColumn(
          id: 'status',
          label: 'Status',
          initialWidth: 110,
          minWidth: 90,
          valueGetter: (r) => r['status'],
          cellBuilder: (context, row, info) {
            final status = row['status'] as String;
            final isActive = status == 'Active';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withAlpha(40) : Colors.grey.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            );
          },
        ),
        GridColumn(id: 'salary', label: 'Salary (\$)', initialWidth: 120, minWidth: 90, valueGetter: (r) => r['salary']),
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
            title: 'Overview & Quickstart',
            subtitle: 'Declarative, type-safe high-performance grid with custom cell rendering.',
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

const String quickstartSnippet = '''import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';

class QuickstartGridExample extends StatefulWidget {
  const QuickstartGridExample({super.key});

  @override
  State<QuickstartGridExample> createState() => _QuickstartGridExampleState();
}

class _QuickstartGridExampleState extends State<QuickstartGridExample> {
  late final AppGridController<Map<String, dynamic>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'id': 101, 'name': 'Sarah Connor', 'role': 'Security Lead'},
        {'id': 102, 'name': 'John Reese', 'role': 'Field Agent'},
      ],
      columns: [
        GridColumn(id: 'id', label: 'ID', initialWidth: 80, valueGetter: (r) => r['id']),
        GridColumn(id: 'name', label: 'Name', initialWidth: 160, valueGetter: (r) => r['name']),
        GridColumn(id: 'role', label: 'Role', initialWidth: 140, valueGetter: (r) => r['role']),
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
    return AppGrid<Map<String, dynamic>>(
      controller: _controller,
      rowHeight: 48.0,
      headerHeight: 48.0,
    );
  }
}''';
