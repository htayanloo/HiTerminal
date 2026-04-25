import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shortcuts/shortcut_action.dart';
import 'design_tokens.dart';
import '../../state/rtl_state.dart';
import '../../state/settings_state.dart';
import '../../state/tab_state.dart';
import '../../state/theme_state.dart';
import '../settings/settings_dialog.dart';
import 'history_viewer.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();

  static void show(BuildContext context) {
    showAnimatedDialog(
      context: context,
      builder: (_) => const CommandPalette(),
    );
  }
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<AppAction> _filteredActions = [];

  List<AppAction> get _allActions {
    final tabNotifier = ref.read(tabListProvider.notifier);
    final themeNotifier = ref.read(themeProvider.notifier);
    final rtlNotifier = ref.read(rtlEnabledProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final settings = ref.read(settingsProvider);
    final tabState = ref.read(tabListProvider);

    return [
      AppAction(
        id: 'new_tab',
        label: 'New Tab',
        shortcutLabel: 'Ctrl+Shift+T',
        execute: () => tabNotifier.addTab(),
      ),
      AppAction(
        id: 'close_tab',
        label: 'Close Tab',
        shortcutLabel: 'Ctrl+Shift+W',
        execute: () => tabNotifier.closeTab(tabState.activeIndex),
      ),
      AppAction(
        id: 'next_tab',
        label: 'Next Tab',
        shortcutLabel: 'Ctrl+Tab',
        execute: () {
          final next = (tabState.activeIndex + 1) % tabState.tabs.length;
          tabNotifier.setActiveTab(next);
        },
      ),
      AppAction(
        id: 'prev_tab',
        label: 'Previous Tab',
        shortcutLabel: 'Ctrl+Shift+Tab',
        execute: () {
          final prev = (tabState.activeIndex - 1 + tabState.tabs.length) %
              tabState.tabs.length;
          tabNotifier.setActiveTab(prev);
        },
      ),
      AppAction(
        id: 'split_horizontal',
        label: 'Split Horizontal',
        shortcutLabel: 'Ctrl+Shift+H',
        execute: () => tabNotifier.splitPanel(Axis.horizontal),
      ),
      AppAction(
        id: 'split_vertical',
        label: 'Split Vertical',
        shortcutLabel: 'Ctrl+Shift+E',
        execute: () => tabNotifier.splitPanel(Axis.vertical),
      ),
      AppAction(
        id: 'close_panel',
        label: 'Close Panel',
        shortcutLabel: 'Ctrl+Shift+X',
        execute: () => tabNotifier.closeActivePanel(),
      ),
      AppAction(
        id: 'focus_next',
        label: 'Focus Next Panel',
        shortcutLabel: 'Ctrl+]',
        execute: () => tabNotifier.focusNextPanel(),
      ),
      AppAction(
        id: 'focus_prev',
        label: 'Focus Previous Panel',
        shortcutLabel: 'Ctrl+[',
        execute: () => tabNotifier.focusPreviousPanel(),
      ),
      AppAction(
        id: 'toggle_rtl',
        label: 'Toggle RTL Mode',
        shortcutLabel: 'Ctrl+Shift+R',
        execute: () => rtlNotifier.toggle(),
      ),
      AppAction(
        id: 'cycle_theme',
        label: 'Cycle Theme',
        shortcutLabel: 'Ctrl+Shift+K',
        execute: () => themeNotifier.nextTheme(),
      ),
      AppAction(
        id: 'settings',
        label: 'Open Settings',
        shortcutLabel: 'Ctrl+,',
        execute: () => SettingsDialog.show(context),
      ),
      AppAction(
        id: 'zoom_in',
        label: 'Zoom In (Increase Font)',
        shortcutLabel: 'Ctrl+=',
        execute: () => settingsNotifier.setFontSize(settings.fontSize + 1),
      ),
      AppAction(
        id: 'zoom_out',
        label: 'Zoom Out (Decrease Font)',
        shortcutLabel: 'Ctrl+-',
        execute: () => settingsNotifier.setFontSize(settings.fontSize - 1),
      ),
      AppAction(
        id: 'toggle_footer',
        label: 'Toggle Panel Footer',
        execute: () => settingsNotifier.togglePanelFooter(),
      ),
      AppAction(
        id: 'history',
        label: 'Command History',
        shortcutLabel: 'Ctrl+Shift+Y',
        execute: () => showHistoryViewer(context),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _filteredActions = _allActions;
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredActions = _allActions
          .where((a) => a.label.toLowerCase().contains(query))
          .toList();
      _selectedIndex = 0;
    });
  }

  void _executeAction(AppAction action) {
    Navigator.of(context).pop();
    action.execute();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              _selectedIndex =
                  (_selectedIndex + 1).clamp(0, _filteredActions.length - 1);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              _selectedIndex =
                  (_selectedIndex - 1).clamp(0, _filteredActions.length - 1);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (_filteredActions.isNotEmpty) {
              _executeAction(_filteredActions[_selectedIndex]);
            }
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 60),
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.panelBorderInactive),
        ),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: TextStyle(color: theme.tabActiveText, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type a command...',
                    hintStyle: TextStyle(color: theme.textDim),
                    prefixIcon: Icon(Icons.search, color: theme.textDim),
                    filled: true,
                    fillColor: theme.tabActiveBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              // Actions list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredActions.length,
                  itemBuilder: (context, index) {
                    final action = _filteredActions[index];
                    final isSelected = index == _selectedIndex;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _selectedIndex = index),
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _executeAction(action),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          color: isSelected
                              ? theme.tabActiveBackground
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  action.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? theme.tabActiveText
                                        : theme.statusBarForeground,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (action.shortcutLabel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.panelBorderInactive,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    action.shortcutLabel!,
                                    style: TextStyle(
                                      color: theme.textDim,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
