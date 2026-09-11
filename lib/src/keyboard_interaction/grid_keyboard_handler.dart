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
class GridKeyboardHandler<T> extends StatelessWidget {
  final AppGridController<T> controller;
  final ScrollController verticalScrollController;
  final double viewportHeight;
  final double rowHeight;
  final FocusNode focusNode;
  final Widget child;
  final bool autofocus;
  final bool readOnly;

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
  });

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (readOnly || controller.isReadOnly) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final rowCount = controller.displayRowCount;
    if (rowCount == 0) return KeyEventResult.ignored;

    final visibleRowCount = math.max(1, (viewportHeight / rowHeight).floor());
    final currentDisplayIndex = controller.selectedDisplayIndex;

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
        controller.selectRow(currentDisplayIndex);
        return KeyEventResult.handled;
      }
    }

    if (targetIndex != null) {
      controller.selectRow(targetIndex);
      _scrollIntoView(targetIndex);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollIntoView(int displayIndex) {
    if (!verticalScrollController.hasClients || viewportHeight <= 0) return;

    final targetOffset = displayIndex * rowHeight;
    final currentOffset = verticalScrollController.offset;
    final maxVisibleOffset = currentOffset + viewportHeight - rowHeight;

    final position = verticalScrollController.position;
    final minScroll = position.minScrollExtent;
    final maxScroll = position.maxScrollExtent;

    if (targetOffset < currentOffset) {
      // Row is above current view -> scroll up
      verticalScrollController.jumpTo(targetOffset.clamp(minScroll, maxScroll));
    } else if (targetOffset > maxVisibleOffset) {
      // Row is below current view -> scroll down
      final newOffset = targetOffset - viewportHeight + rowHeight;
      verticalScrollController.jumpTo(newOffset.clamp(minScroll, maxScroll));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (!focusNode.hasFocus) {
            focusNode.requestFocus();
          }
        },
        child: child,
      ),
    );
  }
}
