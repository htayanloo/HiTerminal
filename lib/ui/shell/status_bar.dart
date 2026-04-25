import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/built_in_themes.dart';
import '../../core/theme/terminal_theme_data.dart';
import '../../platform/platform_shell.dart';
import '../../state/rtl_state.dart';
import '../../state/screen_record_state.dart';
import '../../state/settings_state.dart';
import '../../state/tab_state.dart';
import '../../state/theme_state.dart';
import '../common/design_tokens.dart';
import '../common/env_viewer.dart';
import '../common/toast.dart';
import '../settings/settings_dialog.dart';

class StatusBar extends ConsumerStatefulWidget {
  const StatusBar({super.key});

  @override
  ConsumerState<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends ConsumerState<StatusBar> {
  late Timer _clockTimer;
  String _time = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final tabState = ref.watch(tabListProvider);
    final rtlEnabled = ref.watch(rtlEnabledProvider);
    final settings = ref.watch(settingsProvider);
    final activeTab = tabState.activeTab;
    final panelCount = activeTab.panels.length;
    final shell = PlatformShell.defaultShell.split('/').last;
    final env = Platform.environment;
    final hasProxy = env.containsKey('http_proxy') ||
        env.containsKey('HTTP_PROXY') ||
        env.containsKey('https_proxy') ||
        env.containsKey('HTTPS_PROXY');
    final panel = activeTab.panels[activeTab.activePanelId];
    final isRec = panel?.session.recorder.isRecording ?? false;
    final screenRecState = ref.watch(screenRecordProvider);
    final isScreenRec = screenRecState.isRecording;

    return Container(
      height: HiSizing.statusBarHeight,
      color: theme.statusBarBackground,
      padding: const EdgeInsets.symmetric(horizontal: HiSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          return Row(
            children: [
              // === LEFT: Info group ===
              // Shell badge
              _Seg(
                icon: Icons.terminal,
                text: shell,
                color: theme.statusBarAccent,
                textColor: theme.statusBarBackground,
                filled: true,
              ),
              const SizedBox(width: HiSpacing.md),
              // Active panel
              _Seg(
                icon: Icons.tab,
                text: activeTab.panels[activeTab.activePanelId]?.title ?? '',
                color: theme.statusBarForeground,
              ),
              if (panelCount > 1) ...[
                const SizedBox(width: HiSpacing.md),
                _Seg(
                  icon: Icons.grid_view,
                  text: '$panelCount',
                  color: theme.statusBarForeground,
                ),
              ],
              // Recording — clickable toggle with blinking indicator
              const SizedBox(width: HiSpacing.md),
              Tooltip(
                message: isRec ? 'Stop recording' : 'Start recording',
                child: GestureDetector(
                  onTap: () {
                    if (panel == null) return;
                    final wasRecording = panel.session.recorder.isRecording;
                    panel.session.recorder.toggle();
                    setState(() {});

                    if (!wasRecording) {
                      HiToast.show(
                        context,
                        'Recording started',
                        icon: Icons.fiber_manual_record,
                      );
                    } else {
                      final path = panel.session.recorder.recordingsDir;
                      HiToast.showPath(
                        context,
                        'Recording saved',
                        path,
                        icon: Icons.save,
                      );
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedSwitcher(
                      duration: HiDurations.fast,
                      child: isRec
                          ? _BlinkingRecBadge(key: const ValueKey('rec-on'), theme: theme)
                          : _Seg(
                              key: const ValueKey('rec-off'),
                              icon: Icons.circle_outlined,
                              text: 'rec',
                              color: theme.textDim,
                            ),
                    ),
                  ),
                ),
              ),
              // Screen record (video) — clickable toggle
              const SizedBox(width: HiSpacing.sm),
              Tooltip(
                message: isScreenRec
                    ? 'Stop screen recording'
                    : 'Record screen as video',
                child: GestureDetector(
                  onTap: () async {
                    final notifier = ref.read(screenRecordProvider.notifier);
                    if (!isScreenRec) {
                      final recSettings = ref.read(settingsProvider);
                      final started = await notifier.startRecording(
                          outputDir: recSettings.recordingPath);
                      if (context.mounted) {
                        if (started) {
                          HiToast.show(context, 'Screen recording started',
                              icon: Icons.videocam);
                        } else {
                          HiToast.show(
                            context,
                            'FFmpeg not found. Install: brew install ffmpeg',
                            icon: Icons.error_outline,
                          );
                        }
                      }
                    } else {
                      final path = await notifier.stopRecording();
                      if (context.mounted && path != null) {
                        HiToast.showPath(
                          context,
                          'Video saved',
                          path,
                          icon: Icons.videocam,
                        );
                      }
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedSwitcher(
                      duration: HiDurations.fast,
                      child: isScreenRec
                          ? _BlinkingVideoBadge(
                              key: const ValueKey('vid-on'), theme: theme)
                          : _Seg(
                              key: const ValueKey('vid-off'),
                              icon: Icons.videocam_outlined,
                              text: 'vid',
                              color: theme.textDim,
                            ),
                    ),
                  ),
                ),
              ),
              // Proxy (hide when narrow)
              if (hasProxy && !isNarrow) ...[
                const SizedBox(width: HiSpacing.md),
                _Seg(
                    icon: Icons.vpn_lock, text: 'proxy', color: Colors.amber),
              ],
              // Font size (hide when narrow)
              if (!isNarrow) ...[
                const SizedBox(width: HiSpacing.md),
                _Seg(
                  icon: Icons.text_fields,
                  text: '${settings.fontSize.round()}px',
                  color: theme.textDim,
                ),
              ],

              // === Separator ===
              const Spacer(),
              Container(
                width: 1,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: HiSpacing.md),
                color: theme.dividerColor,
              ),

              // === RIGHT: Actions group ===
              // RTL toggle
              Tooltip(
                message: rtlEnabled ? 'Disable RTL mode' : 'Enable RTL mode',
                child: GestureDetector(
                  onTap: () => ref.read(rtlEnabledProvider.notifier).toggle(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedSwitcher(
                      duration: HiDurations.fast,
                      child: _Seg(
                        key: ValueKey(rtlEnabled),
                        icon: Icons.format_textdirection_r_to_l,
                        text: rtlEnabled ? 'RTL' : 'LTR',
                        color: rtlEnabled ? theme.statusBarAccent : theme.textDim,
                        textColor: rtlEnabled ? theme.statusBarBackground : null,
                        filled: rtlEnabled,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: HiSpacing.md),
              // Env viewer
              Tooltip(
                message: 'Environment variables',
                child: GestureDetector(
                  onTap: () => showEnvViewer(context, theme),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: _Seg(
                        icon: Icons.settings_ethernet,
                        text: 'env',
                        color: theme.textDim),
                  ),
                ),
              ),
              const SizedBox(width: HiSpacing.md),
              // Theme — uses Builder so RenderBox is scoped to this widget
              Tooltip(
                message: 'Change theme',
                child: Builder(
                  builder: (themeButtonContext) => GestureDetector(
                    onTap: () => _showThemePicker(themeButtonContext, ref),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: _Seg(
                        icon: Icons.palette_outlined,
                        text: theme.name,
                        color: theme.statusBarAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: HiSpacing.md),
              // Settings
              Tooltip(
                message: 'Settings (Ctrl+,)',
                child: GestureDetector(
                  onTap: () => SettingsDialog.show(context),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: _Seg(
                      icon: Icons.settings_outlined,
                      text: 'Settings',
                      color: theme.textDim,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: HiSpacing.md),
              // Clock
              Text(_time,
                  style: HiTypography.small(theme.textDim, mono: true)),
            ],
          );
        },
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final buttonPos = button.localToGlobal(Offset.zero);
    final buttonSize = button.size;

    // Position menu above the theme button, right-aligned to it
    final menuHeight = BuiltInThemes.all.length * 48.0;
    final left = buttonPos.dx;
    final top = buttonPos.dy - menuHeight - 4;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        left,
        top,
        left + buttonSize.width,
        buttonPos.dy,
      ),
      color: currentTheme.tabActiveBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HiSizing.radiusLg),
        side: BorderSide(color: currentTheme.panelBorderInactive),
      ),
      items: BuiltInThemes.all.map((t) {
        return PopupMenuItem<String>(
          value: t.id,
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: t.terminalTheme.background,
                  border: Border.all(color: t.panelBorderActive, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                t.name,
                style: HiTypography.subtitle(
                  currentTheme.tabActiveText,
                  weight: t.id == currentTheme.id
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (t.id == currentTheme.id) ...[
                const Spacer(),
                Icon(Icons.check,
                    size: HiSizing.iconLg, color: currentTheme.statusBarAccent),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((selectedId) {
      if (selectedId != null && context.mounted) {
        ref.read(themeProvider.notifier).setTheme(selectedId);
        HiToast.show(context, 'Theme: ${BuiltInThemes.getById(selectedId).name}',
            icon: Icons.palette);
      }
    });
  }
}

class _Seg extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color? textColor;
  final bool filled;

  const _Seg({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.textColor,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: HiSizing.iconXs, color: textColor ?? Colors.white),
            const SizedBox(width: 3),
            Text(text,
                style: HiTypography.caption(textColor ?? Colors.white)
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: HiSizing.iconXs, color: color),
        const SizedBox(width: 3),
        Text(text, style: HiTypography.caption(color)),
      ],
    );
  }
}

/// Blinking red REC badge — visible pulsing dot to clearly indicate recording
class _BlinkingRecBadge extends StatefulWidget {
  final HiTerminalTheme theme;
  const _BlinkingRecBadge({super.key, required this.theme});

  @override
  State<_BlinkingRecBadge> createState() => _BlinkingRecBadgeState();
}

class _BlinkingRecBadgeState extends State<_BlinkingRecBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fiber_manual_record, size: 10, color: Colors.white),
            const SizedBox(width: 3),
            Text('REC',
                style: HiTypography.caption(Colors.white)
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Blinking orange VIDEO badge for screen recording
class _BlinkingVideoBadge extends StatefulWidget {
  final HiTerminalTheme theme;
  const _BlinkingVideoBadge({super.key, required this.theme});

  @override
  State<_BlinkingVideoBadge> createState() => _BlinkingVideoBadgeState();
}

class _BlinkingVideoBadgeState extends State<_BlinkingVideoBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.deepOrange,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, size: 10, color: Colors.white),
            const SizedBox(width: 3),
            Text('VID',
                style: HiTypography.caption(Colors.white)
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
