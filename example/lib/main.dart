import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  runApp(const AppGridShowcaseApp());
}

class AppGridShowcaseApp extends StatelessWidget {
  const AppGridShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppGrid Documentation & Feature Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ShowcaseHomeScreen(),
    );
  }
}

enum GridFeature {
  quickstart('Quickstart & Overview', Icons.rocket_launch, 'Basic table setup with models and builders.'),
  modularBuilders('Modular Column Builders & DX', Icons.dashboard_customize, 'Modular cellBuilder, GridFooter summaries, Empty states, and Header Right-Click Pinning.'),
  largeDataset('100,000 Rows x 50 Cols', Icons.speed, '2D Virtualization benchmark maintaining 60 FPS.'),
  realtimeStreaming('Realtime Streaming Ticks', Icons.bolt, 'High-frequency 60 updates/sec with 0 root rebuilds.'),
  rowHelpers('Row Mutation Helpers', Icons.edit_note, 'Easy 1-row updates, patchRow, and batch updates.'),
  columnFreezing('Column Freezing', Icons.push_pin, 'Static left & right pinned panes with scrollable center.'),
  columnManipulation('Reorder, Resize & Auto-Fit', Icons.tune, 'Interactive header drag reorder, resize, and double-click fit.'),
  autoStretch('Auto-Stretch Layout', Icons.aspect_ratio, 'Proportional column expansion to fill 100% canvas width.'),
  selectionAndKeyboard('Selection & Keyboard', Icons.keyboard, 'Single-row selection with Arrow, Home, End, PageUp/Down.'),
  statePersistence('Selective State Persistence', Icons.save, 'Export & import JSON layout strictly without column widths.'),
  pagination('Discrete Pagination', Icons.pages, 'Discrete page navigation with page, limit, and total count metadata.'),
  infiniteScroll('Infinite Scroll', Icons.all_inclusive, 'Continuous lazy-loading triggered automatically at 80% scroll extent.'),
  exportUtils('CSV & JSON Exporters', Icons.file_download, 'Built-in RFC 4180 CSV and JSON data export utility.');

  final String title;
  final IconData icon;
  final String description;

  const GridFeature(this.title, this.icon, this.description);
}

class ShowcaseHomeScreen extends StatefulWidget {
  const ShowcaseHomeScreen({super.key});

  @override
  State<ShowcaseHomeScreen> createState() => _ShowcaseHomeScreenState();
}

class _ShowcaseHomeScreenState extends State<ShowcaseHomeScreen> {
  GridFeature _selectedFeature = GridFeature.quickstart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AppGrid',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Interactive Documentation & Feature Explorer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Row(
        children: [
          // 1. Left Sidebar Navigation Menu
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor.withAlpha(60),
                ),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'FEATURES & MODULES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                ),
                for (final feat in GridFeature.values)
                  ListTile(
                    dense: true,
                    selected: _selectedFeature == feat,
                    selectedTileColor:
                        Theme.of(context).colorScheme.primary.withAlpha(30),
                    leading: Icon(
                      feat.icon,
                      color: _selectedFeature == feat
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      feat.title,
                      style: TextStyle(
                        fontWeight: _selectedFeature == feat
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedFeature == feat
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedFeature = feat);
                    },
                  ),
              ],
            ),
          ),

          // 2. Main Content Split View: Live Interactive Demo (Left) + Code Snippet (Right)
          Expanded(
            child: FeatureDetailSplitView(feature: _selectedFeature),
          ),
        ],
      ),
    );
  }
}

class FeatureDetailSplitView extends StatelessWidget {
  final GridFeature feature;

  const FeatureDetailSplitView({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 500;

        final demoWidget = FeatureDemoContainer(feature: feature);
        final codeSnippetWidget = CodeSnippetPanel(feature: feature);

        if (isWide) {
          return Row(
            children: [
              // Live Interactive Demo View
              Expanded(
                flex: 6,
                child: demoWidget,
              ),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).dividerColor.withAlpha(60),
              ),
              // Code Snippet & Documentation Panel
              Expanded(
                flex: 5,
                child: codeSnippetWidget,
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(child: demoWidget),
              const Divider(height: 1),
              Expanded(child: codeSnippetWidget),
            ],
          );
        }
      },
    );
  }
}

// ==================== LIVE DEMOS PER FEATURE ====================

class FeatureDemoContainer extends StatefulWidget {
  final GridFeature feature;

  const FeatureDemoContainer({super.key, required this.feature});

  @override
  State<FeatureDemoContainer> createState() => _FeatureDemoContainerState();
}

