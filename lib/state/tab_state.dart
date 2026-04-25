import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/terminal/terminal_session.dart';
import '../ui/panels/split_node.dart';
import 'settings_state.dart';

enum DropPosition { left, right, top, bottom }

class PanelData {
  final String id;
  final String title;
  final TerminalSession session;

  PanelData({
    required this.id,
    String? title,
    int maxLines = 50000,
    bool recordingEnabled = false,
    String? recordingPath,
  })  : title = title ?? 'Terminal',
        session = TerminalSession(
          maxLines: maxLines,
          recordingEnabled: recordingEnabled,
          recordingPath: recordingPath,
        ) {
    session.start();
  }

  PanelData._internal({
    required this.id,
    required this.title,
    required this.session,
  });

  PanelData copyWith({String? title}) {
    return PanelData._internal(
      id: id,
      title: title ?? this.title,
      session: session,
    );
  }

  void dispose() {
    session.dispose();
  }
}

class TabData {
  final String id;
  final String title;
  final Map<String, PanelData> panels;
  final SplitNode splitTree;
  final String activePanelId;

  TabData({
    required this.id,
    required this.title,
    required this.panels,
    required this.splitTree,
    required this.activePanelId,
  });

  TabData copyWith({
    String? title,
    Map<String, PanelData>? panels,
    SplitNode? splitTree,
    String? activePanelId,
  }) {
    return TabData(
      id: id,
      title: title ?? this.title,
      panels: panels ?? this.panels,
      splitTree: splitTree ?? this.splitTree,
      activePanelId: activePanelId ?? this.activePanelId,
    );
  }

  void dispose() {
    for (final panel in panels.values) {
      panel.dispose();
    }
  }
}

class TabListState {
  final List<TabData> tabs;
  final int activeIndex;

  const TabListState({
    required this.tabs,
    required this.activeIndex,
  });

  TabData get activeTab => tabs[activeIndex];
}

class TabListNotifier extends Notifier<TabListState> {
  int _tabCounter = 0;
  int _panelCounter = 0;

  @override
  TabListState build() {
    final firstTab = _createTab();
    ref.onDispose(() {
      for (final tab in state.tabs) {
        tab.dispose();
      }
    });
    return TabListState(tabs: [firstTab], activeIndex: 0);
  }

  String _nextPanelId() {
    _panelCounter++;
    return 'panel_$_panelCounter';
  }

  AppSettings get _settings => ref.read(settingsProvider);

  PanelData _createPanel(String panelId) {
    return PanelData(
      id: panelId,
      maxLines: _settings.scrollbackLines,
      recordingEnabled: _settings.recordingEnabled,
      recordingPath: _settings.recordingPath,
    );
  }

  TabData _createTab() {
    _tabCounter++;
    final panelId = _nextPanelId();
    final panel = _createPanel(panelId);
    final leafId = 'leaf_init_$_tabCounter';
    return TabData(
      id: 'tab_$_tabCounter',
      title: 'Terminal $_tabCounter',
      panels: {panelId: panel},
      splitTree: SplitLeaf(id: leafId, panelId: panelId),
      activePanelId: panelId,
    );
  }

  void addTab() {
    final newTab = _createTab();
    state = TabListState(
      tabs: [...state.tabs, newTab],
      activeIndex: state.tabs.length,
    );
  }

