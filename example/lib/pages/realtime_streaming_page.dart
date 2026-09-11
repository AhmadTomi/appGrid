import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class RealtimeStreamingPage extends StatefulWidget {
  const RealtimeStreamingPage({super.key});

  @override
  State<RealtimeStreamingPage> createState() => _RealtimeStreamingPageState();
}

typedef RealtimeStreamingDemo = RealtimeStreamingPage;

class _RealtimeStreamingPageState extends State<RealtimeStreamingPage> {
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
        GridColumn(
          id: 'change',
          label: 'Delta',
          initialWidth: 120,
          valueGetter: (r) => r['change'],
          cellBuilder: (context, item, info) {
            final delta = item['change'] as double;
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
          },
        ),
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
          buildDemoHeader(
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
              scrollbarVisibility: AppGridScrollbarVisibility.onHover,
            ),
          ),
        ],
      ),
    );
  }
}

const String realtimeStreamingSnippet = '''// AC-02: High-Frequency Streaming Ticks (60 FPS)
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
