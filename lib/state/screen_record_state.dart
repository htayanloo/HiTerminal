import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/recording/screen_recorder.dart';

/// Global key for the RepaintBoundary wrapping terminal content
final terminalRepaintKey = GlobalKey();

class ScreenRecordState {
  final bool isRecording;
  final int frameCount;
  final String? lastOutputPath;
  final bool ffmpegMissing;

  const ScreenRecordState({
    this.isRecording = false,
    this.frameCount = 0,
    this.lastOutputPath,
    this.ffmpegMissing = false,
  });
}

class ScreenRecordNotifier extends Notifier<ScreenRecordState> {
  ScreenRecorder? _recorder;

  @override
  ScreenRecordState build() => const ScreenRecordState();

  /// Start recording. Returns false if FFmpeg not found.
  Future<bool> startRecording({String? outputDir}) async {
    if (state.isRecording) return true;

    _recorder = ScreenRecorder(
      repaintBoundaryKey: terminalRepaintKey,
      outputDir: outputDir,
      fps: 10,
      pixelRatio: 1.0,
    );

    final started = await _recorder!.start();
    if (!started) {
      // FFmpeg not found
      _recorder?.dispose();
      _recorder = null;
      state = const ScreenRecordState(ffmpegMissing: true);
      return false;
    }

    state = const ScreenRecordState(isRecording: true);
    return true;
  }

  Future<String?> stopRecording() async {
    if (!state.isRecording || _recorder == null) return null;

    final path = await _recorder!.stop();
    state = ScreenRecordState(
      isRecording: false,
      lastOutputPath: path,
    );
    _recorder?.dispose();
    _recorder = null;
    return path;
  }
}

final screenRecordProvider =
    NotifierProvider<ScreenRecordNotifier, ScreenRecordState>(
        ScreenRecordNotifier.new);
