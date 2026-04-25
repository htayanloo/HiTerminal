import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/terminal_theme_data.dart';
import '../../state/rtl_state.dart';
import '../../state/screen_record_state.dart';
import '../../state/settings_state.dart';
import '../../state/tab_state.dart';
import '../../state/theme_state.dart';
import '../common/command_palette.dart';
import '../common/env_viewer.dart';
import '../common/history_viewer.dart';
import '../panels/split_tree.dart';
import '../settings/settings_dialog.dart';
import 'status_bar.dart';
import 'tab_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabListProvider);
    final theme = ref.watch(themeProvider);
    final tabNotifier = ref.read(tabListProvider.notifier);
    final themeNotifier = ref.read(themeProvider.notifier);
    final rtlNotifier = ref.read(rtlEnabledProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final settings = ref.watch(settingsProvider);

    return Shortcuts(
      shortcuts: {
        // Tab shortcuts
        const SingleActivator(LogicalKeyboardKey.keyT,
            control: true, shift: true): const _NewTabIntent(),
        const SingleActivator(LogicalKeyboardKey.keyW,
            control: true, shift: true): const _CloseTabIntent(),
        const SingleActivator(LogicalKeyboardKey.tab, control: true):
            const _NextTabIntent(),
        const SingleActivator(LogicalKeyboardKey.tab,
            control: true, shift: true): const _PrevTabIntent(),
        // Split shortcuts
        const SingleActivator(LogicalKeyboardKey.keyH,
            control: true, shift: true): const _SplitHorizontalIntent(),
        const SingleActivator(LogicalKeyboardKey.keyE,
            control: true, shift: true): const _SplitVerticalIntent(),
        const SingleActivator(LogicalKeyboardKey.keyX,
            control: true, shift: true): const _ClosePanelIntent(),
        // Focus shortcuts
        const SingleActivator(LogicalKeyboardKey.bracketRight, control: true):
            const _FocusNextPanelIntent(),
        const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true):
            const _FocusPrevPanelIntent(),
        // Theme shortcut
        const SingleActivator(LogicalKeyboardKey.keyK,
            control: true, shift: true): const _CycleThemeIntent(),
        // RTL toggle
        const SingleActivator(LogicalKeyboardKey.keyR,
            control: true, shift: true): const _ToggleRtlIntent(),
        // Command palette
        const SingleActivator(LogicalKeyboardKey.keyP,
            control: true, shift: true): const _CommandPaletteIntent(),
        // Settings
        const SingleActivator(LogicalKeyboardKey.comma,
            control: true): const _SettingsIntent(),
        // Environment viewer
        const SingleActivator(LogicalKeyboardKey.keyI,
            control: true, shift: true): const _EnvViewerIntent(),
        // Font size
        const SingleActivator(LogicalKeyboardKey.equal,
            control: true): const _ZoomInIntent(),
        const SingleActivator(LogicalKeyboardKey.minus,
            control: true): const _ZoomOutIntent(),
        // History
        const SingleActivator(LogicalKeyboardKey.keyY,
            control: true, shift: true): const _HistoryIntent(),
      },
      child: Actions(
        actions: {
          _NewTabIntent: CallbackAction<_NewTabIntent>(
            onInvoke: (_) => tabNotifier.addTab(),
          ),
          _CloseTabIntent: CallbackAction<_CloseTabIntent>(
            onInvoke: (_) => tabNotifier.closeTab(tabState.activeIndex),
          ),
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (_) {
              final next = (tabState.activeIndex + 1) % tabState.tabs.length;
              tabNotifier.setActiveTab(next);
              return null;
            },
          ),
          _PrevTabIntent: CallbackAction<_PrevTabIntent>(
            onInvoke: (_) {
              final prev =
                  (tabState.activeIndex - 1 + tabState.tabs.length) %
                      tabState.tabs.length;
              tabNotifier.setActiveTab(prev);
              return null;
            },
          ),
          _SplitHorizontalIntent: CallbackAction<_SplitHorizontalIntent>(
            onInvoke: (_) => tabNotifier.splitPanel(Axis.horizontal),
          ),
          _SplitVerticalIntent: CallbackAction<_SplitVerticalIntent>(
            onInvoke: (_) => tabNotifier.splitPanel(Axis.vertical),
          ),
          _ClosePanelIntent: CallbackAction<_ClosePanelIntent>(
            onInvoke: (_) => tabNotifier.closeActivePanel(),
          ),
          _FocusNextPanelIntent: CallbackAction<_FocusNextPanelIntent>(
            onInvoke: (_) => tabNotifier.focusNextPanel(),
          ),
          _FocusPrevPanelIntent: CallbackAction<_FocusPrevPanelIntent>(
            onInvoke: (_) => tabNotifier.focusPreviousPanel(),
          ),
          _CycleThemeIntent: CallbackAction<_CycleThemeIntent>(
            onInvoke: (_) => themeNotifier.nextTheme(),
          ),
          _ToggleRtlIntent: CallbackAction<_ToggleRtlIntent>(
            onInvoke: (_) => rtlNotifier.toggle(),
          ),
          _CommandPaletteIntent: CallbackAction<_CommandPaletteIntent>(
            onInvoke: (_) {
              CommandPalette.show(context);
              return null;
            },
          ),
          _SettingsIntent: CallbackAction<_SettingsIntent>(
            onInvoke: (_) {
              SettingsDialog.show(context);
              return null;
            },
          ),
          _EnvViewerIntent: CallbackAction<_EnvViewerIntent>(
            onInvoke: (_) {
              showEnvViewer(context, theme);
              return null;
            },
          ),
          _ZoomInIntent: CallbackAction<_ZoomInIntent>(
            onInvoke: (_) =>
                settingsNotifier.setFontSize(settings.fontSize + 1),
          ),
          _ZoomOutIntent: CallbackAction<_ZoomOutIntent>(
            onInvoke: (_) =>
                settingsNotifier.setFontSize(settings.fontSize - 1),
          ),
          _HistoryIntent: CallbackAction<_HistoryIntent>(
            onInvoke: (_) {
              showHistoryViewer(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: theme.background,
            body: Column(
              children: [
                // Title bar with tabs — draggable to move window
                GestureDetector(
                  onPanStart: (_) => windowManager.startDragging(),
                  onDoubleTap: () async {
                    final isMaximized = await windowManager.isMaximized();
                    if (isMaximized) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                  child: Container(
                    color: theme.tabBarBackground,
                    child: Row(
                      children: [
                        if (Platform.isMacOS)
                          const SizedBox(width: 78),
                        const Expanded(child: TerminalTabBar()),
                        // Window controls for Windows/Linux
                        if (!Platform.isMacOS)
                          _WindowControls(theme: theme),
                      ],
                    ),
                  ),
                ),
                // Terminal content — wrapped in RepaintBoundary for screen recording
                Expanded(
                  child: RepaintBoundary(
                    key: terminalRepaintKey,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 4, right: 4, bottom: 0),
                      child: IndexedStack(
                        index: tabState.activeIndex,
                        children: tabState.tabs
                            .map((tab) => SplitTreeView(
                                  key: ValueKey(tab.id),
                                  node: tab.splitTree,
                                  panels: tab.panels,
                                  activePanelId: tab.activePanelId,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                // Status bar
                const StatusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Intent classes
class _NewTabIntent extends Intent {
  const _NewTabIntent();
}

class _CloseTabIntent extends Intent {
  const _CloseTabIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PrevTabIntent extends Intent {
  const _PrevTabIntent();
}

class _SplitHorizontalIntent extends Intent {
  const _SplitHorizontalIntent();
}

class _SplitVerticalIntent extends Intent {
  const _SplitVerticalIntent();
}

class _ClosePanelIntent extends Intent {
  const _ClosePanelIntent();
}

class _FocusNextPanelIntent extends Intent {
  const _FocusNextPanelIntent();
}

class _FocusPrevPanelIntent extends Intent {
  const _FocusPrevPanelIntent();
}

class _CycleThemeIntent extends Intent {
  const _CycleThemeIntent();
}

class _ToggleRtlIntent extends Intent {
  const _ToggleRtlIntent();
}

class _CommandPaletteIntent extends Intent {
  const _CommandPaletteIntent();
}

class _SettingsIntent extends Intent {
  const _SettingsIntent();
}

class _EnvViewerIntent extends Intent {
  const _EnvViewerIntent();
}

class _ZoomInIntent extends Intent {
  const _ZoomInIntent();
}

class _ZoomOutIntent extends Intent {
  const _ZoomOutIntent();
}

class _HistoryIntent extends Intent {
  const _HistoryIntent();
}

/// Window control buttons for Windows and Linux (minimize, maximize, close)
class _WindowControls extends StatelessWidget {
  final HiTerminalTheme theme;
  const _WindowControls({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WinButton(
          icon: Icons.minimize,
          theme: theme,
          onTap: () => windowManager.minimize(),
        ),
        _WinButton(
          icon: Icons.crop_square,
          theme: theme,
          onTap: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        _WinButton(
          icon: Icons.close,
          theme: theme,
          hoverColor: Colors.red,
          onTap: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _WinButton extends StatefulWidget {
  final IconData icon;
  final HiTerminalTheme theme;
  final Color? hoverColor;
  final VoidCallback onTap;

  const _WinButton({
    required this.icon,
    required this.theme,
    this.hoverColor,
    required this.onTap,
  });

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.hoverColor ?? widget.theme.tabHoverBackground;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 46,
          height: 30,
          color: _hovered ? hoverBg : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered && widget.hoverColor != null
                ? Colors.white
                : widget.theme.tabInactiveText,
          ),
        ),
      ),
    );
  }
}
