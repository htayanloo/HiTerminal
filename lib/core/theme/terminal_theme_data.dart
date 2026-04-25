import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class HiTerminalTheme {
  final String id;
  final String name;
  // Terminal colors
  final TerminalTheme terminalTheme;
  // UI colors
  final Color background;
  final Color titleBarBackground;
  final Color tabBarBackground;
  final Color tabActiveBackground;
  final Color tabHoverBackground;
  final Color tabActiveIndicator;
  final Color tabActiveText;
  final Color tabInactiveText;
  final Color statusBarBackground;
  final Color statusBarForeground;
  final Color statusBarAccent;
  final Color panelBorderActive;
  final Color panelBorderInactive;
  final Color panelTitleActive;
  final Color panelTitleInactive;
  final Color dividerColor;
  final Color dividerGrip;
  final Color dividerHover;
  final Color dividerActive;
  final Color textDim;

  const HiTerminalTheme({
    required this.id,
    required this.name,
    required this.terminalTheme,
    required this.background,
    required this.titleBarBackground,
    required this.tabBarBackground,
    required this.tabActiveBackground,
    required this.tabHoverBackground,
    required this.tabActiveIndicator,
    required this.tabActiveText,
    required this.tabInactiveText,
    required this.statusBarBackground,
    required this.statusBarForeground,
    required this.statusBarAccent,
    required this.panelBorderActive,
    required this.panelBorderInactive,
    required this.panelTitleActive,
    required this.panelTitleInactive,
    required this.dividerColor,
    required this.dividerGrip,
    required this.dividerHover,
    required this.dividerActive,
    required this.textDim,
  });
}
