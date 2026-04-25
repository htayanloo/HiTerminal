import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/built_in_themes.dart';
import '../core/theme/terminal_theme_data.dart';

class ThemeNotifier extends Notifier<HiTerminalTheme> {
  @override
  HiTerminalTheme build() {
    return BuiltInThemes.catppuccinMocha;
  }

  void setTheme(String themeId) {
    state = BuiltInThemes.getById(themeId);
  }

  void nextTheme() {
    final themes = BuiltInThemes.all;
    final currentIndex = themes.indexWhere((t) => t.id == state.id);
    final nextIndex = (currentIndex + 1) % themes.length;
    state = themes[nextIndex];
  }
}

final themeProvider =
    NotifierProvider<ThemeNotifier, HiTerminalTheme>(ThemeNotifier.new);
