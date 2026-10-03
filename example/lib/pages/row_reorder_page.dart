import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class RowReorderPage extends StatefulWidget {
  const RowReorderPage({super.key});

  @override
  State<RowReorderPage> createState() => _RowReorderPageState();
}

class _RowReorderPageState extends State<RowReorderPage> {
  late final AppGridController<Map<String, dynamic>> _controller;
  final List<String> _reorderLogs = [];

  final List<Map<String, dynamic>> _initialTasks = [
    {
      'id': 'TSK-101',
      'title': 'Design high-performance 2D viewport',
      'priority': 'High',
      'assignee': 'Ahmad',
      'status': 'Done'
    },
    {
      'id': 'TSK-102',
      'title': 'Implement granular row reactivity',
      'priority': 'High',
      'assignee': 'Sarah',
      'status': 'Done'
    },
    {
      'id': 'TSK-103',
      'title': 'Add frame-synced batch throttler',
      'priority': 'Medium',
      'assignee': 'Budi',
      'status': 'Done'
    },
    {
      'id': 'TSK-104',
      'title': 'Manual row drag-and-drop reordering',
      'priority': 'High',
      'assignee': 'Ahmad',
      'status': 'In Progress'
    },
    {
      'id': 'TSK-105',
      'title': 'Disable drag handles on active sort',
      'priority': 'Medium',
      'assignee': 'Sarah',
      'status': 'In Progress'
    },
    {
      'id': 'TSK-106',
      'title': 'Add getReorderedData helper utility',
      'priority': 'Low',
      'assignee': 'Budi',
      'status': 'In Progress'
    },
    {
      'id': 'TSK-107',
      'title': 'Write comprehensive test suite',
      'priority': 'High',
      'assignee': 'Ahmad',
      'status': 'Pending'
    },
    {
      'id': 'TSK-108',
      'title': 'Release AppGrid version 1.5.0',
      'priority': 'Medium',
      'assignee': 'Team',
      'status': 'Pending'
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      initialData: _initialTasks,
      columns: [
        GridColumn.rowDragHandle(),
        GridColumn(
          id: 'pos',
          label: '#',
          initialWidth: 50,
          minWidth: 50,
          pin: GridColumnPin.left,
          isSortable: false,
          isResizable: false,
          cellAlignment: Alignment.center,
          headerAlignment: Alignment.center,
          cellBuilder: (context, data, indexInfo) {
            return Center(
              child: Text(
                '${indexInfo.displayIndex + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        GridColumn(
          id: 'id',
          label: 'Task ID',
          initialWidth: 100,
          minWidth: 80,
          valueGetter: (r) => r['id'],
        ),
        GridColumn(
          id: 'title',
          label: 'Task Title',
          initialWidth: 260,
          minWidth: 160,
          valueGetter: (r) => r['title'],
        ),
        GridColumn(
          id: 'priority',
          label: 'Priority',
          initialWidth: 110,
          minWidth: 80,
          valueGetter: (r) => r['priority'],
          cellBuilder: (context, data, info) {
            final p = data['priority'] as String;
            final color = p == 'High'
                ? Colors.red
                : p == 'Medium'
                    ? Colors.orange
                    : Colors.blue;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withAlpha(100)),
              ),
              child: Text(
                p,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        GridColumn(
          id: 'assignee',
          label: 'Assignee',
          initialWidth: 120,
          minWidth: 90,
          valueGetter: (r) => r['assignee'],
        ),
        GridColumn(
          id: 'status',
          label: 'Status',
          initialWidth: 120,
          minWidth: 90,
          valueGetter: (r) => r['status'],
        ),
      ],
      onRowReorder: (oldIndex, newIndex) {
        final item = _controller.getRowByDisplayIndex(newIndex);
        setState(() {
          _reorderLogs.insert(
            0,
            '[${DateTime.now().toIso8601String().substring(11, 19)}] Moved "${item['title']}" from index $oldIndex -> $newIndex',
          );
        });
      },
    );

    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _showModifiedDataDialog() {
    final modifiedList = _controller.getReorderedData();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.playlist_play, color: Colors.blue),
            SizedBox(width: 8),
            Text('Modified Data (getReorderedData())'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 360,
          child: ListView.separated(
            itemCount: modifiedList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final task = modifiedList[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                ),
                title: Text(task['title'] as String,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${task['id']} • ${task['assignee']} • ${task['priority']}'),
                dense: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canReorder = _controller.canReorderRows;
    final sortCriteria = _controller.sortCriteria;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDemoHeader(
            title: 'Manual Row Reordering (Drag & Drop)',
            subtitle:
                'Drag and drop rows using the dedicated drag handle. Automatically disabled when column sorting is active.',
          ),
          const SizedBox(height: 12),

          // Control Bar & Status
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Sorting Status Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: canReorder
                      ? Colors.green.withAlpha(30)
                      : Colors.orange.withAlpha(35),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: canReorder
                        ? Colors.green.withAlpha(120)
                        : Colors.orange.withAlpha(150),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      canReorder
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: canReorder ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      canReorder
                          ? 'Sorting: Inactive (Drag & Drop ENABLED)'
                          : 'Sorting Active (${sortCriteria?.columnId} ${sortCriteria?.direction.name.toUpperCase()}) - Drag Handle DISABLED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: canReorder
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              if (!canReorder)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    if (sortCriteria != null) {
                      _controller.sortByColumn(sortCriteria.columnId,
                          direction: SortDirection.none);
                    }
                  },
                  icon: const Icon(Icons.sort, size: 16),
                  label: const Text('Reset Sort to Re-enable Drag',
                      style: TextStyle(fontSize: 12)),
                ),

              OutlinedButton.icon(
                onPressed: _showModifiedDataDialog,
                icon: const Icon(Icons.data_object, size: 16),
                label: const Text('Inspect Modified Data (List<T>)',
                    style: TextStyle(fontSize: 12)),
              ),

              OutlinedButton.icon(
                onPressed: () {
                  _controller.setRows(_initialTasks);
                  setState(() {
                    _reorderLogs.insert(0,
                        '[${DateTime.now().toIso8601String().substring(11, 19)}] Reset dataset to initial order');
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Initial Order',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Table Grid
          Expanded(
            flex: 3,
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: AppGrid<Map<String, dynamic>>(
                controller: _controller,
                enableRowReorder: true,
                style: const AppGridStyle(
                  rowHeight: 46,
                  headerHeight: 44,
                  showVerticalGridLines: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Event Callback Log Panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'onRowReorder Event Logs',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_reorderLogs.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _reorderLogs.clear()),
                  child:
                      const Text('Clear Logs', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 90,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.dividerColor.withAlpha(40)),
            ),
            child: _reorderLogs.isEmpty
                ? Center(
                    child: Text(
                      'Drag any row using the grab handle on the left to test the onRowReorder callback.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: _reorderLogs.length,
                    itemBuilder: (ctx, idx) => Text(
                      _reorderLogs[idx],
                      style: const TextStyle(
                          fontSize: 11.5, fontFamily: 'monospace'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

const rowReorderSnippet = '''
// 1. Controller with onRowReorder callback & drag handle column
final controller = AppGridController<Task>(
  initialData: tasks,
  columns: [
    // Dedicated Drag Handle column
    GridColumn.rowDragHandle(),

    GridColumn(id: 'id', label: 'ID', initialWidth: 90, valueGetter: (t) => t.id),
    GridColumn(id: 'title', label: 'Title', initialWidth: 240, valueGetter: (t) => t.title),
    GridColumn(id: 'priority', label: 'Priority', initialWidth: 100, valueGetter: (t) => t.priority),
  ],
  onRowReorder: (oldIndex, newIndex) {
    print('Row moved from \$oldIndex to \$newIndex');
  },
);

// 2. Enable row reordering in AppGrid
AppGrid<Task>(
  controller: controller,
  enableRowReorder: true,
  onRowReorder: (oldIndex, newIndex) {
    // Optional widget-level callback
  },
);

// 3. Retrieve modified data in the new user-defined order
List<Task> currentOrder = controller.getReorderedData();

// Note:
// - Drag handles are automatically DISABLED with muted visual styling
//   when any column sort is active (controller.canReorderRows == false).
// - Reordering is in-memory only and is strictly excluded from JSON state persistence.
''';
