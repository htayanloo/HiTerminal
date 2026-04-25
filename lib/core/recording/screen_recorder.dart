import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// Records the terminal screen as MP4 video by streaming frames to FFmpeg.
///
/// Frames are captured from a RepaintBoundary and piped directly to FFmpeg's
/// stdin in real-time. No frames are buffered in memory — they go straight
/// to disk via FFmpeg's encoder. When stop() is called, the video file is
/// already written.
class ScreenRecorder {
  final GlobalKey repaintBoundaryKey;
  final String outputDir;
  final int fps;
  final double pixelRatio;

  Timer? _captureTimer;
  Process? _ffmpegProcess;
  bool _isRecording = false;
  DateTime? _startTime;
  String? _outputPath;
  String? _ffmpegPath;
  int _frameCount = 0;
  int? _frameWidth;
  int? _frameHeight;

  ScreenRecorder({
    required this.repaintBoundaryKey,
    String? outputDir,
    this.fps = 10,
    this.pixelRatio = 1.0,
  }) : outputDir = outputDir ?? _defaultOutputDir();

  static String _defaultOutputDir() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$home/.hiterminal/recordings';
  }

  bool get isRecording => _isRecording;
  String? get outputPath => _outputPath;
  int get frameCount => _frameCount;
  Duration get elapsed =>
      _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

  /// Check if FFmpeg is available
  static Future<String?> findFfmpeg() async {
    // Check PATH
    try {
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}

    // Check common paths
    for (final path in [
      '/opt/homebrew/bin/ffmpeg',
      '/usr/local/bin/ffmpeg',
      '/usr/bin/ffmpeg',
      'C:\\ffmpeg\\bin\\ffmpeg.exe',
    ]) {
      if (await File(path).exists()) return path;
    }
    return null;
  }

  /// Start recording — launches FFmpeg and begins frame capture
  Future<bool> start() async {
    if (_isRecording) return true;

    _ffmpegPath = await findFfmpeg();
    if (_ffmpegPath == null) return false;

    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Capture one frame first to get dimensions
    final firstFrame = await _captureRawFrame();
    if (firstFrame == null) return false;

    _frameWidth = firstFrame.width;
    _frameHeight = firstFrame.height;

    final dateStr = _formatDate(DateTime.now());
    _outputPath = '$outputDir/${dateStr}_screen.mp4';
    _startTime = DateTime.now();
    _frameCount = 0;

    // Start FFmpeg process — reads raw RGBA frames from stdin, writes MP4
    _ffmpegProcess = await Process.start(_ffmpegPath!, [
      '-y', // Overwrite
      '-f', 'rawvideo',
      '-pixel_format', 'rgba',
      '-video_size', '${_frameWidth}x$_frameHeight',
      '-framerate', '$fps',
      '-i', 'pipe:0', // Read from stdin
      '-c:v', 'libx264',
      '-pix_fmt', 'yuv420p',
      '-crf', '20',
      '-preset', 'ultrafast', // Fast encoding for real-time
      '-movflags', '+faststart', // Web-friendly MP4
      _outputPath!,
    ]);

    // Drain stderr to prevent blocking
    _ffmpegProcess!.stderr.drain();
    _ffmpegProcess!.stdout.drain();

    _isRecording = true;

    // Write the first frame
    _writeFrame(firstFrame.bytes);

    // Start periodic frame capture
    final interval = Duration(milliseconds: (1000 / fps).round());
    _captureTimer = Timer.periodic(interval, (_) => _captureAndWrite());

    return true;
  }

  /// Stop recording — closes FFmpeg pipe, video is saved
  Future<String?> stop() async {
    if (!_isRecording) return null;
    _isRecording = false;
    _captureTimer?.cancel();
    _captureTimer = null;

    // Close stdin pipe — signals FFmpeg to finish encoding
    try {
      _ffmpegProcess?.stdin.close();
      // Wait for FFmpeg to finish writing
      final exitCode = await _ffmpegProcess?.exitCode
          .timeout(const Duration(seconds: 10), onTimeout: () {
        _ffmpegProcess?.kill();
        return -1;
      });

      if (exitCode == 0 && _outputPath != null) {
        final file = File(_outputPath!);
        if (await file.exists() && await file.length() > 0) {
          return _outputPath;
        }
      }
    } catch (_) {
      _ffmpegProcess?.kill();
    }

    _ffmpegProcess = null;
    return _outputPath;
  }

  Future<void> _captureAndWrite() async {
    if (!_isRecording || _ffmpegProcess == null) return;

    final frame = await _captureRawFrame();
    if (frame != null) {
      _writeFrame(frame.bytes);
    }
  }

  void _writeFrame(List<int> rgbaBytes) {
    try {
      _ffmpegProcess?.stdin.add(rgbaBytes);
      _frameCount++;
    } catch (_) {
      // FFmpeg process may have died
      _isRecording = false;
      _captureTimer?.cancel();
    }
  }

  /// Capture a single frame as raw RGBA bytes
  Future<_RawFrame?> _captureRawFrame() async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final width = image.width;
      final height = image.height;
      image.dispose();

      if (byteData != null) {
        return _RawFrame(
          bytes: byteData.buffer.asUint8List(),
          width: width,
          height: height,
        );
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _captureTimer?.cancel();
    _ffmpegProcess?.kill();
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
}

class _RawFrame {
  final List<int> bytes;
  final int width;
  final int height;

  const _RawFrame({
    required this.bytes,
    required this.width,
    required this.height,
  });
}
