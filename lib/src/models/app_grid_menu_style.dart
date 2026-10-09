import 'package:flutter/material.dart';

/// Styling and layout configuration for the [AppGrid] column header context menu.
///
/// Encapsulates dimensions, typography, spacing, elevations, and visual styling
/// for the header popup menu with built-in presets such as [AppGridMenuStyle.compact]
/// tailored for desktop displays and compact column layouts.
class AppGridMenuStyle {
  /// Height of individual menu items in logical pixels.
  /// Defaults to 48.0 ([kMinInteractiveDimension]) in the default constructor, and 28.0 in [compact].
  final double itemHeight;

  /// Internal padding for each menu item row.
  /// Defaults to horizontal 16.0, and horizontal 10.0, vertical 2.0 in [compact].
  final EdgeInsets itemPadding;

  /// Text style applied to menu item labels.
  final TextStyle? textStyle;

  /// Icon size for menu item icons (sort, pin, clear, etc.).
  /// If null, falls back to [AppGridStyle.iconSize].
  final double? iconSize;

  /// Optional width and height constraints on the popup menu surface.
  /// In [compact], constrained between 160.0 and 220.0 logical pixels.
  final BoxConstraints? constraints;

  /// Optional background color of the popup menu card.
  final Color? backgroundColor;

  /// Optional elevation / shadow depth of the popup menu card.
  final double? elevation;

  /// Optional corner radius for the popup menu card.
  final BorderRadius? borderRadius;

  /// Optional border outlining the popup menu card.
  final BorderSide? borderSide;

  /// Vertical space occupied by dividers between menu sections.
  /// Defaults to 12.0 in the default constructor, and 6.0 in [compact].
  final double dividerHeight;

  /// Optional custom color for menu dividers.
  final Color? dividerColor;

  /// Default menu styling matching Flutter's standard Material popup menu dimensions.
  const AppGridMenuStyle({
    this.itemHeight = kMinInteractiveDimension,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.textStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
    this.iconSize,
    this.constraints,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.borderSide,
    this.dividerHeight = 16.0,
    this.dividerColor,
  });

  /// Dense, compact preset designed specifically for desktop views and narrow columns.
  ///
  /// Shrinks item height to 28.0px, item padding to 10.0px, dividers to 6.0px,
  /// limits width between 160–220px, and applies crisp 6.0px rounded corners.
  const AppGridMenuStyle.compact({
    this.itemHeight = 28.0,
    this.itemPadding =
        const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
    this.textStyle =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
    this.iconSize = 14.0,
    this.constraints = const BoxConstraints(minWidth: 160.0, maxWidth: 220.0),
    this.backgroundColor,
    this.elevation = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(6.0)),
    this.borderSide,
    this.dividerHeight = 6.0,
    this.dividerColor,
  });

  /// Creates a copy of this menu style with the specified properties replaced.
  AppGridMenuStyle copyWith({
    double? itemHeight,
    EdgeInsets? itemPadding,
    TextStyle? textStyle,
    double? iconSize,
    BoxConstraints? constraints,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
    BorderSide? borderSide,
    double? dividerHeight,
    Color? dividerColor,
  }) {
    return AppGridMenuStyle(
      itemHeight: itemHeight ?? this.itemHeight,
      itemPadding: itemPadding ?? this.itemPadding,
      textStyle: textStyle ?? this.textStyle,
      iconSize: iconSize ?? this.iconSize,
      constraints: constraints ?? this.constraints,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      borderRadius: borderRadius ?? this.borderRadius,
      borderSide: borderSide ?? this.borderSide,
      dividerHeight: dividerHeight ?? this.dividerHeight,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppGridMenuStyle &&
          runtimeType == other.runtimeType &&
          itemHeight == other.itemHeight &&
          itemPadding == other.itemPadding &&
          textStyle == other.textStyle &&
          iconSize == other.iconSize &&
          constraints == other.constraints &&
          backgroundColor == other.backgroundColor &&
          elevation == other.elevation &&
          borderRadius == other.borderRadius &&
          borderSide == other.borderSide &&
          dividerHeight == other.dividerHeight &&
          dividerColor == other.dividerColor;

  @override
  int get hashCode => Object.hash(
        itemHeight,
        itemPadding,
        textStyle,
        iconSize,
        constraints,
        backgroundColor,
        elevation,
        borderRadius,
        borderSide,
        dividerHeight,
        dividerColor,
      );

  @override
  String toString() {
    return 'AppGridMenuStyle(itemHeight: $itemHeight, itemPadding: $itemPadding, '
        'textStyle: $textStyle, iconSize: $iconSize, dividerHeight: $dividerHeight)';
  }
}
