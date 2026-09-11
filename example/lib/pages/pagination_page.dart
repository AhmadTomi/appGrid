import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class PaginationPage extends StatefulWidget {
  const PaginationPage({super.key});

  @override
  State<PaginationPage> createState() => _PaginationPageState();
}

typedef PaginationDemo = PaginationPage;

class _PaginationPageState extends State<PaginationPage> {
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
        GridColumn(id: 'id', label: 'Order ID', initialWidth: 120, valueGetter: (r) => r['id']),
        GridColumn(id: 'customer', label: 'Customer', initialWidth: 160, valueGetter: (r) => r['customer']),
        GridColumn(id: 'amount', label: 'Amount', initialWidth: 110, valueGetter: (r) => r['amount']),
        GridColumn(
          id: 'status',
          label: 'Status',
          initialWidth: 130,
          valueGetter: (r) => r['status'],
          cellBuilder: (context, order, info) {
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
          },
        ),
        GridColumn(id: 'channel', label: 'Sales Channel', initialWidth: 150, valueGetter: (r) => r['channel']),
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
          buildDemoHeader(
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

const String paginationSnippet = '''// REQ-DATA-01: Discrete Pagination Mode
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
);''';
