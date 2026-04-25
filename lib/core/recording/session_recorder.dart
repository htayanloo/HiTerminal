import 'dart:io';

/// Records terminal session I/O to a file in a timestamped format.
///
/// Recording is **disabled by default**. Call [start] to begin recording.
/// Commands are always tracked in memory (for current session history),
/// but only written to disk when recording is enabled.
class SessionRecorder {
  final String sessionId;
  String _recordingsDir;
  File? _rawFile;
  File? _commandFile;
  IOSink? _rawSink;
  IOSink? _commandSink;
  final DateTime _startTime;
  bool _isRecording = false;
  bool _enabled = false;

  // Command detection state — always active even without recording
  final StringBuffer _currentLine = StringBuffer();
  final List<CommandEntry> _commands = [];

  SessionRecorder({
    required this.sessionId,
    String? recordingsDir,
  })  : _startTime = DateTime.now(),
        _recordingsDir = recordingsDir ?? _defaultRecordingsDir();

  static String _defaultRecordingsDir() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$home/.hiterminal/recordings';
  }

  String get recordingsDir => _recordingsDir;
  bool get isRecording => _isRecording;
  bool get isEnabled => _enabled;
  List<CommandEntry> get commands => List.unmodifiable(_commands);
  DateTime get startTime => _startTime;

  /// Update the recording directory path
  void setRecordingsDir(String path) {
    _recordingsDir = path;
  }

  /// Start recording to disk
  Future<void> start() async {
    if (_isRecording) return;

    final dir = Directory(_recordingsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dateStr = _formatDate(_startTime);
    final baseName = '${dateStr}_$sessionId';

    _rawFile = File('${dir.path}/$baseName.raw.log');
    _commandFile = File('${dir.path}/$baseName.commands.log');

    _rawSink = _rawFile!.openWrite(mode: FileMode.append);
    _commandSink = _commandFile!.openWrite(mode: FileMode.append);

    _rawSink!.writeln('# HiTerminal Session Recording');
    _rawSink!.writeln('# Session: $sessionId');
    _rawSink!.writeln('# Started: ${_startTime.toIso8601String()}');
    _rawSink!.writeln('# Shell: ${Platform.environment['SHELL'] ?? 'unknown'}');
    _rawSink!.writeln('# ---');

    _commandSink!.writeln('# HiTerminal Command History');
    _commandSink!.writeln('# Session: $sessionId');
    _commandSink!.writeln('# Started: ${_startTime.toIso8601String()}');
    _commandSink!.writeln('# ---');

    // Write any commands already captured before recording started
    for (final cmd in _commands) {
      _commandSink!.writeln('${cmd.timestamp.toIso8601String()} | ${cmd.command}');
    }

    _isRecording = true;
    _enabled = true;
  }

  /// Stop recording to disk (commands still tracked in memory)
  Future<void> stop() async {
    if (!_isRecording) return;
    _isRecording = false;
    _enabled = false;

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime);

    _rawSink?.writeln('# ---');
    _rawSink?.writeln('# Ended: ${endTime.toIso8601String()}');
    _rawSink?.writeln('# Duration: ${_formatDuration(duration)}');
    _rawSink?.writeln('# Commands: ${_commands.length}');

    _commandSink?.writeln('# ---');
    _commandSink?.writeln('# Total commands: ${_commands.length}');
    _commandSink?.writeln('# Duration: ${_formatDuration(duration)}');

    await _rawSink?.flush();
    await _commandSink?.flush();
    await _rawSink?.close();
    await _commandSink?.close();
    _rawSink = null;
    _commandSink = null;
  }

  /// Toggle recording on/off
  Future<void> toggle() async {
    if (_isRecording) {
      await stop();
    } else {
      await start();
    }
  }

  /// Record terminal output (PTY -> screen)
  void recordOutput(String data) {
    if (_isRecording) {
      final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
      _rawSink?.writeln('[${elapsed}ms] OUT: ${_escapeForLog(data)}');
    }
  }

  /// Record terminal input (keyboard -> PTY)
  /// Always tracks commands in memory, only writes to disk if recording
  void recordInput(String data) {
    if (_isRecording) {
      final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
      _rawSink?.writeln('[${elapsed}ms] IN: ${_escapeForLog(data)}');
    }

    // Always track commands in memory
    _processInputForCommands(data);
  }

  void _processInputForCommands(String data) {
    for (final char in data.codeUnits) {
      if (char == 13 || char == 10) {
        final cmd = _currentLine.toString().trim();
        if (cmd.isNotEmpty) {
          final entry = CommandEntry(
            command: cmd,
            timestamp: DateTime.now(),
            sessionId: sessionId,
          );
          _commands.add(entry);
          // Write to disk only if recording
          if (_isRecording) {
            _commandSink?.writeln(
                '${entry.timestamp.toIso8601String()} | $cmd');
            _commandSink?.flush();
          }
        }
        _currentLine.clear();
      } else if (char == 127 || char == 8) {
        if (_currentLine.isNotEmpty) {
          final s = _currentLine.toString();
          _currentLine.clear();
          _currentLine.write(s.substring(0, s.length - 1));
        }
      } else if (char >= 32) {
        _currentLine.writeCharCode(char);
      }
    }
  }

  /// Flush buffers
  Future<void> flush() async {
    await _rawSink?.flush();
    await _commandSink?.flush();
  }

  /// Dispose — stop recording and clean up
  Future<void> dispose() async {
    if (_isRecording) {
      await stop();
    }
  }

  static String _escapeForLog(String data) {
    return data
        .replaceAll('\x1b', '<ESC>')
        .replaceAll('\n', '<LF>')
        .replaceAll('\r', '<CR>')
        .replaceAll('\t', '<TAB>');
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}'
        '_'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h}h ${m}m ${s}s';
  }
}

class CommandEntry {
  final String command;
  final DateTime timestamp;
  final String sessionId;

  const CommandEntry({
    required this.command,
    required this.timestamp,
    required this.sessionId,
  });
}
