import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('FrameBatchThrottler Tests (REQ-PERF-05 & REQ-PERF-06)', () {
    test('Buffers mutations and flushes strictly once per frame', () {
      final List<List<String>> flushedBatches = [];
      FrameCallback? scheduledFrameCallback;

      final throttler = FrameBatchThrottler<String>(
        onFlush: (batch) => flushedBatches.add(batch),
        frameSchedulerOverride: (cb) => scheduledFrameCallback = cb,
      );

      // 100 high-frequency streaming events arrive
      for (var i = 0; i < 100; i++) {
        throttler.queue('event_$i');
      }

      expect(throttler.pendingCount, equals(100));
      expect(flushedBatches.isEmpty, isTrue);
      expect(throttler.isFrameScheduled, isTrue);

      // Simulate frame render cycle tick
      scheduledFrameCallback!(Duration.zero);

      expect(flushedBatches.length, equals(1));
      expect(flushedBatches.first.length, equals(100));
      expect(flushedBatches.first.first, equals('event_0'));
      expect(flushedBatches.first.last, equals('event_99'));
      expect(throttler.pendingCount, equals(0));
      expect(throttler.isFrameScheduled, isFalse);

      throttler.dispose();
    });

    test('flushNow() dispatches pending items synchronously', () {
      final List<List<int>> flushed = [];
      final throttler = FrameBatchThrottler<int>(
        onFlush: (batch) => flushed.add(batch),
        frameSchedulerOverride: (_) {},
      );

      throttler.queueAll([1, 2, 3]);
      expect(throttler.pendingCount, equals(3));

      throttler.flushNow();
      expect(flushed.length, equals(1));
      expect(flushed.first, equals([1, 2, 3]));
      expect(throttler.pendingCount, equals(0));

      throttler.dispose();
    });
  });
}
