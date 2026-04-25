import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/terminal_theme_data.dart';
import '../../state/tab_state.dart';
import '../../state/theme_state.dart';
import '../common/context_menu.dart';
import '../terminal/panel_footer.dart';
import '../terminal/terminal_panel.dart';
import 'split_node.dart';

/// Data carried during panel drag
class _PanelDragData {
  final String panelId;
  const _PanelDragData(this.panelId);
}

class SplitTreeView extends ConsumerWidget {
  final SplitNode node;
  final Map<String, PanelData> panels;
  final String activePanelId;

  const SplitTreeView({
    super.key,
    required this.node,
    required this.panels,
    required this.activePanelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return _buildNode(context, ref, node, theme);
  }

  Widget _buildNode(
      BuildContext context, WidgetRef ref, SplitNode node, HiTerminalTheme theme) {
    switch (node) {
      case SplitLeaf():
        return _buildLeaf(context, ref, node, theme);
      case SplitBranch():
        return _buildBranch(context, ref, node, theme);
    }
  }

  Widget _buildLeaf(
      BuildContext context, WidgetRef ref, SplitLeaf leaf, HiTerminalTheme theme) {
    final panel = panels[leaf.panelId];
    if (panel == null) return const SizedBox.shrink();

    final isActive = leaf.panelId == activePanelId;

    return _DropZonePanel(
      panelId: leaf.panelId,
      theme: theme,
      child: GestureDetector(
        onTap: () =>
            ref.read(tabListProvider.notifier).setActivePanel(leaf.panelId),
        onSecondaryTapDown: (details) {
          PanelContextMenu.show(
            context: context,
            ref: ref,
            position: details.globalPosition,
            panelId: leaf.panelId,
            canClose: panels.length > 1,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? theme.panelBorderActive : theme.panelBorderInactive,
              width: isActive ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              _DraggablePanelTitleBar(
                panelId: leaf.panelId,
                title: panel.title,
                isActive: isActive,
                canClose: panels.length > 1,
                theme: theme,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                  child: TerminalPanel(session: panel.session),
                ),
              ),
              const PanelFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranch(
      BuildContext context, WidgetRef ref, SplitBranch branch, HiTerminalTheme theme) {
    return _ResizableSplit(
      branchId: branch.id,
      axis: branch.axis,
      ratio: branch.ratio,
      theme: theme,
      first: _buildNode(context, ref, branch.first, theme),
      second: _buildNode(context, ref, branch.second, theme),
    );
  }
}

/// A draggable wrapper for the panel title bar.
/// When dragged, it carries the panel ID so drop zones can accept it.
class _DraggablePanelTitleBar extends ConsumerStatefulWidget {
  final String panelId;
  final String title;
  final bool isActive;
  final bool canClose;
  final HiTerminalTheme theme;

  const _DraggablePanelTitleBar({
    required this.panelId,
    required this.title,
    required this.isActive,
    required this.canClose,
    required this.theme,
  });

  @override
  ConsumerState<_DraggablePanelTitleBar> createState() =>
      _DraggablePanelTitleBarState();
}

class _DraggablePanelTitleBarState
    extends ConsumerState<_DraggablePanelTitleBar> {
  @override
  Widget build(BuildContext context) {
    return Draggable<_PanelDragData>(
      data: _PanelDragData(widget.panelId),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(6),
        color: widget.theme.tabActiveBackground,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal, size: 12, color: widget.theme.panelBorderActive),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.theme.tabActiveText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
      child: _PanelTitleBar(
        panelId: widget.panelId,
        title: widget.title,
        isActive: widget.isActive,
        canClose: widget.canClose,
        theme: widget.theme,
      ),
    );
  }
}

/// A drop zone wrapper around a panel that shows directional drop indicators
/// when a panel is being dragged over it.
class _DropZonePanel extends ConsumerStatefulWidget {
  final String panelId;
  final HiTerminalTheme theme;
  final Widget child;

  const _DropZonePanel({
    required this.panelId,
    required this.theme,
    required this.child,
  });

  @override
  ConsumerState<_DropZonePanel> createState() => _DropZonePanelState();
}

class _DropZonePanelState extends ConsumerState<_DropZonePanel> {
  DropPosition? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_PanelDragData>(
      onWillAcceptWithDetails: (details) {
        return details.data.panelId != widget.panelId;
      },
      onAcceptWithDetails: (details) {
        if (_hoverPosition != null) {
          ref.read(tabListProvider.notifier).movePanel(
                details.data.panelId,
                widget.panelId,
                _hoverPosition!,
              );
        }
        setState(() => _hoverPosition = null);
      },
      onLeave: (_) => setState(() => _hoverPosition = null),
      onMove: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localPos = box.globalToLocal(details.offset);
        final size = box.size;

        // Determine which quadrant the cursor is in
        final relX = localPos.dx / size.width;
        final relY = localPos.dy / size.height;

        DropPosition? pos;
        // Edge zones (outer 30%)
        if (relX < 0.3) {
          pos = DropPosition.left;
        } else if (relX > 0.7) {
          pos = DropPosition.right;
        } else if (relY < 0.3) {
          pos = DropPosition.top;
        } else if (relY > 0.7) {
          pos = DropPosition.bottom;
        }

        if (pos != _hoverPosition) {
          setState(() => _hoverPosition = pos);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty && _hoverPosition != null;

        return Stack(
          children: [
            widget.child,
            // Drop zone indicator overlay
            if (isDraggingOver)
              Positioned.fill(
                child: IgnorePointer(
                  child: _DropZoneOverlay(
                    position: _hoverPosition!,
                    theme: widget.theme,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Visual overlay showing where a panel will be placed
class _DropZoneOverlay extends StatelessWidget {
  final DropPosition position;
  final HiTerminalTheme theme;

  const _DropZoneOverlay({
    required this.position,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = theme.panelBorderActive.withAlpha(60);
    final borderColor = theme.panelBorderActive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        Rect rect;
        switch (position) {
          case DropPosition.left:
            rect = Rect.fromLTWH(0, 0, w * 0.5, h);
          case DropPosition.right:
            rect = Rect.fromLTWH(w * 0.5, 0, w * 0.5, h);
          case DropPosition.top:
            rect = Rect.fromLTWH(0, 0, w, h * 0.5);
          case DropPosition.bottom:
            rect = Rect.fromLTWH(0, h * 0.5, w, h * 0.5);
        }

        return CustomPaint(
          painter: _DropZonePainter(
            rect: rect,
            fillColor: color,
            borderColor: borderColor,
          ),
        );
      },
    );
  }
}

class _DropZonePainter extends CustomPainter {
  final Rect rect;
  final Color fillColor;
  final Color borderColor;

  _DropZonePainter({
    required this.rect,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = fillColor,
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _DropZonePainter oldDelegate) {
    return rect != oldDelegate.rect;
  }
}

class _PanelTitleBar extends ConsumerStatefulWidget {
  final String panelId;
  final String title;
  final bool isActive;
  final bool canClose;
  final HiTerminalTheme theme;

  const _PanelTitleBar({
    required this.panelId,
    required this.title,
    required this.isActive,
    required this.canClose,
    required this.theme,
  });

  @override
  ConsumerState<_PanelTitleBar> createState() => _PanelTitleBarState();
}

class _PanelTitleBarState extends ConsumerState<_PanelTitleBar> {
  bool _editing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.title);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    // Check if panel is recording
    final tabState = ref.watch(tabListProvider);
    final panel = tabState.activeTab.panels[widget.panelId];
    final isRecording = panel?.session.recorder.isRecording ?? false;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: widget.isActive ? t.panelTitleActive : t.panelTitleInactive,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
      child: Row(
        children: [
          // Drag grip hint
          Opacity(
            opacity: 0.3,
            child: Icon(Icons.drag_indicator, size: 10, color: t.textDim),
          ),
          const SizedBox(width: 2),
          // Terminal icon (red when recording)
          Icon(
            isRecording ? Icons.fiber_manual_record : Icons.terminal,
            size: 11,
            color: isRecording
                ? Colors.red
                : widget.isActive
                    ? t.panelBorderActive
                    : t.textDim,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _editing
                  ? TextField(
                      key: const ValueKey('edit'),
                      controller: _editController,
                      autofocus: true,
                      style: TextStyle(color: t.tabActiveText, fontSize: 11),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) {
                        ref
                            .read(tabListProvider.notifier)
                            .renamePanelTitle(widget.panelId, value);
                        setState(() => _editing = false);
                      },
                    )
                  : GestureDetector(
                      key: const ValueKey('display'),
                      onDoubleTap: () {
                        _editController.text = widget.title;
                        setState(() => _editing = true);
                      },
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.isActive ? t.tabActiveText : t.textDim,
                          fontSize: 11,
                          fontWeight: widget.isActive
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),
          if (widget.canClose)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => ref
                    .read(tabListProvider.notifier)
                    .closePanel(widget.panelId),
                child: Icon(Icons.close, size: 14, color: t.textDim),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResizableSplit extends ConsumerStatefulWidget {
  final String branchId;
  final Axis axis;
  final double ratio;
  final HiTerminalTheme theme;
  final Widget first;
  final Widget second;

  const _ResizableSplit({
    required this.branchId,
    required this.axis,
    required this.ratio,
    required this.theme,
    required this.first,
    required this.second,
  });

  @override
  ConsumerState<_ResizableSplit> createState() => _ResizableSplitState();
}

class _ResizableSplitState extends ConsumerState<_ResizableSplit> {
  static const _layoutThickness = 8.0;
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final dividerColor = _isDragging
        ? t.dividerActive
        : _isHovered
            ? t.dividerHover
            : t.dividerColor;
    final gripColor = _isDragging
        ? t.dividerActive
        : _isHovered
            ? t.tabActiveText
            : t.dividerGrip;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isHorizontal = widget.axis == Axis.horizontal;
        final totalSize =
            isHorizontal ? constraints.maxWidth : constraints.maxHeight;
        final availableSize = totalSize - _layoutThickness;
        final firstSize = availableSize * widget.ratio;
        final secondSize = availableSize - firstSize;

        final children = <Widget>[
          SizedBox(
            width: isHorizontal ? firstSize : null,
            height: isHorizontal ? null : firstSize,
            child: widget.first,
          ),
          MouseRegion(
            cursor: isHorizontal
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.resizeRow,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onPanStart: (_) => setState(() => _isDragging = true),
              onPanEnd: (_) => setState(() => _isDragging = false),
              onPanUpdate: (details) {
                final delta =
                    isHorizontal ? details.delta.dx : details.delta.dy;
                final newRatio = widget.ratio + delta / availableSize;
                ref
                    .read(tabListProvider.notifier)
                    .updateSplitRatio(widget.branchId, newRatio);
              },
              child: SizedBox(
                width: isHorizontal ? _layoutThickness : double.infinity,
                height: isHorizontal ? double.infinity : _layoutThickness,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    width: isHorizontal ? 4 : double.infinity,
                    height: isHorizontal ? double.infinity : 4,
                    color: dividerColor,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: isHorizontal ? 2 : 24,
                        height: isHorizontal ? 24 : 2,
                        decoration: BoxDecoration(
                          color: gripColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: isHorizontal ? secondSize : null,
            height: isHorizontal ? null : secondSize,
            child: widget.second,
          ),
        ];

        if (isHorizontal) {
          return Row(children: children);
        } else {
          return Column(children: children);
        }
      },
    );
  }
}
