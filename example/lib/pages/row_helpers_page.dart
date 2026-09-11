import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class RowHelpersPage extends StatefulWidget {
  const RowHelpersPage({super.key});

  @override
  State<RowHelpersPage> createState() => _RowHelpersPageState();
}

typedef RowHelpersDemo = RowHelpersPage;

class _RowHelpersPageState extends State<RowHelpersPage> {
  late final AppGridController<Map<String, dynamic>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      rowIdGetter: (item) => item['id'],
      initialData: [
        {'id': 'usr_1', 'name': 'Emma Watson', 'level': 1, 'score': 100},
        {'id': 'usr_2', 'name': 'David Tennant', 'level': 2, 'score': 250},
        {'id': 'usr_3', 'name': 'Matt Smith', 'level': 3, 'score': 420},
      ],
      columns: [
        GridColumn(id: 'id', label: 'User ID', initialWidth: 100, valueGetter: (r) => r['id']),
        GridColumn(id: 'name', label: 'Name', initialWidth: 160, valueGetter: (r) => r['name']),
        GridColumn(id: 'level', label: 'Level', initialWidth: 100, valueGetter: (r) => r['level']),
        GridColumn(id: 'score', label: 'Score', initialWidth: 100, valueGetter: (r) => r['score']),
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
            title: 'Developer Row & Batch Mutation Helpers',
            subtitle: 'Direct helper methods on AppGridController so you never have to loop cells manually.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _controller.updateRow(0, {'id': 'usr_1', 'name': 'Emma (Updated)', 'level': 5, 'score': 999});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('updateRow(0, ...) executed!'), duration: Duration(seconds: 1)));
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('updateRow(0)'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _controller.patchRow(1, (prev) => {
                    'id': prev['id'],
                    'name': prev['name'],
                    'level': (prev['level'] as int) + 1,
                    'score': (prev['score'] as int) + 50,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('patchRow(1) executed (Level + 1)!'), duration: Duration(seconds: 1)));
                },
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('patchRow(1)'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _controller.updateRowById('usr_3', {'id': 'usr_3', 'name': 'Matt Smith (VIP)', 'level': 99, 'score': 9999});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("updateRowById('usr_3', ...) executed!"), duration: Duration(seconds: 1)));
                },
                icon: const Icon(Icons.badge, size: 16),
                label: const Text("updateRowById('usr_3')"),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _controller.batchUpdateRows({
                    0: {'id': 'usr_1', 'name': 'Emma W.', 'level': 10, 'score': 1200},
                    1: {'id': 'usr_2', 'name': 'David T.', 'level': 20, 'score': 2400},
                    2: {'id': 'usr_3', 'name': 'Matt S.', 'level': 30, 'score': 3600},
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('batchUpdateRows(...) executed!'), duration: Duration(seconds: 1)));
                },
                icon: const Icon(Icons.dynamic_feed, size: 16),
                label: const Text('batchUpdateRows()'),
              ),
            ],
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

const String rowHelpersSnippet = '''// Developer Row & Batch Mutation Helpers:
// 1. Direct 1-row update by original index:
controller.updateRow(originalIndex, updatedUser);

// 2. Direct 1-row update by active visual index:
controller.updateRowAtDisplayIndex(displayIndex, updatedUser);

// 3. Update by ID using configured rowIdGetter:
controller.updateRowById('usr_42', updatedUser);

// 4. Functional patch of existing state:
controller.patchRow(originalIndex, (currentUser) {
  return currentUser.copyWith(status: 'Active', score: 500);
});

// 5. Update rows matching a predicate:
controller.updateRowWhere(
  (user) => user.isExpired,
  (user) => user.copyWith(status: 'Archived'),
);

// 6. High-volume batch updates:
controller.batchUpdateRows({
  0: updatedUserA,
  1: updatedUserB,
});''';
