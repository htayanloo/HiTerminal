import 'dart:convert';
import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import '../../platform/platform_shell.dart';
import '../recording/session_recorder.dart';

class TerminalSession {
  final Terminal terminal;
  late final Pty _pty;
  bool _isAlive = true;
  late final SessionRecorder recorder;
  final String sessionId;

  TerminalSession({
    int maxLines = 50000,
    String? id,
    bool recordingEnabled = false,
    String? recordingPath,
  })  : sessionId = id ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
        terminal = Terminal(maxLines: maxLines) {
    recorder = SessionRecorder(
      sessionId: sessionId,
      recordingsDir: recordingPath,
    );
    if (recordingEnabled) {
      recorder.start();
    }
  }

  bool get isAlive => _isAlive;

  void start() {
    final shell = PlatformShell.defaultShell;
    final args = PlatformShell.defaultShellArgs;
    final env = PlatformShell.defaultEnvironment;

    _pty = Pty.start(
      shell,
      arguments: args,
      environment: env,
      workingDirectory: Platform.environment['HOME'] ?? '.',
    );

    // PTY output -> Terminal + recorder
    _pty.output.cast<List<int>>().transform(const Utf8Decoder()).listen(
      (data) {
        terminal.write(data);
        recorder.recordOutput(data);
      },
      onDone: () {
        _isAlive = false;
      },
    );

    // Terminal input -> PTY + recorder
    terminal.onOutput = (data) {
      _pty.write(const Utf8Encoder().convert(data));
      recorder.recordInput(data);
    };

    // Terminal resize -> PTY
    terminal.onResize = (w, h, pw, ph) {
      _pty.resize(h, w);
    };
  }

  void resize(int rows, int cols) {
    if (_isAlive) {
      _pty.resize(rows, cols);
    }
  }

  void dispose() {
    _isAlive = false;
    recorder.dispose();
    _pty.kill();
  }
}
