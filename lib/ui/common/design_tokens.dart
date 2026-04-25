import 'package:flutter/material.dart';

/// Centralized design tokens for consistent spacing, sizing, typography,
/// and animation across all HiTerminal UI components.

class HiSpacing {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
}

class HiSizing {
  // Bar heights
  static const double statusBarHeight = 28;
  static const double tabBarHeight = 36;
  static const double panelTitleHeight = 28;
  static const double panelFooterHeight = 20;

  // Divider
  static const double dividerThickness = 6.0;
  static const double dividerVisual = 4.0;
  static const double dividerHitTarget = 12.0;
  static const double dividerGripLength = 24.0;
  static const double dividerGripWidth = 2.0;

  // Tabs
  static const double maxTabWidth = 180.0;
  static const double tabPaddingH = 12.0;

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 12.0;

  // Icons
  static const double iconXs = 10.0;
  static const double iconSm = 12.0;
  static const double iconMd = 14.0;
  static const double iconLg = 16.0;
  static const double iconXl = 18.0;
  static const double icon2xl = 20.0;

  // Window controls (Windows/Linux)
  static const double windowControlWidth = 46.0;
  static const double windowControlHeight = 30.0;

  // macOS traffic light offset
  static const double macTrafficLightWidth = 78.0;
}

class HiTypography {
  static TextStyle caption(Color color, {bool mono = false}) => TextStyle(
        fontSize: 10,
        color: color,
        fontFamily: mono ? 'monospace' : null,
      );

  static TextStyle small(Color color, {bool mono = false, FontWeight? weight}) =>
      TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: weight,
        fontFamily: mono ? 'monospace' : null,
      );

  static TextStyle body(Color color, {FontWeight? weight}) => TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: weight,
      );

  static TextStyle subtitle(Color color, {FontWeight? weight}) => TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: weight,
      );

  static TextStyle title(Color color) => TextStyle(
        fontSize: 15,
        color: color,
        fontWeight: FontWeight.w600,
      );

  static TextStyle heading(Color color) => TextStyle(
        fontSize: 16,
        color: color,
        fontWeight: FontWeight.w700,
      );
}

class HiDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
}

class HiCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
}

/// Animated dialog helper — fade + scale transition
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  Color barrierColor = Colors.black38,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dialog',
    transitionDuration: HiDurations.normal,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: HiCurves.standard);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