class _FeatureDemoContainerState extends State<FeatureDemoContainer> {
  @override
  Widget build(BuildContext context) {
    switch (widget.feature) {
      case GridFeature.quickstart:
        return const QuickstartDemo();
      case GridFeature.modularBuilders:
        return const ModularBuildersDemo();
      case GridFeature.largeDataset:
        return const LargeDatasetDemo();
      case GridFeature.realtimeStreaming:
        return const RealtimeStreamingDemo();
      case GridFeature.rowHelpers:
        return const RowHelpersDemo();
      case GridFeature.columnFreezing:
        return const ColumnFreezingDemo();
      case GridFeature.columnManipulation:
        return const ColumnManipulationDemo();
      case GridFeature.autoStretch:
        return const AutoStretchDemo();
      case GridFeature.selectionAndKeyboard:
        return const SelectionAndKeyboardDemo();
      case GridFeature.statePersistence:
        return const StatePersistenceDemo();
      case GridFeature.pagination:
        return const PaginationDemo();
      case GridFeature.infiniteScroll:
        return const InfiniteScrollDemo();
      case GridFeature.exportUtils:
        return const ExportUtilsDemo();
    }
  }
}

// 1. Quickstart Demo
class QuickstartDemo extends StatefulWidget {
  const QuickstartDemo({super.key});

  @override
  State<QuickstartDemo> createState() => _QuickstartDemoState();
}

