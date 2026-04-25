import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final double fontSize;
  final String fontFamily;
  final double opacity;
  final bool showPanelFooter;
  final List<String> footerSegments;
  final int scrollbackLines;
  final bool recordingEnabled;
  final String recordingPath;

  AppSettings({
    this.fontSize = 14,
    this.fontFamily = 'Menlo',
    this.opacity = 1.0,
    this.showPanelFooter = true,
    this.footerSegments = const ['shell', 'proxy', 'ip'],
    this.scrollbackLines = 50000,
    this.recordingEnabled = false,
    String? recordingPath,
  }) : recordingPath = recordingPath ?? _defaultRecordingPath();

  static String _defaultRecordingPath() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$home/.hiterminal/recordings';
  }

  AppSettings copyWith({
    double? fontSize,
    String? fontFamily,
    double? opacity,
    bool? showPanelFooter,
    List<String>? footerSegments,
    int? scrollbackLines,
    bool? recordingEnabled,
    String? recordingPath,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      opacity: opacity ?? this.opacity,
      showPanelFooter: showPanelFooter ?? this.showPanelFooter,
      footerSegments: footerSegments ?? this.footerSegments,
      scrollbackLines: scrollbackLines ?? this.scrollbackLines,
      recordingEnabled: recordingEnabled ?? this.recordingEnabled,
      recordingPath: recordingPath ?? this.recordingPath,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings();

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size.clamp(8, 32));
  }

  void setFontFamily(String family) {
    state = state.copyWith(fontFamily: family);
  }

  void setOpacity(double opacity) {
    state = state.copyWith(opacity: opacity.clamp(0.3, 1.0));
  }

  void togglePanelFooter() {
    state = state.copyWith(showPanelFooter: !state.showPanelFooter);
  }

  void setFooterSegments(List<String> segments) {
    state = state.copyWith(footerSegments: segments);
  }

  void setScrollbackLines(int lines) {
    state = state.copyWith(scrollbackLines: lines.clamp(1000, 500000));
  }

  void setRecordingEnabled(bool enabled) {
    state = state.copyWith(recordingEnabled: enabled);
  }

  void setRecordingPath(String path) {
    state = state.copyWith(recordingPath: path);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
