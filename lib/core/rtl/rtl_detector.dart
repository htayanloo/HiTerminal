/// Detects RTL (Right-to-Left) characters in text.
/// Optimized for fast scanning — O(n) per line, skips pure LTR lines.
class RtlDetector {
  /// Check if a single codepoint is in an RTL Unicode range.
  static bool isRtlCodePoint(int codePoint) {
    // Arabic (covers Persian/Farsi, Urdu, etc.)
    if (codePoint >= 0x0600 && codePoint <= 0x06FF) return true;
    // Arabic Supplement
    if (codePoint >= 0x0750 && codePoint <= 0x077F) return true;
    // Arabic Extended-B
    if (codePoint >= 0x0870 && codePoint <= 0x089F) return true;
    // Arabic Extended-A
    if (codePoint >= 0x08A0 && codePoint <= 0x08FF) return true;
    // Hebrew
    if (codePoint >= 0x0590 && codePoint <= 0x05FF) return true;
    // Arabic Presentation Forms-A
    if (codePoint >= 0xFB50 && codePoint <= 0xFDFF) return true;
    // Arabic Presentation Forms-B
    if (codePoint >= 0xFE70 && codePoint <= 0xFEFF) return true;
    // Hebrew Presentation Forms (subset of Alphabetic Presentation Forms)
    if (codePoint >= 0xFB1D && codePoint <= 0xFB4F) return true;
    // Thaana (Maldivian)
    if (codePoint >= 0x0780 && codePoint <= 0x07BF) return true;
    // NKo
    if (codePoint >= 0x07C0 && codePoint <= 0x07FF) return true;
    return false;
  }

  /// Check if a string contains any RTL characters.
  static bool containsRtl(String text) {
    for (var i = 0; i < text.length; i++) {
      if (isRtlCodePoint(text.codeUnitAt(i))) return true;
    }
    return false;
  }

  /// Check if a line of codepoints (from terminal buffer) contains RTL.
  static bool lineContainsRtl(List<int> codePoints) {
    for (final cp in codePoints) {
      if (cp != 0 && isRtlCodePoint(cp)) return true;
    }
    return false;
  }

  /// Detect whether a codepoint is a Persian-specific character.
  static bool isPersian(int codePoint) {
    // Persian-specific letters
    if (codePoint == 0x067E) return true; // Pe
    if (codePoint == 0x0686) return true; // Che
    if (codePoint == 0x0698) return true; // Zhe
    if (codePoint == 0x06AF) return true; // Gaf
    if (codePoint == 0x06CC) return true; // Persian Yeh
    if (codePoint == 0x06A9) return true; // Keheh (Persian Kaf)
    // Persian digits
    if (codePoint >= 0x06F0 && codePoint <= 0x06F9) return true;
    // ZWNJ (heavily used in Persian)
    if (codePoint == 0x200C) return true;
    return false;
  }
}
