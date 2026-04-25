import 'dart:io';

import 'session_recorder.dart';

/// Manages recording files on disk: listing, searching, deleting sessions.
class HistoryManager {
  final String _recordingsDir;

  HistoryManager({String? recordingsDir})
      : _recordingsDir = recordingsDir ?? _defaultDir();

  static String _defaultDir() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$home/.hiterminal/recordings';
  }

  /// List all recorded sessions, newest first
  Future<List<SessionInfo>> listSessions() async {
    final dir = Directory(_recordingsDir);
    if (!await dir.exists()) return [];

    final sessions = <SessionInfo>[];
    final files = await dir.list().toList();

    // Group by base name (before .raw.log or .commands.log)
    final commandFiles = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.commands.log'))
        .toList();

    for (final file in commandFiles) {
      final name = file.uri.pathSegments.last;
      final baseName = name.replaceAll('.commands.log', '');
      final rawFile = File('${dir.path}/$baseName.raw.log');

      // Parse header for metadata
      final lines = await file.readAsLines();
      String? startedAt;
      int commandCount = 0;

      for (final line in lines) {
        if (line.startsWith('# Started:')) {
          startedAt = line.substring(11).trim();
        } else if (line.startsWith('# Total commands:')) {
          commandCount = int.tryParse(line.substring(18).trim()) ?? 0;
        } else if (!line.startsWith('#') && line.trim().isNotEmpty) {
          commandCount++;
        }
      }

      sessions.add(SessionInfo(
        baseName: baseName,
        commandFile: file,
        rawFile: rawFile.existsSync() ? rawFile : null,
        startedAt: startedAt != null
            ? DateTime.tryParse(startedAt)
            : file.lastModifiedSync(),
        commandCount: commandCount,
        rawSizeBytes: rawFile.existsSync() ? rawFile.lengthSync() : 0,
      ));
    }

    sessions.sort((a, b) => (b.startedAt ?? DateTime(2000))
        .compareTo(a.startedAt ?? DateTime(2000)));
    return sessions;
  }

  /// Load all commands from a session file
  Future<List<CommandEntry>> loadCommands(File commandFile) async {
    if (!await commandFile.exists()) return [];

    final lines = await commandFile.readAsLines();
    final commands = <CommandEntry>[];

    for (final line in lines) {
      if (line.startsWith('#') || line.trim().isEmpty) continue;

      // Format: "2026-04-25T10:30:00.000 | command text"
      final pipeIndex = line.indexOf(' | ');
      if (pipeIndex == -1) continue;

      final timestamp = DateTime.tryParse(line.substring(0, pipeIndex));
      final command = line.substring(pipeIndex + 3);

      if (timestamp != null && command.isNotEmpty) {
        commands.add(CommandEntry(
          command: command,
          timestamp: timestamp,
          sessionId: '',
        ));
      }
    }

    return commands;
  }

  /// Search all command history across sessions
  Future<List<CommandEntry>> searchCommands(String query) async {
    final sessions = await listSessions();
    final results = <CommandEntry>[];
    final q = query.toLowerCase();

    for (final session in sessions) {
      final commands = await loadCommands(session.commandFile);
      results.addAll(
          commands.where((c) => c.command.toLowerCase().contains(q)));
    }

    return results;
  }

  /// Delete a recording session
  Future<void> deleteSession(SessionInfo session) async {
    await session.commandFile.delete();
    if (session.rawFile != null && await session.rawFile!.exists()) {
      await session.rawFile!.delete();
    }
  }

  /// Get total disk usage of recordings
  Future<int> totalDiskUsage() async {
    final dir = Directory(_recordingsDir);
    if (!await dir.exists()) return 0;

    int total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}

class SessionInfo {
  final String baseName;
  final File commandFile;
  final File? rawFile;
  final DateTime? startedAt;
  final int commandCount;
  final int rawSizeBytes;

  const SessionInfo({
    required this.baseName,
    required this.commandFile,
    this.rawFile,
    this.startedAt,
    required this.commandCount,
    required this.rawSizeBytes,
  });

  String get formattedSize {
    if (rawSizeBytes < 1024) return '${rawSizeBytes}B';
    if (rawSizeBytes < 1024 * 1024) return '${(rawSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(rawSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
