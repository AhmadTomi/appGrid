import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Defines the visibility behavior of scrollbars in [AppGrid].
enum AppGridScrollbarVisibility {
  /// The scrollbar is visible when hovering over the table/scrollbar or during active scrolling,
  /// and smoothly fades out when idle.
  onHover,

  /// The scrollbar is always visible as long as the content exceeds the viewport.
  always,

  /// The scrollbar is completely hidden.
  hidden,
}

/// Type alias for convenience.
typedef ScrollbarVisibility = AppGridScrollbarVisibility;

/// Interactive horizontal scrollbar for [AppGrid]'s center scrollable pane.
class AppGridHorizontalScrollbar extends StatefulWidget {
  final ScrollController controller;
  final double trackWidth;
  final double contentWidth;
  final double thickness;
  final Color? thumbColor;
  final Color? trackColor;
  final AppGridScrollbarVisibility visibility;
  final ValueListenable<bool>? isParentHovered;

  const AppGridHorizontalScrollbar({
    super.key,
    required this.controller,
    required this.trackWidth,
    required this.contentWidth,
    this.thickness = 10.0,
    this.thumbColor,
    this.trackColor,
    this.visibility = AppGridScrollbarVisibility.onHover,
    this.isParentHovered,
  });

  @override
  State<AppGridHorizontalScrollbar> createState() => _AppGridHorizontalScrollbarState();
}

