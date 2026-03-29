import 'package:flutter/material.dart';

/// Provides access to open the main app drawer and switch tabs from any descendant widget.
class DrawerScope extends InheritedWidget {
  final VoidCallback openDrawer;
  /// Optional: switch main bottom-nav tab by index (e.g. 1 = Order History).
  final void Function(int index)? switchToTab;

  const DrawerScope({
    super.key,
    required this.openDrawer,
    this.switchToTab,
    required super.child,
  });

  static DrawerScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DrawerScope>();
    assert(scope != null, 'DrawerScope not found in context');
    return scope!;
  }

  /// Returns the DrawerScope if present (e.g. when screen is a tab). Use this when the screen
  /// might be pushed as a route and thus not have DrawerScope (e.g. OrdersScreen).
  static DrawerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DrawerScope>();
  }

  @override
  bool updateShouldNotify(DrawerScope oldWidget) =>
      openDrawer != oldWidget.openDrawer || switchToTab != oldWidget.switchToTab;
}
