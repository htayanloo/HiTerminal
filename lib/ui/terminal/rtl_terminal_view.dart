import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../core/rtl/rtl_detector.dart';

/// A widget that wraps [TerminalView] and overlays correct RTL rendering
/// on lines that contain right-to-left characters.
///
/// How it works:
/// 1. Listens to terminal buffer changes
/// 2. Scans visible lines for RTL characters
/// 3. For lines with RTL content, paints a full-line paragraph on top of
///    xterm.dart's character-by-character output, using Flutter's built-in
///    BiDi-aware text layout (ICU)
/// 4. Pure LTR lines are left untouched (zero overhead)
class RtlTerminalView extends StatefulWidget {
  final Terminal terminal;
  final TerminalController? controller;
  final TerminalTheme theme;
  final TerminalStyle textStyle;
  final bool rtlEnabled;

  const RtlTerminalView({
    super.key,
    required this.terminal,
    this.controller,
    required this.theme,
    this.textStyle = const TerminalStyle(),
    this.rtlEnabled = true,
  });

  @override
  State<RtlTerminalView> createState() => _RtlTerminalViewState();
}

class _RtlTerminalViewState extends State<RtlTerminalView> {
  late TerminalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TerminalController();
    widget.terminal.addListener(_onTerminalChanged);
  }

  @override
  void didUpdateWidget(RtlTerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.terminal != widget.terminal) {
      oldWidget.terminal.removeListener(_onTerminalChanged);
      widget.terminal.addListener(_onTerminalChanged);
    }
  }

  @override
  void dispose() {
    widget.terminal.removeListener(_onTerminalChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTerminalChanged() {
    // Trigger repaint of the overlay
    if (mounted && widget.rtlEnabled) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base terminal view from xterm.dart
        TerminalView(
          widget.terminal,
          controller: _controller,
          autofocus: true,
          textStyle: widget.textStyle,
          theme: widget.theme,
        ),
        // RTL overlay — only active when enabled
        if (widget.rtlEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RtlOverlayPainter(
                  terminal: widget.terminal,
                  theme: widget.theme,
                  textStyle: widget.textStyle,
                  textScaler: MediaQuery.textScalerOf(context),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RtlOverlayPainter extends CustomPainter {
  final Terminal terminal;
  final TerminalTheme theme;
  final TerminalStyle textStyle;
  final TextScaler textScaler;

  // Cache the cell size measurement
  late final Size _cellSize = _measureCellSize();

  _RtlOverlayPainter({
    required this.terminal,
    required this.theme,
    required this.textStyle,
    required this.textScaler,
  });

  Size _measureCellSize() {
    const test = 'mmmmmmmmmm';
    final style = textStyle.toTextStyle();
    final builder = ui.ParagraphBuilder(style.getParagraphStyle());
    builder.pushStyle(style.getTextStyle(textScaler: textScaler));
    builder.addText(test);
    final paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    final size = Size(
      paragraph.maxIntrinsicWidth / test.length,
      paragraph.height,
    );
    paragraph.dispose();
    return size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final buffer = terminal.buffer;
    final lines = buffer.lines;
    final cellHeight = _cellSize.height;
    final cellWidth = _cellSize.width;
    final viewWidth = terminal.viewWidth;

    // Calculate visible line range
    final viewHeight = terminal.viewHeight;
    // The visible area starts from (lines.length - viewHeight) for the bottom
    final firstVisibleLine = lines.length - viewHeight;

    for (var i = 0; i < viewHeight; i++) {
      final lineIndex = firstVisibleLine + i;
      if (lineIndex < 0 || lineIndex >= lines.length) continue;

      final line = lines[lineIndex];

      // Extract codepoints for RTL detection
      final codePoints = <int>[];
      for (var col = 0; col < line.length && col < viewWidth; col++) {
        codePoints.add(line.getCodePoint(col));
      }

      // Skip lines without RTL characters
      if (!RtlDetector.lineContainsRtl(codePoints)) continue;

      // This line has RTL content — repaint it with proper BiDi layout
      _paintRtlLine(canvas, i, line, codePoints, cellWidth, cellHeight, viewWidth);
    }
  }

  void _paintRtlLine(
    Canvas canvas,
    int viewRow,
    dynamic line, // BufferLine
    List<int> codePoints,
    double cellWidth,
    double cellHeight,
    int viewWidth,
  ) {
    final y = viewRow * cellHeight;

    // First, paint the background to cover xterm.dart's incorrect rendering
    final bgPaint = Paint()..color = theme.background;
    canvas.drawRect(
      Rect.fromLTWH(0, y, viewWidth * cellWidth, cellHeight),
      bgPaint,
    );

    // Extract the line text, respecting cell widths
    final textBuffer = StringBuffer();
    final cellColors = <Color>[];
    final cellBgColors = <Color?>[];

    for (var col = 0; col < codePoints.length; col++) {
      final cp = codePoints[col];
      if (cp == 0) {
        textBuffer.write(' ');
      } else {
        textBuffer.write(String.fromCharCode(cp));
      }

      // Get cell styling
      final fg = line.getForeground(col);
      final bg = line.getBackground(col);
      final flags = line.getAttributes(col);

      cellColors.add(_resolveForegroundColor(fg, flags));
      cellBgColors.add(_resolveBackgroundColor(bg));
    }

    final lineText = textBuffer.toString().trimRight();
    if (lineText.isEmpty) return;

    // Paint cell backgrounds for cells with non-default colors
    for (var col = 0; col < cellBgColors.length && col < codePoints.length; col++) {
      final bgColor = cellBgColors[col];
      if (bgColor != null) {
        final bgPaintCell = Paint()..color = bgColor;
        canvas.drawRect(
          Rect.fromLTWH(col * cellWidth, y, cellWidth, cellHeight),
          bgPaintCell,
        );
      }
    }

    // Use Flutter's text layout engine for proper BiDi rendering
    // We create a TextPainter with TextDirection.ltr as the base,
    // and let the Unicode BiDi algorithm handle RTL runs
    final textSpan = TextSpan(
      text: lineText,
      style: textStyle.toTextStyle(
        color: theme.foreground,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: _detectLineDirection(lineText),
      maxLines: 1,
    );

    textPainter.layout(maxWidth: viewWidth * cellWidth);
    textPainter.paint(canvas, Offset(0, y));
    textPainter.dispose();
  }

  /// Determine the primary text direction of a line.
  /// If the first strong character is RTL, the line is RTL.
  TextDirection _detectLineDirection(String text) {
    for (var i = 0; i < text.length; i++) {
      final cp = text.codeUnitAt(i);
      if (RtlDetector.isRtlCodePoint(cp)) return TextDirection.rtl;
      // Check for strong LTR characters (Latin, etc.)
      if ((cp >= 0x41 && cp <= 0x5A) || // A-Z
          (cp >= 0x61 && cp <= 0x7A) || // a-z
          (cp >= 0xC0 && cp <= 0x02B8)) {
        return TextDirection.ltr;
      }
    }
    return TextDirection.ltr;
  }

  Color _resolveForegroundColor(int cellColor, int flags) {
    final colorType = cellColor & 0xFF000000;
    final colorValue = cellColor & 0x00FFFFFF;

    // Check for inverse flag
    const inverseFlag = 1 << 1; // CellFlags.inverse
    if (flags & inverseFlag != 0) {
      return theme.background;
    }

    // Named colors (0-15)
    if (colorType == 0) {
      // Default foreground
      if (colorValue == 0) return theme.foreground;
    }

    // For indexed and RGB colors, use the foreground as fallback
    return theme.foreground;
  }

  Color? _resolveBackgroundColor(int cellColor) {
    final colorType = cellColor & 0xFF000000;
    if (colorType == 0) return null; // Default background — transparent
    return null; // Let the base terminal handle colored backgrounds for now
  }

  @override
  bool shouldRepaint(covariant _RtlOverlayPainter oldDelegate) {
    return true; // Always repaint — terminal content changes frequently
  }
}
