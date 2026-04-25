import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../core/terminal/terminal_session.dart';
import '../../state/rtl_state.dart';
import '../../state/settings_state.dart';
import '../../state/theme_state.dart';
import 'rtl_terminal_view.dart';

class TerminalPanel extends ConsumerStatefulWidget {
  final TerminalSession session;

  const TerminalPanel({super.key, required this.session});

  @override
  ConsumerState<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends ConsumerState<TerminalPanel> {
  late final TerminalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TerminalController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final rtlEnabled = ref.watch(rtlEnabledProvider);
    final settings = ref.watch(settingsProvider);

    final style = TerminalStyle(
      fontSize: settings.fontSize,
      fontFamily: settings.fontFamily,
      fontFamilyFallback: const [
        'Courier New',
        'Consolas',
        'SF Mono',
        'monospace',
      ],
    );

    return RtlTerminalView(
      terminal: widget.session.terminal,
      controller: _controller,
      theme: theme.terminalTheme,
      textStyle: style,
      rtlEnabled: rtlEnabled,
    );
  }
}
