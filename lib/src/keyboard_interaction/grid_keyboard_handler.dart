import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/app_grid_controller.dart';

/// Keyboard interaction listener for [AppGrid] complying with REQ-NAV-01 and AC-04.
///
/// Supports:
/// - [LogicalKeyboardKey.arrowUp] / [LogicalKeyboardKey.arrowDown]: step selection by 1 row.
/// - [LogicalKeyboardKey.home]: jump to first visual row.
/// - [LogicalKeyboardKey.end]: jump to last visual row.
/// - [LogicalKeyboardKey.pageUp] / [LogicalKeyboardKey.pageDown]: jump selection by count of visible rows.
class GridKeyboardHandler<T> extends StatefulWidget {
  final AppGridController<T> controller;
  final ScrollController verticalScrollController;
  final double viewportHeight;
  final double rowHeight;
  final FocusNode focusNode;
  final Widget child;
  final bool autofocus;
  final bool readOnly;
  final DateTime Function()? clock;

  const GridKeyboardHandler({
    super.key,
    required this.controller,
    required this.verticalScrollController,
    required this.viewportHeight,
    required this.rowHeight,
    required this.focusNode,
    required this.child,
    this.autofocus = false,
    this.readOnly = false,
    this.clock,
  });

  @override
  State<GridKeyboardHandler<T>> createState() => _GridKeyboardHandlerState<T>();
}

class _GridKeyboardHandlerState<T> extends State<GridKeyboardHandler<T>> {
  int _lastStepTime = 0;

  DateTime get _now => widget.clock != null ? widget.clock!() : DateTime.now();

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.readOnly || widget.controller.isReadOnly) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final rowCount = widget.controller.displayRowCount;
    if (rowCount == 0) return KeyEventResult.ignored;

    final visibleRowCount = math.max(1, (widget.viewportHeight / widget.rowHeight).floor());
    final currentDisplayIndex = widget.controller.selectedDisplayIndex;

    int? targetIndex;
    final key = event.logicalKey;

    final isMetaOrCtrl = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    final isHome = key == LogicalKeyboardKey.home ||
        key == LogicalKeyboardKey.numpad7 ||
        (isMetaOrCtrl && key == LogicalKeyboardKey.arrowUp);

    final isEnd = key == LogicalKeyboardKey.end ||
        key == LogicalKeyboardKey.numpad1 ||
        (isMetaOrCtrl && key == LogicalKeyboardKey.arrowDown);

    final isArrowDown = key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.numpad2;

    final isArrowUp = key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.numpad8;

    final isPageDown = key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.numpad3;

    final isPageUp = key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.numpad9;

    // Smooth Key Repeat Rate Pacing:
    // When holding an arrow key, the OS generates repeat events at 30-60 Hz (every 16-33ms).
    // Without pacing, multiple key repeats collapse into single frames, causing the selection
    // to skip rows (e.g. jumping 2-4 rows at a time) and feel laggy.
    // By pacing repeat events to ~45ms for row stepping (~22 rows/sec), every single row
    // is rendered and stepped 1-by-1 smoothly without any frame jumps or skipped rows.
    if (event is KeyRepeatEvent) {
      final now = _now.millisecondsSinceEpoch;
      final minInterval = (isPageDown || isPageUp) ? 140 : 45;
      if (now - _lastStepTime < minInterval) {
        return KeyEventResult.handled;
      }
      _lastStepTime = now;
    } else if (event is KeyDownEvent) {
      _lastStepTime = _now.millisecondsSinceEpoch;
    }

    if (isHome) {
      targetIndex = 0;
    } else if (isEnd) {
      targetIndex = rowCount - 1;
    } else if (isArrowDown) {
      if (currentDisplayIndex == null) {
        targetIndex = 0;
      } else {
        targetIndex = math.min(rowCount - 1, currentDisplayIndex + 1);
      }
    } else if (isArrowUp) {
      if (currentDisplayIndex == null) {
        targetIndex = rowCount - 1;
      } else {
        targetIndex = math.max(0, currentDisplayIndex - 1);
      }
    } else if (isPageDown) {
      final base = currentDisplayIndex ?? 0;
      targetIndex = math.min(rowCount - 1, base + visibleRowCount);
    } else if (isPageUp) {
      final base = currentDisplayIndex ?? 0;
      targetIndex = math.max(0, base - visibleRowCount);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (currentDisplayIndex != null) {
        widget.controller.selectRow(currentDisplayIndex);
        return KeyEventResult.handled;
      }
    }

    if (targetIndex != null) {
      widget.controller.selectRow(targetIndex);
      _scrollIntoView(targetIndex);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollIntoView(int displayIndex) {
    if (!widget.verticalScrollController.hasClients || widget.viewportHeight <= 0) return;

    final targetOffset = displayIndex * widget.rowHeight;
    final currentOffset = widget.verticalScrollController.offset;
    final maxVisibleOffset = currentOffset + widget.viewportHeight - widget.rowHeight;

    final position = widget.verticalScrollController.position;
    final minScroll = position.minScrollExtent;
    final maxScroll = position.maxScrollExtent;

    if (targetOffset < currentOffset) {
      // Row is above current view -> scroll up
      widget.verticalScrollController.jumpTo(targetOffset.clamp(minScroll, maxScroll));
    } else if (targetOffset > maxVisibleOffset) {
      // Row is below current view -> scroll down
      final newOffset = targetOffset - widget.viewportHeight + widget.rowHeight;
      widget.verticalScrollController.jumpTo(newOffset.clamp(minScroll, maxScroll));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (!widget.focusNode.hasFocus) {
            widget.focusNode.requestFocus();
          }
        },
        child: widget.child,
      ),
    );
  }
}
