import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_state.dart';

class HiToast {
  static void show(BuildContext context, String message, {IconData? icon}) {
    final container = ProviderScope.containerOf(context, listen: false);
    final theme = container.read(themeProvider);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: theme.tabActiveText),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: theme.tabActiveText,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.tabActiveBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.panelBorderInactive),
        ),
        width: 280,
        duration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  /// Show a toast with a copyable path — stays longer, has copy button
  static void showPath(BuildContext context, String label, String path,
      {IconData? icon}) {
    final container = ProviderScope.containerOf(context, listen: false);
    final theme = container.read(themeProvider);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: theme.statusBarAccent),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: theme.tabActiveText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.panelBorderInactive),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      path,
                      style: TextStyle(
                        color: theme.statusBarForeground,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CopyButton(path: path, theme: theme),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: theme.tabActiveBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.panelBorderInactive),
        ),
        width: 420,
        duration: const Duration(seconds: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String path;
  final dynamic theme;
  const _CopyButton({required this.path, required this.theme});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: widget.path));
          setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _copied = false);
          });
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: _copied
              ? const Icon(Icons.check, key: ValueKey('check'), size: 16, color: Colors.green)
              : Icon(Icons.copy, key: const ValueKey('copy'), size: 14, color: widget.theme.textDim),
        ),
      ),
    );
  }
}
