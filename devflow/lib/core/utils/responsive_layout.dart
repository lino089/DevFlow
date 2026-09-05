import 'package:flutter/material.dart';

/// Screen device categories based on PRD Section 8 Breakpoint Matrix:
/// - Compact (< 600px): Mobile view (single-column stack, bottom nav bar, dropdown workspace selector)
/// - Medium (600px - 1023px): Tablet / Small Web view (collapsible drawer sidebar)
/// - Expanded (>= 1024px): Desktop / Large Web view (persistent 240px dual-pane sidebar)
enum ScreenType {
  compact,
  medium,
  expanded,
}

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context) expanded;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    required this.expanded,
  });

  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return ScreenType.expanded;
    if (width >= 600) return ScreenType.medium;
    return ScreenType.compact;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return expanded(context);
        } else if (constraints.maxWidth >= 600) {
          return medium != null ? medium!(context) : expanded(context);
        } else {
          return compact(context);
        }
      },
    );
  }
}
