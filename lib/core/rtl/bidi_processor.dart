import 'rtl_detector.dart';

/// Processes terminal line text for correct BiDi (Bidirectional) rendering.
///
/// The core problem: xterm.dart stores characters in logical order and renders
/// them left-to-right, one cell at a time. For RTL text, this produces
/// reversed/jumbled output. This processor identifies RTL runs and prepares
/// text for Flutter's built-in BiDi-aware text rendering.
class BidiProcessor {
  /// Process a terminal line's text for BiDi-aware rendering.
  ///
  /// Returns null if the line has no RTL content (skip overlay).
  /// Returns a [BidiLineResult] with processed segments if RTL is present.
  static BidiLineResult? processLine(String lineText, List<int> codePoints) {
    if (lineText.isEmpty) return null;

    // Fast path: no RTL characters at all
    if (!RtlDetector.containsRtl(lineText)) return null;

    // Build segments: contiguous runs of same directionality
    final segments = <BidiSegment>[];
    int segStart = 0;
    bool currentIsRtl = RtlDetector.isRtlCodePoint(lineText.codeUnitAt(0));

    for (var i = 1; i < lineText.length; i++) {
      final cp = lineText.codeUnitAt(i);

      // Skip neutral/space characters — they inherit direction from context
      if (_isNeutral(cp)) continue;

      final charIsRtl = RtlDetector.isRtlCodePoint(cp);
      if (charIsRtl != currentIsRtl) {
        segments.add(BidiSegment(
          text: lineText.substring(segStart, i),
          startCol: segStart,
          endCol: i,
          isRtl: currentIsRtl,
        ));
        segStart = i;
        currentIsRtl = charIsRtl;
      }
    }

    // Add final segment
    segments.add(BidiSegment(
      text: lineText.substring(segStart),
      startCol: segStart,
      endCol: lineText.length,
      isRtl: currentIsRtl,
    ));

    return BidiLineResult(
      originalText: lineText,
      segments: segments,
      hasRtl: true,
    );
  }

  static bool _isNeutral(int cp) {
    // Space, digits, punctuation, symbols
    if (cp == 0x20) return true; // space
    if (cp >= 0x30 && cp <= 0x39) return true; // ASCII digits
    if (cp >= 0x21 && cp <= 0x2F) return true; // !"#$%&'()*+,-./
    if (cp >= 0x3A && cp <= 0x40) return true; // :;<=>?@
    if (cp >= 0x5B && cp <= 0x60) return true; // [\]^_`
    if (cp >= 0x7B && cp <= 0x7E) return true; // {|}~
    return false;
  }
}

/// Result of BiDi processing for a single terminal line.
class BidiLineResult {
  final String originalText;
  final List<BidiSegment> segments;
  final bool hasRtl;

  const BidiLineResult({
    required this.originalText,
    required this.segments,
    required this.hasRtl,
  });
}

/// A contiguous run of text with the same directionality.
class BidiSegment {
  final String text;
  final int startCol;
  final int endCol;
  final bool isRtl;

  const BidiSegment({
    required this.text,
    required this.startCol,
    required this.endCol,
    required this.isRtl,
  });
}
