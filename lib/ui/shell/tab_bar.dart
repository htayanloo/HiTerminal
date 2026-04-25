import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/terminal_theme_data.dart';
import '../../state/tab_state.dart';
import '../../state/theme_state.dart';
import '../common/design_tokens.dart';

class TerminalTabBar extends ConsumerWidget {
  const TerminalTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabListProvider);
    final theme = ref.watch(themeProvider);

    return SizedBox(
      height: HiSizing.tabBarHeight,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  elevation: 4,
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                ref.read(tabListProvider.notifier).reorderTab(oldIndex, newIndex);
              },
              itemCount: tabState.tabs.length,
              itemBuilder: (context, index) {
                final tab = tabState.tabs[index];
                final isActive = index == tabState.activeIndex;
                return ReorderableDragStartListener(
                  key: ValueKey(tab.id),
                  index: index,
                  child: _TabItem(
                    index: index,
                    title: tab.title,
                    isActive: isActive,
                    theme: theme,
                    onTap: () =>
                        ref.read(tabListProvider.notifier).setActiveTab(index),
                    onClose: tabState.tabs.length > 1
                        ? () =>
                            ref.read(tabListProvider.notifier).closeTab(index)
                        : null,
                  ),
                );
              },
            ),
          ),
          // Split buttons
          _ActionButton(
            icon: Icons.horizontal_split,
            tooltip: 'Split Horizontal',
            theme: theme,
            onTap: () =>
                ref.read(tabListProvider.notifier).splitPanel(Axis.horizontal),
          ),
          _ActionButton(
            icon: Icons.vertical_split,
            tooltip: 'Split Vertical',
            theme: theme,
            onTap: () =>
                ref.read(tabListProvider.notifier).splitPanel(Axis.vertical),
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.add,
            tooltip: 'New Tab',
            theme: theme,
            onTap: () => ref.read(tabListProvider.notifier).addTab(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final int index;
  final String title;
  final bool isActive;
  final HiTerminalTheme theme;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const _TabItem({
    required this.index,
    required this.title,
    required this.isActive,
    required this.theme,
    required this.onTap,
    this.onClose,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HiSizing.maxTabWidth),
          child: AnimatedContainer(
            duration: HiDurations.fast,
            curve: HiCurves.standard,
            margin: const EdgeInsets.only(left: 2, top: 4, bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: HiSizing.tabPaddingH),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? t.tabActiveBackground
                  : _hovered
                      ? t.tabHoverBackground
                      : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(HiSizing.radiusLg)),
              border: widget.isActive
                  ? Border(
                      top: BorderSide(color: t.tabActiveIndicator, width: 2),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.terminal, size: HiSizing.iconMd, color: t.tabInactiveText),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.title,
                    style: HiTypography.body(
                      widget.isActive ? t.tabActiveText : t.tabInactiveText,
                      weight: widget.isActive ? FontWeight.w500 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                // Animated close button
                AnimatedOpacity(
                  opacity: (widget.onClose != null && (_hovered || widget.isActive))
                      ? 1.0
                      : 0.0,
                  duration: HiDurations.fast,
                  child: widget.onClose != null
                      ? GestureDetector(
                          onTap: widget.onClose,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(Icons.close,
                                size: HiSizing.iconMd, color: t.tabInactiveText),
                          ),
                        )
                      : const SizedBox(width: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final HiTerminalTheme theme;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1.0,
            duration: HiDurations.fast,
            curve: HiCurves.standard,
            child: AnimatedContainer(
              duration: HiDurations.fast,
              margin:
                  const EdgeInsets.only(left: 2, right: 2, top: 6, bottom: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _hovered
                    ? widget.theme.tabActiveBackground
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(HiSizing.radiusMd),
              ),
              child: Icon(widget.icon,
                  size: HiSizing.iconLg, color: widget.theme.tabInactiveText),
            ),
          ),
        ),
      ),
    );
  }
}