class _QuickstartDemoState extends State<QuickstartDemo> {
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
        GridColumn(id: 'id', label: 'ID', initialWidth: 80, minWidth: 60, valueGetter: (r) => r['id'],),
        GridColumn(id: 'name', label: 'Employee Name', initialWidth: 160, minWidth: 120, valueGetter: (r) => r['name']),
        GridColumn(id: 'role', label: 'Role', initialWidth: 150, minWidth: 100, valueGetter: (r) => r['role']),
        GridColumn(id: 'status', label: 'Status', initialWidth: 110, minWidth: 90, valueGetter: (r) => r['status']),
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
          _buildDemoHeader(
            title: 'Overview & Quickstart',
            subtitle: 'Declarative, type-safe high-performance grid with custom cell rendering.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
              cellBuilder: (context, row, info, colId) {
                if (colId == 'status') {
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
                }
                final val = row[colId]?.toString() ?? '';
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(val),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Modular Column Builders, Footers & Header Context Menu Demo
class FruitData {
  final String name;
  final String category;
  final int total;
  final double price;
  final String? note;

  const FruitData({
    required this.name,
    required this.category,
    required this.total,
    required this.price,
    this.note,
  });
}

class ModularBuildersDemo extends StatefulWidget {
  const ModularBuildersDemo({super.key});

  @override
  State<ModularBuildersDemo> createState() => _ModularBuildersDemoState();
}

class _ModularBuildersDemoState extends State<ModularBuildersDemo> {
  static const List<FruitData> _sampleFruits = [
    FruitData(name: 'Honeycrisp Apple', category: 'Orchard', total: 140, price: 2.99, note: 'Fresh Harvest'),
    FruitData(name: 'Cavendish Banana', category: 'Tropical', total: 250, price: 0.69, note: 'Fair Trade'),
    FruitData(name: 'Valencia Orange', category: 'Citrus', total: 180, price: 1.49, note: 'High Vitamin C'),
    FruitData(name: 'Alphonso Mango', category: 'Tropical', total: 75, price: 3.50, note: 'Seasonal Premium'),
    FruitData(name: 'Sweet Strawberry', category: 'Berry', total: 95, price: 4.20, note: null),
    FruitData(name: 'Wild Blueberry', category: 'Berry', total: 110, price: 4.99, note: 'Antioxidant Rich'),
    FruitData(name: 'Crimson Watermelon', category: 'Melon', total: 40, price: 5.99, note: null),
    FruitData(name: 'Golden Pineapple', category: 'Tropical', total: 60, price: 3.29, note: 'Extra Sweet'),
    FruitData(name: 'Hass Avocado', category: 'Specialty', total: 130, price: 1.89, note: 'Ripe & Ready'),
    FruitData(name: 'White Peach', category: 'Stone Fruit', total: 85, price: 2.79, note: null),
    FruitData(name: 'Autumn Crisp Grape', category: 'Berry', total: 120, price: 3.89, note: 'Seedless'),
    FruitData(name: 'Golden Kiwi', category: 'Exotic', total: 90, price: 1.25, note: 'New Zealand'),
  ];

  late final AppGridController<FruitData> _controller;
  bool _showEmptyState = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = AppGridController<FruitData>(
      fetchMode: DataFetchMode.pagination,
      paginationInfo: const GridPaginationInfo(page: 1, limit: 6, totalCount: 12),
      initialData: _sampleFruits.take(6).toList(),
      columns: [
        GridColumn(
          id: 'name',
          label: 'Fruit Name',
          initialWidth: 180,
          minWidth: 140,
          footerBuilder: GridFooter.count(prefix: 'Total: ', suffix: ' types'),
        ),
        const GridColumn(
          id: 'category',
          label: 'Category',
          initialWidth: 130,
          minWidth: 100,
        ),
        GridColumn(
          id: 'total',
          label: 'Stock (pcs)',
          initialWidth: 130,
          minWidth: 100,
          footerBuilder: GridFooter.sum<FruitData>(
            (f) => f.total,
            prefix: 'Sum: ',
            suffix: ' pcs',
          ),
        ),
        GridColumn(
          id: 'price',
          label: 'Price',
          initialWidth: 120,
          minWidth: 90,
          footerBuilder: GridFooter.average<FruitData>(
            (f) => f.price,
            prefix: 'Avg: \$',
            precision: 2,
          ),
        ),
        GridColumn(
          id: 'note',
          label: 'Special Note',
          initialWidth: 150,
          minWidth: 110,
          valueGetter: (f) => (f as FruitData).note,
        ),
      ],
      cellBuilders: {
        'name': (context, fruit, info) {
          final f = fruit;
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.eco, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
        'category': (context, fruit, info) {
          final f = fruit;
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                f.category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        },
        'total': (context, fruit, info) {
          final f = fruit;
          final isLow = f.total < 80;
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  '${f.total} pcs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLow ? Colors.orange : null,
                  ),
                ),
                if (isLow) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                ],
              ],
            ),
          );
        },
        'price': (context, fruit, info) {
          final f = fruit;
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '\$${f.price.toStringAsFixed(2)}',
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
            ),
          );
        },
      },
    );
  }

  void _onPageChanged(int page, int pageSize) {
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, _sampleFruits.length);
    final slice = _sampleFruits.sublist(start.clamp(0, _sampleFruits.length), end);

    _controller.setPageData(
      rows: slice,
      pagination: GridPaginationInfo(
        page: page,
        limit: pageSize,
        totalCount: _sampleFruits.length,
      ),
    );
  }

  void _toggleEmptyState() {
    setState(() {
      _showEmptyState = !_showEmptyState;
      if (_showEmptyState) {
        _controller.setPageData(
          rows: [],
          pagination: const GridPaginationInfo(page: 1, limit: 6, totalCount: 0),
        );
      } else {
        _onPageChanged(1, 6);
      }
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
          _buildDemoHeader(
            title: 'Modular Column Builders, Summaries & Header Context Menu',
            subtitle: 'Declare cellBuilder, footer summaries (GridFooter.sum / average / count), and header freeze right on GridColumn.',
          ),
          const SizedBox(height: 12),
          // Interactive Action Toolbar
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _toggleEmptyState,
                icon: Icon(_showEmptyState ? Icons.refresh : Icons.hourglass_empty),
                label: Text(_showEmptyState ? 'Restore Fruit Data' : 'Simulate Empty State'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withAlpha(100)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mouse, size: 16, color: Colors.amber),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Right-click header to freeze/unpin',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.withAlpha(100)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pan_tool, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Click-drag mouse to pan/scroll table 2D',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<FruitData>(
              controller: _controller,
              rowHeight: 44.0,
              headerHeight: 44.0,
              footerHeight: 40.0,
              showPaginationBar: true,
              onPageChanged: _onPageChanged,
              emptyWidget: const AppGridEmptyWidget(
                message: 'No fruit records found. Tap "Restore Fruit Data" to reload catalog.',
                icon: Icons.search_off,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Large Dataset Demo (100,000 x 50)
class LargeDatasetDemo extends StatefulWidget {
  const LargeDatasetDemo({super.key});

  @override
  State<LargeDatasetDemo> createState() => _LargeDatasetDemoState();
}

class _LargeDatasetDemoState extends State<LargeDatasetDemo> {
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
          _buildDemoHeader(
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

              cellBuilder: (context, rowIndex, info, colId) {
                final colNum = int.tryParse(colId.replaceAll('col_', '')) ?? 0;
                final val = colNum == 0 ? rowIndex : (rowIndex * (colNum + 1) % 10007);
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('$val', style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Realtime Streaming Demo
class RealtimeStreamingDemo extends StatefulWidget {
  const RealtimeStreamingDemo({super.key});

  @override
  State<RealtimeStreamingDemo> createState() => _RealtimeStreamingDemoState();
}

class _RealtimeStreamingDemoState extends State<RealtimeStreamingDemo> {
  late final AppGridController<Map<String, dynamic>> _controller;
  Timer? _tickTimer;
  int _updateTicks = 0;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    final data = List.generate(50, (i) => {
      'symbol': 'TICK${100 + i}',
      'price': (100.0 + i * 2.5),
      'change': 0.0,
      'volume': 1000 + i * 50,
    });

    _controller = AppGridController<Map<String, dynamic>>(
      initialData: data,
      columns: [
        GridColumn(id: 'symbol', label: 'Ticker', initialWidth: 100, pin: GridColumnPin.left, valueGetter: (r) => r['symbol']),
        GridColumn(id: 'price', label: 'Price (\$)', initialWidth: 120, valueGetter: (r) => r['price']),
        GridColumn(id: 'change', label: 'Delta', initialWidth: 120, valueGetter: (r) => r['change']),
        GridColumn(id: 'volume', label: 'Volume', initialWidth: 120, valueGetter: (r) => r['volume']),
      ],
    );
  }

  void _toggleStreaming() {
    if (_isStreaming) {
      _tickTimer?.cancel();
      setState(() => _isStreaming = false);
    } else {
      setState(() => _isStreaming = true);
      // Emit high-frequency ticks at ~60 ticks/sec
      _tickTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        final rng = math.Random();
        final targetRow = rng.nextInt(_controller.originalRowCount);
        final current = _controller.getRowByOriginalIndex(targetRow);

        final delta = (rng.nextDouble() - 0.5) * 2.0;
        final newPrice = ((current['price'] as double) + delta);
        final newVolume = (current['volume'] as int) + rng.nextInt(20);

        _controller.updateRow(targetRow, {
          'symbol': current['symbol'],
          'price': double.parse(newPrice.toStringAsFixed(2)),
          'change': double.parse(delta.toStringAsFixed(2)),
          'volume': newVolume,
        });

        _updateTicks++;
        if (_updateTicks % 30 == 0) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
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
          _buildDemoHeader(
            title: 'Realtime High-Frequency Streaming Ticks',
            subtitle: 'AC-02: 60 updates/sec isolated to affected cells without root widget rebuild.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _toggleStreaming,
                icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                label: Text(_isStreaming ? 'Stop Streaming' : 'Start 60 FPS Ticks'),
              ),
              const SizedBox(width: 16),
              Text(
                'Processed Ticks: $_updateTicks',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
              cellBuilder: (context, item, info, colId) {
                final val = item[colId];
                if (colId == 'change') {
                  final delta = val as double;
                  final isPos = delta >= 0;
                  return Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${isPos ? '+' : ''}$delta',
                      style: TextStyle(
                        color: isPos ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(val.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Row Mutation Helpers Demo
class RowHelpersDemo extends StatefulWidget {
  const RowHelpersDemo({super.key});

  @override
  State<RowHelpersDemo> createState() => _RowHelpersDemoState();
}

class _RowHelpersDemoState extends State<RowHelpersDemo> {
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
          _buildDemoHeader(
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
              cellBuilder: (context, row, info, colId) {
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(row[colId].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Column Freezing Demo
class ColumnFreezingDemo extends StatefulWidget {
  const ColumnFreezingDemo({super.key});

  @override
  State<ColumnFreezingDemo> createState() => _ColumnFreezingDemoState();
}

class _ColumnFreezingDemoState extends State<ColumnFreezingDemo> {
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
        GridColumn(id: 'actions', label: 'Frozen Action', initialWidth: 130, pin: GridColumnPin.right, valueGetter: (r) => r['actions']),
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
          _buildDemoHeader(
            title: 'Column Freezing (Left & Right Panes)',
            subtitle: 'REQ-COL-01: Freeze left columns and right columns while horizontally scrolling the center pane.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
              cellBuilder: (context, row, info, colId) {
                if (colId == 'actions') {
                  return Container(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('View', style: TextStyle(fontSize: 11)),
                    ),
                  );
                }
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(row[colId].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 6. Column Manipulation Demo
class ColumnManipulationDemo extends StatefulWidget {
  const ColumnManipulationDemo({super.key});

  @override
  State<ColumnManipulationDemo> createState() => _ColumnManipulationDemoState();
}

class _ColumnManipulationDemoState extends State<ColumnManipulationDemo> {
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
          _buildDemoHeader(
            title: 'Interactive Column Manipulation',
            subtitle: '1. Drag header to reorder • 2. Drag right handle to resize • 3. Double-click handle to auto-fit!',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
              cellBuilder: (context, row, info, colId) {
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(row[colId].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 7. Auto-Stretch Demo
class AutoStretchDemo extends StatefulWidget {
  const AutoStretchDemo({super.key});

  @override
  State<AutoStretchDemo> createState() => _AutoStretchDemoState();
}

class _AutoStretchDemoState extends State<AutoStretchDemo> {
  bool _wideColumnsMode = false;
  Key _gridKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final List<GridColumn> columns = _wideColumnsMode
        ? const [
            GridColumn(id: 'col1', label: 'Field 1 (min 300)', minWidth: 300, initialWidth: 300),
            GridColumn(id: 'col2', label: 'Field 2 (min 300)', minWidth: 300, initialWidth: 300),
            GridColumn(id: 'col3', label: 'Field 3 (min 300)', minWidth: 300, initialWidth: 300),
            GridColumn(id: 'col4', label: 'Field 4 (min 300)', minWidth: 300, initialWidth: 300),
          ]
        : const [
            GridColumn(id: 'col1', label: 'Column 1 (min 100)', minWidth: 100, initialWidth: 100),
            GridColumn(id: 'col2', label: 'Column 2 (min 150)', minWidth: 150, initialWidth: 150),
            GridColumn(id: 'col3', label: 'Column 3 (min 150)', minWidth: 150, initialWidth: 150),
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
          _buildDemoHeader(
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
              cellBuilder: (context, row, info, colId) {
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(row[colId]?.toString() ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 8. Selection & Keyboard Navigation Demo
class SelectionAndKeyboardDemo extends StatefulWidget {
  const SelectionAndKeyboardDemo({super.key});

  @override
  State<SelectionAndKeyboardDemo> createState() => _SelectionAndKeyboardDemoState();
}

class _SelectionAndKeyboardDemoState extends State<SelectionAndKeyboardDemo> {
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
          _buildDemoHeader(
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
              cellBuilder: (context, row, info, colId) {
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(row[colId].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 9. State Persistence Demo
class StatePersistenceDemo extends StatefulWidget {
  const StatePersistenceDemo({super.key});

  @override
  State<StatePersistenceDemo> createState() => _StatePersistenceDemoState();
}

class _StatePersistenceDemoState extends State<StatePersistenceDemo> {
  late final AppGridController<Map<String, dynamic>> _controller;
  String _savedJson = '';

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'id': 1, 'name': 'Item 1', 'price': 99},
        {'id': 2, 'name': 'Item 2', 'price': 149},
      ],
      columns: [
        GridColumn(id: 'id', label: 'ID', initialWidth: 100, valueGetter: (r) => r['id']),
        GridColumn(id: 'name', label: 'Name', initialWidth: 180, valueGetter: (r) => r['name']),
        GridColumn(id: 'price', label: 'Price', initialWidth: 140, valueGetter: (r) => r['price']),
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
          _buildDemoHeader(
            title: 'Selective State Persistence (AC-05)',
            subtitle: 'REQ-STATE-03 Strict Invariant: Serializes columnOrder, sortCriteria, columnVisibility. NO widths allowed.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  final state = _controller.exportState();
                  setState(() => _savedJson = state.toJson());
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export State JSON'),
              ),
              OutlinedButton.icon(
                onPressed: _savedJson.isEmpty
                    ? null
                    : () {
                        final restored = GridState.fromJson(_savedJson);
                        _controller.restoreState(restored);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('State restored successfully!')));
                      },
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Restore State'),
              ),
            ],
          ),
          if (_savedJson.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _savedJson,
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
              cellBuilder: (context, row, info, colId) {
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(row[colId].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 10. Discrete Pagination Demo
class PaginationDemo extends StatefulWidget {
  const PaginationDemo({super.key});

  @override
  State<PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<PaginationDemo> {
  static const int _totalCount = 120;
  int _currentPage = 1;
  int _pageSize = 10;
  bool _isLoading = false;

  late final AppGridController<Map<String, dynamic>> _controller;

  // Mock server dataset
  final List<Map<String, dynamic>> _mockDatabase = List.generate(
    _totalCount,
    (i) {
      final id = 1001 + i;
      final statuses = ['Delivered', 'Processing', 'Cancelled', 'In Transit'];
      final status = statuses[i % statuses.length];
      final amount = ((i * 47 + 23) % 450 + 19.99).toStringAsFixed(2);
      return {
        'id': 'ORD-$id',
        'customer': 'Customer ${(i % 20) + 1}',
        'amount': '\$$amount',
        'status': status,
        'channel': (i % 2 == 0) ? 'Mobile App' : 'Web Store',
      };
    },
  );

  late final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final initialRows = _getPageSlice(_currentPage, _pageSize);
    _controller = AppGridController<Map<String, dynamic>>(
      fetchMode: DataFetchMode.pagination,
      paginationInfo: GridPaginationInfo(
        page: _currentPage,
        limit: _pageSize,
        totalCount: _totalCount,
      ),
      initialData: initialRows,
      columns: [
        const GridColumn(id: 'id', label: 'Order ID', initialWidth: 120),
        const GridColumn(id: 'customer', label: 'Customer', initialWidth: 160),
        const GridColumn(id: 'amount', label: 'Amount', initialWidth: 110),
        const GridColumn(id: 'status', label: 'Status', initialWidth: 130),
        const GridColumn(id: 'channel', label: 'Sales Channel', initialWidth: 150),
      ],
    );
  }

  List<Map<String, dynamic>> _getPageSlice(int page, int limit) {
    final start = (page - 1) * limit;
    final end = math.min(start + limit, _totalCount);
    if (start >= _totalCount) return [];
    return _mockDatabase.sublist(start, end);
  }

  void _goToPage(int targetPage) {
    final totalPages = (_totalCount / _pageSize).ceil();
    if (targetPage < 1 || targetPage > totalPages || targetPage == _currentPage) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      final newRows = _getPageSlice(targetPage, _pageSize);
      setState(() {
        _currentPage = targetPage;
        _isLoading = false;
        _controller.setPageData(
          rows: newRows,
          pagination: GridPaginationInfo(
            page: _currentPage,
            limit: _pageSize,
            totalCount: _totalCount,
          ),
        );
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    });
  }

  void _onPageSizeChanged(int newSize) {
    if (newSize == _pageSize) return;
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      final newRows = _getPageSlice(1, _pageSize);
      setState(() {
        _isLoading = false;
        _controller.setPageData(
          rows: newRows,
          pagination: GridPaginationInfo(
            page: 1,
            limit: _pageSize,
            totalCount: _totalCount,
          ),
        );
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalCount / _pageSize).ceil();
    final startItem = (_currentPage - 1) * _pageSize + 1;
    final endItem = math.min(_currentPage * _pageSize, _totalCount);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDemoHeader(
            title: 'Data Ingestion: Discrete Pagination (REQ-DATA-01)',
            subtitle: 'Discrete page navigation with page, limit, and total count metadata managed via GridPaginationInfo.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor.withAlpha(40)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Showing $startItem–$endItem of $_totalCount orders',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Text('Page size: ', style: TextStyle(fontSize: 12)),
                  DropdownButton<int>(
                    value: _pageSize,
                    isDense: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 20, child: Text('20')),
                      DropdownMenuItem(value: 25, child: Text('25')),
                    ],
                    onChanged: _isLoading ? null : (v) {
                      if (v != null) _onPageSizeChanged(v);
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.first_page, size: 20),
                    tooltip: 'First Page',
                    onPressed: (_currentPage > 1 && !_isLoading) ? () => _goToPage(1) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    tooltip: 'Previous Page',
                    onPressed: (_currentPage > 1 && !_isLoading) ? () => _goToPage(_currentPage - 1) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Page $_currentPage of $totalPages',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    tooltip: 'Next Page',
                    onPressed: (_currentPage < totalPages && !_isLoading) ? () => _goToPage(_currentPage + 1) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page, size: 20),
                    tooltip: 'Last Page',
                    onPressed: (_currentPage < totalPages && !_isLoading) ? () => _goToPage(totalPages) : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                AppGrid<Map<String, dynamic>>(
                  controller: _controller,
                  verticalScrollController: _scrollController,
                  cellBuilder: (context, order, info, colId) {
                    if (colId == 'status') {
                      final status = order['status'] as String;
                      final isCompleted = status == 'Delivered';
                      final isPending = status == 'Processing' || status == 'In Transit';
                      final color = isCompleted
                          ? Colors.green
                          : (isPending ? Colors.blue : Colors.red);
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      );
                    }
                    return Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${order[colId]}', style: const TextStyle(fontSize: 13)),
                    );
                  },
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 11. Continuous Infinite Scroll Demo
class InfiniteScrollDemo extends StatefulWidget {
  const InfiniteScrollDemo({super.key});

  @override
  State<InfiniteScrollDemo> createState() => _InfiniteScrollDemoState();
}

class _InfiniteScrollDemoState extends State<InfiniteScrollDemo> {
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
        const GridColumn(id: 'index', label: '#', initialWidth: 70, pin: GridColumnPin.left),
        const GridColumn(id: 'event', label: 'Telemetry Stream Event', initialWidth: 260),
        const GridColumn(id: 'service', label: 'Service Origin', initialWidth: 160),
        const GridColumn(id: 'timestamp', label: 'Timestamp', initialWidth: 140),
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
          _buildDemoHeader(
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
              cellBuilder: (context, row, info, colId) {
                if (colId == 'index') {
                  return Container(
                    alignment: Alignment.center,
                    child: Text('${row['index']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  );
                }
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${row[colId]}', style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 11. Export Utilities Demo
class ExportUtilsDemo extends StatefulWidget {
  const ExportUtilsDemo({super.key});

  @override
  State<ExportUtilsDemo> createState() => _ExportUtilsDemoState();
}

class _ExportUtilsDemoState extends State<ExportUtilsDemo> {
  late final AppGridController<Map<String, dynamic>> _controller;
  String _exportPreview = '';

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'id': 1, 'name': 'Acme, "Widgets" Inc.', 'country': 'USA'},
        {'id': 2, 'name': 'Globex Corporation', 'country': 'Canada'},
        {'id': 3, 'name': 'Soylent, Corp', 'country': 'UK'},
      ],
      columns: [
        GridColumn(id: 'id', label: 'ID', valueGetter: (r) => r['id']),
        GridColumn(id: 'name', label: 'Company Name', valueGetter: (r) => r['name']),
        GridColumn(id: 'country', label: 'Country', valueGetter: (r) => r['country']),
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
          _buildDemoHeader(
            title: 'CSV & JSON Data Exporters (REQ-DATA-02)',
            subtitle: 'Built-in RFC 4180 CSV escaping and formatted JSON exports for active display data.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  final csv = DataGridExporter.toCsv(controller: _controller);
                  setState(() => _exportPreview = csv);
                },
                icon: const Icon(Icons.table_view, size: 16),
                label: const Text('Export to CSV (RFC 4180)'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final jsonStr = DataGridExporter.toJson(controller: _controller, pretty: true);
                  setState(() => _exportPreview = jsonStr);
                },
                icon: const Icon(Icons.code, size: 16),
                label: const Text('Export to JSON'),
              ),
            ],
          ),
          if (_exportPreview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _exportPreview,
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
              cellBuilder: (context, row, info, colId) {
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(row[colId].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildDemoHeader({required String title, required String subtitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
    ],
  );
}

// ==================== CODE SNIPPET PANEL (RIGHT SIDE) ====================

class CodeSnippetPanel extends StatefulWidget {
  final GridFeature feature;

  const CodeSnippetPanel({super.key, required this.feature});

  @override
  State<CodeSnippetPanel> createState() => _CodeSnippetPanelState();
}

class _CodeSnippetPanelState extends State<CodeSnippetPanel> {
  bool _copied = false;

  void _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = _getCodeForFeature(widget.feature);

    return Container(
      color: const Color(0xFF18181B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF27272A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.code, color: Colors.lightBlueAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.feature.title} • Code Snippet',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _copied ? Colors.green : const Color(0xFF3F3F46),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => _copyCode(code),
                  icon: Icon(_copied ? Icons.check : Icons.copy, size: 14),
                  label: Text(_copied ? 'Copied!' : 'Copy Code', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Scrollable Code Display
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: Color(0xFFE4E4E7),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCodeForFeature(GridFeature feat) {
    switch (feat) {
      case GridFeature.quickstart:
        return '''import 'package:flutter/material.dart';
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
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(row[colId]?.toString() ?? ''),
        );
      },
    );
  }
}''';

      case GridFeature.modularBuilders:
        return r'''// Custom Data Model (e.g. List<FruitData>)
class FruitData {
  final String name;
  final String category;
  final int total;
  final double price;
  final String? note;

  const FruitData({
    required this.name,
    required this.category,
    required this.total,
    required this.price,
    this.note,
  });
}

// 1. Controller with Modular Column Builders & Footer Summaries:
final controller = AppGridController<FruitData>(
  initialData: fruits,
  columns: [
    GridColumn(
      id: 'name',
      label: 'Fruit Name',
      // Declarative footer summary:
      footerBuilder: GridFooter.count(prefix: 'Total: ', suffix: ' types'),
    ),
    GridColumn(
      id: 'total',
      label: 'Total Stock',
      // Declarative 1-line column sum calculation:
      footerBuilder: GridFooter.sum<FruitData>((f) => f.total, prefix: 'Sum: ', suffix: ' pcs'),
    ),
    GridColumn(
      id: 'price',
      label: 'Unit Price',
      // Declarative average calculation:
      footerBuilder: GridFooter.average<FruitData>((f) => f.price, prefix: 'Avg: \$', precision: 2),
    ),
    GridColumn(
      id: 'note',
      label: 'Quality / Note',
      valueGetter: (f) => (f as FruitData).note, // Null values automatically render EmptyCell ('—')
    ),
  ],
  // Controller-level modular cell builders:
  cellBuilders: {
    'name': (context, fruit, info) => Row(
      children: [
        const Icon(Icons.eco, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Text(fruit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
    'total': (context, fruit, info) => Text('${fruit.total} pcs'),
  },
);

// 2. High-Performance AppGrid with Built-In Addons:
AppGrid<FruitData>(
  controller: controller,
  showPaginationBar: true, // Integrated production-ready pagination bar
  emptyWidget: const AppGridEmptyWidget(
    message: 'No fruit records found. Try adjusting filters or reload data.',
  ),
  // Tip: Right-click any column header to freeze to left/right or unpin!
);''';

      case GridFeature.largeDataset:
        return '''// AC-01: 2D Virtualization for 100,000 Rows x 50 Columns
final controller = AppGridController<int>(
  initialData: List.generate(100000, (i) => i),
  columns: List.generate(
    50,
    (c) => GridColumn(
      id: 'col_\$c',
      label: 'Column \$c',
      initialWidth: 110,
      pin: c == 0 ? GridColumnPin.left : GridColumnPin.none,
    ),
  ),
);

// Only visible rows (+1 buffer) exist in the Flutter widget tree.
AppGrid<int>(
  controller: controller,
  rowHeight: 40.0,
  cellBuilder: (context, rowIndex, info, colId) {
    return Text('R\$rowIndex \$colId');
  },
);''';

      case GridFeature.realtimeStreaming:
        return '''// AC-02: High-Frequency Streaming Ticks (60 FPS)
// Cells update directly without rebuilding root AppGrid widget.

final controller = AppGridController<StockQuote>(
  initialData: quotes,
  columns: [...],
);

// Streaming tick updates:
void onTickReceived(int rowIndex, StockQuote updatedQuote) {
  // Directly updates row in dataset and notifies only affected cells
  controller.updateRow(rowIndex, updatedQuote);
}

// Or batch multiple ticks together:
void onBatchReceived(Map<int, StockQuote> batch) {
  // Automatically coalesced to the next frame via SchedulerBinding
  controller.batchUpdateRows(batch);
}''';

      case GridFeature.rowHelpers:
        return '''// Developer Row & Batch Mutation Helpers:
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

      case GridFeature.columnFreezing:
        return '''// REQ-COL-01: Freeze left or right columns
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

      case GridFeature.columnManipulation:
        return '''// REQ-COL-02 & REQ-COL-03:
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

      case GridFeature.autoStretch:
        return '''// REQ-COL-05 & AC-06: Auto-Stretch Rules
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

      case GridFeature.selectionAndKeyboard:
        return '''// REQ-SEL-01, REQ-SEL-02 & REQ-NAV-01:
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

      case GridFeature.statePersistence:
        return '''// REQ-STATE-01, 02, 03 & AC-05: State Persistence
// STRICT INVARIANT: Column widths are NEVER saved to persistence.

// 1. Export state (strictly: columnOrder, sortCriteria, columnVisibility)
final GridState state = controller.exportState();
final String jsonString = state.toJson();
// jsonString contains NO 'width' or 'columnWidth' keys!

// 2. Restore state:
final GridState importedState = GridState.fromJson(jsonString);
controller.restoreState(importedState);''';

      case GridFeature.pagination:
        return '''// REQ-DATA-01: Discrete Pagination Mode
// Manage discrete pages with page index, page size, and total record count.

// 1. Initialize controller with pagination metadata
final controller = AppGridController<Order>(
  fetchMode: DataFetchMode.pagination,
  paginationInfo: const GridPaginationInfo(
    page: 1,
    limit: 10,
    totalCount: 120,
  ),
  initialData: initialOrders,
  columns: [
    GridColumn(id: 'id', label: 'Order ID', initialWidth: 120),
    GridColumn(id: 'customer', label: 'Customer', initialWidth: 160),
    GridColumn(id: 'amount', label: 'Amount', initialWidth: 110),
    GridColumn(id: 'status', label: 'Status', initialWidth: 130),
  ],
);

// 2. Switching pages or changing page size:
void onPageChanged(int targetPage, int pageSize) async {
  // Fetch slice from API or backend database
  final response = await api.fetchOrders(page: targetPage, limit: pageSize);

  // Updates rows and paginationInfo in a single reactive notification:
  controller.setPageData(
    rows: response.orders,
    pagination: GridPaginationInfo(
      page: targetPage,
      limit: pageSize,
      totalCount: response.totalOrders,
    ),
  );
}

// 3. Mount in AppGrid:
AppGrid<Order>(
  controller: controller,
  cellBuilder: (context, order, info, colId) {
    return Text('\${order.toMap()[colId]}');
  },
);''';

      case GridFeature.infiniteScroll:
        return '''// REQ-DATA-01: Continuous Infinite Scroll Mode
// Automatically triggers lazy loading when user scrolls past 80% extent.

final controller = AppGridController<TelemetryEvent>(
  fetchMode: DataFetchMode.infiniteScroll,
  initialData: initialBatch,
  columns: [
    GridColumn(id: 'index', label: '#', initialWidth: 70, pin: GridColumnPin.left),
    GridColumn(id: 'event', label: 'Telemetry Stream Event', initialWidth: 260),
    GridColumn(id: 'service', label: 'Service Origin', initialWidth: 160),
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
  cellBuilder: (context, event, info, colId) {
    return Text('\${event.getField(colId)}');
  },
);''';

      case GridFeature.exportUtils:
        return '''// REQ-DATA-02: CSV & JSON Exporters

// 1. Export active sorted/filtered display data to CSV (RFC 4180)
final String csv = DataGridExporter.toCsv(
  controller: controller,
  includeHeaders: true,
  delimiter: ',',
);

// 2. Export active display data to JSON
final String jsonString = DataGridExporter.toJson(
  controller: controller,
  pretty: true,
);''';
    }
  }
}