class _AppGridHorizontalScrollbarState extends State<AppGridHorizontalScrollbar> {
  bool _isHoveringThumb = false;
  bool _isHoveringTrack = false;
  bool _isDragging = false;
  bool _isScrolling = false;
  Timer? _scrollFadeTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    widget.isParentHovered?.addListener(_onParentHoverChanged);
  }

  @override
  void didUpdateWidget(covariant AppGridHorizontalScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
    if (oldWidget.isParentHovered != widget.isParentHovered) {
      oldWidget.isParentHovered?.removeListener(_onParentHoverChanged);
      widget.isParentHovered?.addListener(_onParentHoverChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    widget.isParentHovered?.removeListener(_onParentHoverChanged);
    _scrollFadeTimer?.cancel();
    super.dispose();
  }

  void _onParentHoverChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (widget.visibility != AppGridScrollbarVisibility.onHover) return;
    if (!mounted) return;
    _scrollFadeTimer?.cancel();
    if (!_isScrolling) {
      setState(() => _isScrolling = true);
    }
    _scrollFadeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _isScrolling) {
        setState(() => _isScrolling = false);
      }
    });
  }

  bool get _isVisible {
    switch (widget.visibility) {
      case AppGridScrollbarVisibility.hidden:
        return false;
      case AppGridScrollbarVisibility.always:
        return true;
      case AppGridScrollbarVisibility.onHover:
        return (widget.isParentHovered?.value ?? false) ||
            _isHoveringThumb ||
            _isHoveringTrack ||
            _isDragging ||
            _isScrolling;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visibility == AppGridScrollbarVisibility.hidden) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (!widget.controller.hasClients) {
          return const SizedBox.shrink();
        }

        final position = widget.controller.position;
        final maxScroll = position.maxScrollExtent;
        if (maxScroll <= 0.0 || widget.trackWidth <= 0.0) {
          return const SizedBox.shrink();
        }

        final currentScroll = widget.controller.offset.clamp(0.0, maxScroll);
        final trackWidth = widget.trackWidth;
        final contentWidth = math.max(trackWidth, widget.contentWidth);

        final thumbWidth = math.max(28.0, (trackWidth / contentWidth) * trackWidth);
        final maxThumbOffset = math.max(1.0, trackWidth - thumbWidth);
        final thumbOffset = (currentScroll / maxScroll) * maxThumbOffset;

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final trackColor = widget.trackColor ??
            (isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000));
        final baseThumbColor = widget.thumbColor ??
            (isDark ? const Color(0x66FFFFFF) : const Color(0x66000000));
        final activeThumbColor = widget.thumbColor != null
            ? widget.thumbColor!.withAlpha(220)
            : (isDark ? const Color(0x99FFFFFF) : const Color(0x99000000));

        final thumbColor = (_isDragging || _isHoveringThumb)
            ? activeThumbColor
            : baseThumbColor;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isVisible ? 1.0 : 0.0,
          curve: Curves.easeOut,
          child: SizedBox(
            width: trackWidth,
            height: widget.thickness,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final clickX = details.localPosition.dx;
                if (clickX < thumbOffset || clickX > thumbOffset + thumbWidth) {
                  final targetRatio = (clickX - thumbWidth / 2) / maxThumbOffset;
                  final targetScroll = (targetRatio * maxScroll).clamp(0.0, maxScroll);
                  widget.controller.jumpTo(targetScroll);
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track background
                  Positioned.fill(
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHoveringTrack = true),
                      onExit: (_) => setState(() => _isHoveringTrack = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: trackColor,
                          borderRadius: BorderRadius.circular(widget.thickness / 2),
                        ),
                      ),
                    ),
                  ),

                // Interactive Draggable Thumb
                Positioned(
                  left: thumbOffset,
                  top: 0,
                  bottom: 0,
                  width: thumbWidth,
                  child: MouseRegion(
                    cursor: _isDragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab,
                    onEnter: (_) => setState(() => _isHoveringThumb = true),
                    onExit: (_) => setState(() => _isHoveringThumb = false),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) {
                        setState(() => _isDragging = true);
                      },
                      onHorizontalDragUpdate: (details) {
                        final deltaScroll = (details.delta.dx / maxThumbOffset) * maxScroll;
                        final newOffset = (widget.controller.offset + deltaScroll).clamp(0.0, maxScroll);
                        widget.controller.jumpTo(newOffset);
                      },
                      onHorizontalDragEnd: (_) {
                        setState(() => _isDragging = false);
                      },
                      onHorizontalDragCancel: () {
                        setState(() => _isDragging = false);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: thumbColor,
                          borderRadius: BorderRadius.circular(widget.thickness / 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }
}

/// Interactive vertical scrollbar for [AppGrid].
class AppGridVerticalScrollbar extends StatefulWidget {
  final ScrollController controller;
  final double trackHeight;
  final double contentHeight;
  final double thickness;
  final Color? thumbColor;
  final Color? trackColor;
  final AppGridScrollbarVisibility visibility;
  final ValueListenable<bool>? isParentHovered;

  const AppGridVerticalScrollbar({
    super.key,
    required this.controller,
    required this.trackHeight,
    required this.contentHeight,
    this.thickness = 10.0,
    this.thumbColor,
    this.trackColor,
    this.visibility = AppGridScrollbarVisibility.onHover,
    this.isParentHovered,
  });

  @override
  State<AppGridVerticalScrollbar> createState() => _AppGridVerticalScrollbarState();
}

class _AppGridVerticalScrollbarState extends State<AppGridVerticalScrollbar> {
  bool _isHoveringThumb = false;
  bool _isHoveringTrack = false;
  bool _isDragging = false;
  bool _isScrolling = false;
  Timer? _scrollFadeTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    widget.isParentHovered?.addListener(_onParentHoverChanged);
  }

  @override
  void didUpdateWidget(covariant AppGridVerticalScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
    if (oldWidget.isParentHovered != widget.isParentHovered) {
      oldWidget.isParentHovered?.removeListener(_onParentHoverChanged);
      widget.isParentHovered?.addListener(_onParentHoverChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    widget.isParentHovered?.removeListener(_onParentHoverChanged);
    _scrollFadeTimer?.cancel();
    super.dispose();
  }

  void _onParentHoverChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (widget.visibility != AppGridScrollbarVisibility.onHover) return;
    if (!mounted) return;
    _scrollFadeTimer?.cancel();
    if (!_isScrolling) {
      setState(() => _isScrolling = true);
    }
    _scrollFadeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _isScrolling) {
        setState(() => _isScrolling = false);
      }
    });
  }

  bool get _isVisible {
    switch (widget.visibility) {
      case AppGridScrollbarVisibility.hidden:
        return false;
      case AppGridScrollbarVisibility.always:
        return true;
      case AppGridScrollbarVisibility.onHover:
        return (widget.isParentHovered?.value ?? false) ||
            _isHoveringThumb ||
            _isHoveringTrack ||
            _isDragging ||
            _isScrolling;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visibility == AppGridScrollbarVisibility.hidden) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (!widget.controller.hasClients) {
          return const SizedBox.shrink();
        }

        final position = widget.controller.position;
        final maxScroll = position.maxScrollExtent;
        if (maxScroll <= 0.0 || widget.trackHeight <= 0.0) {
          return const SizedBox.shrink();
        }

        final currentScroll = widget.controller.offset.clamp(0.0, maxScroll);
        final trackHeight = widget.trackHeight;
        final contentHeight = math.max(trackHeight, widget.contentHeight);

        final thumbHeight = math.max(28.0, (trackHeight / contentHeight) * trackHeight);
        final maxThumbOffset = math.max(1.0, trackHeight - thumbHeight);
        final thumbOffset = (currentScroll / maxScroll) * maxThumbOffset;

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final trackColor = widget.trackColor ??
            (isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000));
        final baseThumbColor = widget.thumbColor ??
            (isDark ? const Color(0x66FFFFFF) : const Color(0x66000000));
        final activeThumbColor = widget.thumbColor != null
            ? widget.thumbColor!.withAlpha(220)
            : (isDark ? const Color(0x99FFFFFF) : const Color(0x99000000));

        final thumbColor = (_isDragging || _isHoveringThumb)
            ? activeThumbColor
            : baseThumbColor;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isVisible ? 1.0 : 0.0,
          curve: Curves.easeOut,
          child: SizedBox(
            width: widget.thickness,
            height: trackHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final clickY = details.localPosition.dy;
                if (clickY < thumbOffset || clickY > thumbOffset + thumbHeight) {
                  final targetRatio = (clickY - thumbHeight / 2) / maxThumbOffset;
                  final targetScroll = (targetRatio * maxScroll).clamp(0.0, maxScroll);
                  widget.controller.jumpTo(targetScroll);
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track background
                  Positioned.fill(
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHoveringTrack = true),
                      onExit: (_) => setState(() => _isHoveringTrack = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: trackColor,
                          borderRadius: BorderRadius.circular(widget.thickness / 2),
                        ),
                      ),
                    ),
                  ),

                  // Interactive Draggable Thumb
                  Positioned(
                    top: thumbOffset,
                    left: 0,
                    right: 0,
                    height: thumbHeight,
                    child: MouseRegion(
                      cursor: _isDragging
                          ? SystemMouseCursors.grabbing
                          : SystemMouseCursors.grab,
                      onEnter: (_) => setState(() => _isHoveringThumb = true),
                      onExit: (_) => setState(() => _isHoveringThumb = false),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: (_) {
                          setState(() => _isDragging = true);
                        },
                        onVerticalDragUpdate: (details) {
                          final deltaScroll = (details.delta.dy / maxThumbOffset) * maxScroll;
                          final newOffset = (widget.controller.offset + deltaScroll).clamp(0.0, maxScroll);
                          widget.controller.jumpTo(newOffset);
                        },
                        onVerticalDragEnd: (_) {
                          setState(() => _isDragging = false);
                        },
                        onVerticalDragCancel: () {
                          setState(() => _isDragging = false);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: thumbColor,
                            borderRadius: BorderRadius.circular(widget.thickness / 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
