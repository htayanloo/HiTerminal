import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/terminal_theme_data.dart';
import '../../state/tab_state.dart';
import '../../state/theme_state.dart';
import 'env_viewer.dart';
import 'history_viewer.dart';
import 'toast.dart';

class PanelContextMenu {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required Offset position,
    required String panelId,
    required bool canClose,
  }) {
    final theme = ref.read(themeProvider);
    final notifier = ref.read(tabListProvider.notifier);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: theme.tabActiveBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.panelBorderInactive),
      ),
      items: [
        _menuItem('split_h', 'Split Horizontal', Icons.horizontal_split,
            'Ctrl+Shift+H', theme),
        _menuItem('split_v', 'Split Vertical', Icons.vertical_split,
            'Ctrl+Shift+E', theme),
        _divider(theme),
        _menuItem(
            'rename', 'Rename Panel', Icons.edit_outlined, null, theme),
        if (canClose)
          _menuItem('close', 'Close Panel', Icons.close, 'Ctrl+Shift+X',
              theme),
        _divider(theme),
        _menuItem('copy', 'Copy', Icons.copy_outlined, 'Ctrl+Shift+C', theme),
        _menuItem(
            'paste', 'Paste', Icons.paste_outlined, 'Ctrl+Shift+V', theme),
        _divider(theme),
        _menuItem('clear', 'Clear Terminal', Icons.cleaning_services_outlined,
            null, theme),
        _menuItem('env', 'Show Environment', Icons.settings_ethernet,
            'Ctrl+Shift+I', theme),
        _menuItem('history', 'Command History', Icons.history,
            'Ctrl+Shift+Y', theme),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'split_h':
          notifier.setActivePanel(panelId);
          notifier.splitPanel(Axis.horizontal);
        case 'split_v':
          notifier.setActivePanel(panelId);
          notifier.splitPanel(Axis.vertical);
        case 'rename':
          // Trigger rename via a callback — handled by panel title bar
          _startRename(context, ref, panelId, theme);
        case 'close':
          notifier.closePanel(panelId);
        case 'copy':
          _copySelection(context, ref, panelId);
        case 'paste':
          _pasteToTerminal(context, ref, panelId);
        case 'clear':
          _clearTerminal(ref, panelId);
          HiToast.show(context, 'Terminal cleared', icon: Icons.cleaning_services);
        case 'env':
          _showEnvDialog(context, ref, theme);
        case 'history':
          showHistoryViewer(context);
      }
    });
  }

  static PopupMenuItem<String> _menuItem(
    String value,
    String label,
    IconData icon,
    String? shortcut,
    HiTerminalTheme theme,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.tabInactiveText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.tabActiveText, fontSize: 13),
            ),
          ),
          if (shortcut != null)
            Text(
              shortcut,
              style: TextStyle(
                  color: theme.textDim, fontSize: 11, fontFamily: 'monospace'),
            ),
        ],
      ),
    );
  }

  static PopupMenuEntry<String> _divider(HiTerminalTheme theme) {
    return PopupMenuDivider(height: 1);
  }

  static void _startRename(
      BuildContext context, WidgetRef ref, String panelId, HiTerminalTheme theme) {
    final tabState = ref.read(tabListProvider);
    final currentTitle =
        tabState.activeTab.panels[panelId]?.title ?? 'Terminal';

    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: currentTitle);
        return AlertDialog(
          backgroundColor: theme.background,
          title: Text('Rename Panel',
              style: TextStyle(color: theme.tabActiveText, fontSize: 16)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: theme.tabActiveText),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.tabActiveBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              ref.read(tabListProvider.notifier).renamePanelTitle(panelId, value);
              Navigator.of(ctx).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: theme.textDim)),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(tabListProvider.notifier)
                    .renamePanelTitle(panelId, controller.text);
                Navigator.of(ctx).pop();
              },
              child:
                  Text('Rename', style: TextStyle(color: theme.statusBarAccent)),
            ),
          ],
        );
      },
    );
  }

  static void _copySelection(BuildContext context, WidgetRef ref, String panelId) {
    final tabState = ref.read(tabListProvider);
    final panel = tabState.activeTab.panels[panelId];
    if (panel == null) return;
    final text = panel.session.terminal.buffer.getText();
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      HiToast.show(context, 'Copied to clipboard', icon: Icons.copy);
    }
  }

  static void _pasteToTerminal(BuildContext context, WidgetRef ref, String panelId) async {
    final tabState = ref.read(tabListProvider);
    final panel = tabState.activeTab.panels[panelId];
    if (panel == null) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      panel.session.terminal.paste(data!.text!);
      HiToast.show(context, 'Pasted', icon: Icons.paste);
    }
  }

  static void _clearTerminal(WidgetRef ref, String panelId) {
    final tabState = ref.read(tabListProvider);
    final panel = tabState.activeTab.panels[panelId];
    if (panel == null) return;
    panel.session.terminal.write('\x1b[2J\x1b[H');
  }

  static void _showEnvDialog(
      BuildContext context, WidgetRef ref, HiTerminalTheme theme) {
    showEnvViewer(context, theme);
  }
}
