import 'package:flutter/material.dart';

/// An ultra-lightweight, high-performance button widget designed specifically for
/// virtualized data grid cells, streaming rows, and high-frequency tables.
///
/// Unlike standard Material buttons ([ElevatedButton], [FilledButton]), [AppGridButton]:
/// - Does NOT register or traverse the Flutter [Focus] / [FocusNode] tree.
/// - Does NOT perform deep [Theme] / [ButtonStyle] cascade evaluations.
/// - Does NOT allocate [InkFeature] canvas layers or ticker animation controllers.
/// - Provides desktop/web UX: tactile hover highlight, click/press feedback,
///   customizable colors, and crisp borders.
class AppGridButton extends StatefulWidget {
  /// The text label displayed inside the button.
  final String? text;

  /// Optional icon widget displayed before the label.
  final Widget? icon;

  /// Optional custom child widget (overrides [text] and [icon]).
  final Widget? child;

  /// Callback invoked when the button is clicked.
  final VoidCallback? onPressed;

  /// Base background color. If null, defaults to theme primary color with subtle tint.
  final Color? color;

  /// Background color when hovered with a mouse pointer.
  final Color? hoverColor;

  /// Background color while being clicked/pressed down.
  final Color? pressedColor;

  /// Foreground text and icon color.
  final Color? foregroundColor;

  /// Optional border color.
  final Color? borderColor;

  /// Border radius of the button. Defaults to 4.0.
  final BorderRadius? borderRadius;

  /// Optional fixed width.
  final double? width;

  /// Fixed height of the button. Defaults to 26.0 (compact for grid rows).
  final double height;

  /// Internal padding. Defaults to `horizontal: 10, vertical: 4`.
  final EdgeInsetsGeometry padding;

  /// Optional custom text style.
  final TextStyle? textStyle;

  /// Whether the button is disabled.
  final bool disabled;

  const AppGridButton({
    super.key,
    this.text,
    this.icon,
    this.child,
    this.onPressed,
    this.color,
    this.hoverColor,
    this.pressedColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.width,
    this.height = 26.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
    this.textStyle,
    this.disabled = false,
  });

  @override
  State<AppGridButton> createState() => _AppGridButtonState();
}

class _AppGridButtonState extends State<AppGridButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _handleTap() {
    if (!widget.disabled) {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final isInteractive = !widget.disabled && widget.onPressed != null;

    // Resolved colors with zero Theme cascade overhead
    final Color defaultBg = widget.color ??
        (isDark ? primary.withAlpha(45) : primary.withAlpha(25));
    final Color hoverBg = widget.hoverColor ??
        (isDark ? primary.withAlpha(80) : primary.withAlpha(50));
    final Color pressedBg = widget.pressedColor ??
        (isDark ? primary.withAlpha(120) : primary.withAlpha(85));
    final Color defaultFg = widget.foregroundColor ??
        (isDark ? theme.colorScheme.onSurface : primary);

    Color bg;
    if (widget.disabled) {
      bg = isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000);
    } else if (_isPressed) {
      bg = pressedBg;
    } else if (_isHovered) {
      bg = hoverBg;
    } else {
      bg = defaultBg;
    }

    final Color defaultBorder = widget.borderColor ??
        (widget.disabled
            ? Colors.transparent
            : (isDark ? primary.withAlpha(70) : primary.withAlpha(90)));

    final radius = widget.borderRadius ?? BorderRadius.circular(4.0);

    Widget content;
    if (widget.child != null) {
      content = widget.child!;
    } else {
      final children = <Widget>[];
      if (widget.icon != null) {
        if (widget.icon is Icon) {
          final ic = widget.icon as Icon;
          children.add(
            Icon(
              ic.icon,
              size: ic.size ?? 14.0,
              color: ic.color ?? (widget.disabled ? defaultFg.withAlpha(100) : defaultFg),
            ),
          );
        } else {
          children.add(
            IconTheme(
              data: IconThemeData(
                size: 14.0,
                color: widget.disabled ? defaultFg.withAlpha(100) : defaultFg,
              ),
              child: widget.icon!,
            ),
          );
        }
        if (widget.text != null) {
          children.add(const SizedBox(width: 6.0));
        }
      }
      if (widget.text != null) {
        children.add(
          Text(
            widget.text!,
            style: widget.textStyle ??
                TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.disabled ? defaultFg.withAlpha(100) : defaultFg,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    }

    return MouseRegion(
      cursor: isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (isInteractive && !_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (_isHovered || _isPressed) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isInteractive ? _handleTap : null,
        onTapDown: (_) {
          if (isInteractive && !_isPressed) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        onTapCancel: () {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(
              color: _isPressed
                  ? (widget.borderColor ?? primary)
                  : defaultBorder,
              width: 1.0,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
