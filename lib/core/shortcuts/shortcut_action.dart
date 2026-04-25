import 'package:flutter/services.dart';

class AppAction {
  final String id;
  final String label;
  final String? shortcutLabel;
  final void Function() execute;

  const AppAction({
    required this.id,
    required this.label,
    this.shortcutLabel,
    required this.execute,
  });
}

/// Format a key combination for display
String formatShortcut(LogicalKeyboardKey key,
    {bool control = false, bool shift = false, bool alt = false}) {
  final parts = <String>[];
  if (control) parts.add('Ctrl');
  if (shift) parts.add('Shift');
  if (alt) parts.add('Alt');
  parts.add(key.keyLabel);
  return parts.join('+');
}
