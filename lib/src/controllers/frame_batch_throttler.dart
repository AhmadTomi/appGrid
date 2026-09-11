import 'package:flutter/scheduler.dart';

/// Callback invoked when buffered mutations are flushed on the frame cycle.
typedef BatchFlushCallback<M> = void Function(List<M> mutations);

/// Frame-synchronized batch throttler for streaming high-frequency grid updates.
///
/// Complies with REQ-PERF-05 and REQ-PERF-06 by queueing mutations and
/// dispatching them strictly once per display frame using [SchedulerBinding.scheduleFrameCallback].
class FrameBatchThrottler<M> {
  final BatchFlushCallback<M> onFlush;
  final List<M> _buffer = [];
  bool _isFrameScheduled = false;
  bool _isDisposed = false;

  /// Custom frame scheduler for testing or non-binding environments.
  final void Function(FrameCallback callback)? frameSchedulerOverride;

  FrameBatchThrottler({
    required this.onFlush,
    this.frameSchedulerOverride,
  });

  /// Count of currently buffered mutations awaiting the next frame flush.
  int get pendingCount => _buffer.length;

  /// Whether a frame callback is currently scheduled.
  bool get isFrameScheduled => _isFrameScheduled;

  /// Enqueues a single mutation to the buffer.
  void queue(M mutation) {
    if (_isDisposed) return;
    _buffer.add(mutation);
    _requestFrame();
  }

  /// Enqueues multiple mutations in bulk.
  void queueAll(Iterable<M> mutations) {
    if (_isDisposed) return;
    _buffer.addAll(mutations);
    _requestFrame();
  }

  /// Flushes all pending mutations synchronously.
  void flushNow() {
    if (_buffer.isEmpty || _isDisposed) return;
    final batch = List<M>.from(_buffer);
    _buffer.clear();
    _isFrameScheduled = false;
    onFlush(batch);
  }

  void _requestFrame() {
    if (_isFrameScheduled || _isDisposed) return;
    _isFrameScheduled = true;

    final scheduler = frameSchedulerOverride;
    if (scheduler != null) {
      scheduler(_onFrame);
    } else {
      SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
    }
  }

  void _onFrame(Duration timeStamp) {
    if (_isDisposed) {
      _isFrameScheduled = false;
      return;
    }
    _isFrameScheduled = false;
    if (_buffer.isEmpty) return;

    final batch = List<M>.from(_buffer);
    _buffer.clear();
    onFlush(batch);
  }

  /// Clears the buffer and cancels any pending work.
  void dispose() {
    _isDisposed = true;
    _buffer.clear();
    _isFrameScheduled = false;
  }
}
