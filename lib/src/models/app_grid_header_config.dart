/// Modular configuration for column header features and behaviors in [AppGrid].
///
/// Controls individual header interactions such as sorting, context menu,
/// drag-reordering, drag-resizing, auto-fit, and icon visibility.
class AppGridHeaderConfig {
  /// Whether clicking the column header triggers sorting.
  final bool enableSort;

  /// Whether clicking the header icon opens the context menu.
  final bool enableMenu;

  /// Whether columns can be reordered via drag-and-drop.
  final bool enableReorder;

  /// Whether columns can be resized by dragging their borders.
  final bool enableResize;

  /// Whether header icons (menu '≡' or sort indicators) are rendered.
  final bool showIcon;

  /// Whether double-clicking the column edge auto-fits width to content.
  final bool enableAutoFit;

  /// Standard configuration with all header features and icons enabled.
  const AppGridHeaderConfig({
    this.enableSort = true,
    this.enableMenu = true,
    this.enableReorder = true,
    this.enableResize = true,
    this.showIcon = true,
    this.enableAutoFit = true,
  });

  /// Minimal/simple header preset: disables sorting, context menu, reordering,
  /// and icons, keeping ONLY column resizing and auto-fit enabled.
  const AppGridHeaderConfig.simple({
    this.enableResize = true,
    this.enableAutoFit = true,
    this.enableSort = false,
    this.enableMenu = false,
    this.enableReorder = false,
    this.showIcon = false,
  });

  /// Creates a copy of this header configuration with the given fields replaced.
  AppGridHeaderConfig copyWith({
    bool? enableSort,
    bool? enableMenu,
    bool? enableReorder,
    bool? enableResize,
    bool? showIcon,
    bool? enableAutoFit,
  }) {
    return AppGridHeaderConfig(
      enableSort: enableSort ?? this.enableSort,
      enableMenu: enableMenu ?? this.enableMenu,
      enableReorder: enableReorder ?? this.enableReorder,
      enableResize: enableResize ?? this.enableResize,
      showIcon: showIcon ?? this.showIcon,
      enableAutoFit: enableAutoFit ?? this.enableAutoFit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppGridHeaderConfig &&
          runtimeType == other.runtimeType &&
          enableSort == other.enableSort &&
          enableMenu == other.enableMenu &&
          enableReorder == other.enableReorder &&
          enableResize == other.enableResize &&
          showIcon == other.showIcon &&
          enableAutoFit == other.enableAutoFit;

  @override
  int get hashCode => Object.hash(
        enableSort,
        enableMenu,
        enableReorder,
        enableResize,
        showIcon,
        enableAutoFit,
      );
}