  void closeTab(int index) {
    if (state.tabs.length <= 1) return;

    final tabs = [...state.tabs];
    tabs[index].dispose();
    tabs.removeAt(index);

    int newActive = state.activeIndex;
    if (newActive >= tabs.length) {
      newActive = tabs.length - 1;
    } else if (index < state.activeIndex) {
      newActive--;
    }

    state = TabListState(tabs: tabs, activeIndex: newActive);
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = TabListState(tabs: state.tabs, activeIndex: index);
    }
  }

  void renameTab(int index, String title) {
    final tabs = [...state.tabs];
    tabs[index] = tabs[index].copyWith(title: title);
    state = TabListState(tabs: tabs, activeIndex: state.activeIndex);
  }

  void reorderTab(int oldIndex, int newIndex) {
    final tabs = [...state.tabs];
    final tab = tabs.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    tabs.insert(newIndex, tab);

    // Track the active tab
    int newActive = state.activeIndex;
    if (state.activeIndex == oldIndex) {
      newActive = newIndex;
    } else if (oldIndex < state.activeIndex && newIndex >= state.activeIndex) {
      newActive--;
    } else if (oldIndex > state.activeIndex && newIndex <= state.activeIndex) {
      newActive++;
    }

    state = TabListState(tabs: tabs, activeIndex: newActive);
  }

  // --- Panel operations ---

  void setActivePanel(String panelId) {
    final tab = state.activeTab;
    if (tab.panels.containsKey(panelId)) {
      _updateActiveTab(tab.copyWith(activePanelId: panelId));
    }
  }

  void splitPanel(Axis axis) {
    final tab = state.activeTab;
    final activePanelId = tab.activePanelId;
    final leafId = SplitTreeOps.findLeafByPanelId(tab.splitTree, activePanelId);
    if (leafId == null) return;

    final newPanelId = _nextPanelId();
    final newPanel = _createPanel(newPanelId);
    final newTree = SplitTreeOps.splitLeaf(tab.splitTree, leafId, axis, newPanelId);
    final newPanels = Map<String, PanelData>.from(tab.panels);
    newPanels[newPanelId] = newPanel;

    _updateActiveTab(tab.copyWith(
      panels: newPanels,
      splitTree: newTree,
      activePanelId: newPanelId,
    ));
  }

  void closePanel(String panelId) {
    final tab = state.activeTab;
    if (tab.panels.length <= 1) return;

    final leafId = SplitTreeOps.findLeafByPanelId(tab.splitTree, panelId);
    if (leafId == null) return;

    final newTree = SplitTreeOps.removeLeaf(tab.splitTree, leafId);
    if (newTree == null) return;

    final newPanels = Map<String, PanelData>.from(tab.panels);
    newPanels[panelId]?.dispose();
    newPanels.remove(panelId);

    final newActivePanelId = tab.activePanelId == panelId
        ? SplitTreeOps.allPanelIds(newTree).first
        : tab.activePanelId;

    _updateActiveTab(tab.copyWith(
      panels: newPanels,
      splitTree: newTree,
      activePanelId: newActivePanelId,
    ));
  }

  void closeActivePanel() {
    closePanel(state.activeTab.activePanelId);
  }

  void updateSplitRatio(String branchId, double ratio) {
    final tab = state.activeTab;
    final newTree = SplitTreeOps.updateRatio(tab.splitTree, branchId, ratio);
    _updateActiveTab(tab.copyWith(splitTree: newTree));
  }

  /// Move a panel next to a target panel in a given direction.
  /// Used for drag-and-drop panel rearrangement.
  void movePanel(String sourcePanelId, String targetPanelId, DropPosition position) {
    if (sourcePanelId == targetPanelId) return;
    final tab = state.activeTab;
    if (tab.panels.length <= 1) return;

    // Remove source from tree
    final sourceLeafId = SplitTreeOps.findLeafByPanelId(tab.splitTree, sourcePanelId);
    if (sourceLeafId == null) return;

    final treeAfterRemove = SplitTreeOps.removeLeaf(tab.splitTree, sourceLeafId);
    if (treeAfterRemove == null) return;

    // Find target leaf and split it with the source
    final targetLeafId = SplitTreeOps.findLeafByPanelId(treeAfterRemove, targetPanelId);
    if (targetLeafId == null) return;

    final axis = (position == DropPosition.left || position == DropPosition.right)
        ? Axis.horizontal
        : Axis.vertical;

    // For left/top, source goes first; for right/bottom, source goes second
    final sourceFirst = position == DropPosition.left || position == DropPosition.top;

    final newTree = SplitTreeOps.splitLeafWithExisting(
      treeAfterRemove,
      targetLeafId,
      axis,
      sourcePanelId,
      sourceFirst,
    );

    _updateActiveTab(tab.copyWith(
      splitTree: newTree,
      activePanelId: sourcePanelId,
    ));
  }

  void renamePanelTitle(String panelId, String title) {
    final tab = state.activeTab;
    final newPanels = Map<String, PanelData>.from(tab.panels);
    if (newPanels.containsKey(panelId)) {
      newPanels[panelId] = newPanels[panelId]!.copyWith(title: title);
      _updateActiveTab(tab.copyWith(panels: newPanels));
    }
  }

  void focusNextPanel() {
    final tab = state.activeTab;
    final panelIds = SplitTreeOps.allPanelIds(tab.splitTree);
    final currentIndex = panelIds.indexOf(tab.activePanelId);
    final nextIndex = (currentIndex + 1) % panelIds.length;
    setActivePanel(panelIds[nextIndex]);
  }

  void focusPreviousPanel() {
    final tab = state.activeTab;
    final panelIds = SplitTreeOps.allPanelIds(tab.splitTree);
    final currentIndex = panelIds.indexOf(tab.activePanelId);
    final prevIndex = (currentIndex - 1 + panelIds.length) % panelIds.length;
    setActivePanel(panelIds[prevIndex]);
  }

  void _updateActiveTab(TabData updatedTab) {
    final tabs = [...state.tabs];
    tabs[state.activeIndex] = updatedTab;
    state = TabListState(tabs: tabs, activeIndex: state.activeIndex);
  }
}

final tabListProvider =
    NotifierProvider<TabListNotifier, TabListState>(TabListNotifier.new);
