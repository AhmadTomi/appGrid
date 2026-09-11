import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class InfiniteScrollPage extends StatefulWidget {
  const InfiniteScrollPage({super.key});

  @override
  State<InfiniteScrollPage> createState() => _InfiniteScrollPageState();
}

typedef InfiniteScrollDemo = InfiniteScrollPage;

class _InfiniteScrollPageState extends State<InfiniteScrollPage> {
  late final AppGridController<Map<String, dynamic>> _controller;
  int _loadedCount = 30;
  final int _batchSize = 20;
  final int _maxServerRecords = 200;

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      fetchMode: DataFetchMode.infiniteScroll,
      initialData: _generateBatch(0, _loadedCount),
      columns: [
        GridColumn(
          id: 'index',
          label: '#',
          initialWidth: 70,
          pin: GridColumnPin.left,
          valueGetter: (r) => r['index'],
          cellBuilder: (context, row, info) => Container(
            alignment: Alignment.center,
            child: Text('${row['index']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        GridColumn(id: 'event', label: 'Telemetry Stream Event', initialWidth: 260, valueGetter: (r) => r['event']),
        GridColumn(id: 'service', label: 'Service Origin', initialWidth: 160, valueGetter: (r) => r['service']),
        GridColumn(id: 'timestamp', label: 'Timestamp', initialWidth: 140, valueGetter: (r) => r['timestamp']),
      ],
      onLoadMore: _handleLoadMore,
    );
  }

  List<Map<String, dynamic>> _generateBatch(int start, int count) {
    final services = ['auth-service', 'billing-worker', 'gateway-api', 'cache-node', 'order-processor'];
    return List.generate(count, (i) {
      final idx = start + i + 1;
      return {
        'index': idx,
        'event': 'Packet batch #$idx analyzed and cached',
        'service': services[idx % services.length],
        'timestamp': DateTime.now().subtract(Duration(seconds: (250 - idx) * 12)).toIso8601String().substring(11, 19),
      };
    });
  }

  void _handleLoadMore() {
    if (_loadedCount >= _maxServerRecords) {
      _controller.setLoadMoreLoading(false);
      return;
    }

    // Simulate async network request
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final remaining = _maxServerRecords - _loadedCount;
      final fetchCount = math.min(_batchSize, remaining);
      final newRows = _generateBatch(_loadedCount, fetchCount);
      _loadedCount += fetchCount;
      _controller.appendRows(newRows);
      setState(() {});
    });
  }

  void _resetDemo() {
    setState(() {
      _loadedCount = 30;
      _controller.setRows(_generateBatch(0, 30));
    });
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
            title: 'Data Ingestion: Infinite Scroll (REQ-DATA-01)',
            subtitle: 'Continuous lazy-loading automatically triggered when the vertical scroll extent reaches 80%.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor.withAlpha(40)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.all_inclusive, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Loaded: $_loadedCount / $_maxServerRecords items',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  if (_controller.isLoadingMore) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    const Text('Fetching next batch from API...', style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ] else if (_loadedCount >= _maxServerRecords) ...[
                    const Text('All records fetched!', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                  ] else ...[
                    const Text('Scroll down past 80% to lazy-load more', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _resetDemo,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Reset to 30', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
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

const String infiniteScrollSnippet = '''// REQ-DATA-01: Continuous Infinite Scroll Mode
// Automatically triggers lazy loading when user scrolls past 80% extent.

final controller = AppGridController<TelemetryEvent>(
  fetchMode: DataFetchMode.infiniteScroll,
  initialData: initialBatch,
  columns: [
    GridColumn(
      id: 'index',
      label: '#',
      initialWidth: 70,
      pin: GridColumnPin.left,
      cellBuilder: (context, event, info) => Text('\${event.index}'),
    ),
    GridColumn(id: 'event', label: 'Telemetry Stream Event', initialWidth: 260, valueGetter: (e) => e.event),
    GridColumn(id: 'service', label: 'Service Origin', initialWidth: 160, valueGetter: (e) => e.service),
  ],
  // Callback automatically triggered at 80% threshold:
  onLoadMore: () async {
    // 1. Fetch next batch from API
    final nextBatch = await api.fetchNextBatch(offset: controller.originalRowCount);

    // 2. Append rows to controller (automatically clears loading indicator)
    controller.appendRows(nextBatch);
  },
);

AppGrid<TelemetryEvent>(
  controller: controller,
);''';
