import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/built_in_themes.dart';
import '../../core/theme/terminal_theme_data.dart';
import '../../state/rtl_state.dart';
import '../../state/settings_state.dart';
import '../../state/theme_state.dart';
import '../common/design_tokens.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  static void show(BuildContext context) {
    showAnimatedDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return Dialog(
      backgroundColor: theme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.panelBorderInactive),
      ),
      child: SizedBox(
        width: 600,
        height: 520,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.tabBarBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: theme.statusBarAccent, size: 20),
                  const SizedBox(width: 8),
                  Text('Settings',
                      style: TextStyle(
                          color: theme.tabActiveText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child:
                          Icon(Icons.close, color: theme.textDim, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              color: theme.tabBarBackground,
              child: TabBar(
                controller: _tabController,
                labelColor: theme.tabActiveText,
                unselectedLabelColor: theme.textDim,
                indicatorColor: theme.statusBarAccent,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Appearance'),
                  Tab(text: 'Font'),
                  Tab(text: 'Profile'),
                  Tab(text: 'Footer'),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AppearanceTab(theme: theme),
                  _FontTab(theme: theme),
                  _ProfileTab(theme: theme),
                  _FooterTab(theme: theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceTab extends ConsumerWidget {
  final HiTerminalTheme theme;
  const _AppearanceTab({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Theme', theme),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BuiltInThemes.all.map((t) {
            final isSelected = t.id == currentTheme.id;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => ref.read(themeProvider.notifier).setTheme(t.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? t.panelBorderActive
                          : t.panelBorderInactive,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t.name,
                              style: TextStyle(
                                  color: t.terminalTheme.foreground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          if (isSelected) ...[
                            const Spacer(),
                            Icon(Icons.check,
                                size: 14, color: t.panelBorderActive),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Color preview
                      Row(
                        children: [
                          _colorDot(t.terminalTheme.red),
                          _colorDot(t.terminalTheme.green),
                          _colorDot(t.terminalTheme.yellow),
                          _colorDot(t.terminalTheme.blue),
                          _colorDot(t.terminalTheme.magenta),
                          _colorDot(t.terminalTheme.cyan),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _SectionHeader('Window Opacity', theme),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: settings.opacity,
                min: 0.3,
                max: 1.0,
                activeColor: theme.statusBarAccent,
                inactiveColor: theme.panelBorderInactive,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setOpacity(v),
              ),
            ),
            SizedBox(
              width: 45,
              child: Text(
                '${(settings.opacity * 100).round()}%',
                style: TextStyle(color: theme.tabActiveText, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _FontTab extends ConsumerWidget {
  final HiTerminalTheme theme;
  const _FontTab({required this.theme});

  static const _fonts = [
    'Menlo',
    'Monaco',
    'Courier New',
    'Consolas',
    'SF Mono',
    'Fira Code',
    'JetBrains Mono',
    'Source Code Pro',
    'Ubuntu Mono',
    'IBM Plex Mono',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Font Size', theme),
        const SizedBox(height: 8),
        Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setFontSize(settings.fontSize - 1),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.tabActiveBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.remove, size: 16, color: theme.tabActiveText),
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: settings.fontSize,
                min: 8,
                max: 32,
                divisions: 24,
                activeColor: theme.statusBarAccent,
                inactiveColor: theme.panelBorderInactive,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setFontSize(v),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setFontSize(settings.fontSize + 1),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.tabActiveBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add, size: 16, color: theme.tabActiveText),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '${settings.fontSize.round()}px',
                style: TextStyle(
                    color: theme.tabActiveText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader('Font Family', theme),
        const SizedBox(height: 8),
        ...List.generate(_fonts.length, (i) {
          final font = _fonts[i];
          final isSelected = font == settings.fontFamily;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () =>
                  ref.read(settingsProvider.notifier).setFontFamily(font),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.tabActiveBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hello World سلام',
                        style: TextStyle(
                          fontFamily: font,
                          color: theme.tabActiveText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      font,
                      style: TextStyle(color: theme.textDim, fontSize: 11),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check,
                          size: 16, color: theme.statusBarAccent),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  final HiTerminalTheme theme;
  const _ProfileTab({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rtlEnabled = ref.watch(rtlEnabledProvider);
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('RTL / Persian Support', theme),
        const SizedBox(height: 8),
        _ToggleSetting(
          label: 'Enable RTL Mode',
          description: 'Render right-to-left text correctly (Persian, Arabic, Hebrew)',
          value: rtlEnabled,
          onChanged: (_) => ref.read(rtlEnabledProvider.notifier).toggle(),
          theme: theme,
        ),
        const SizedBox(height: 20),
        _SectionHeader('Session Recording', theme),
        const SizedBox(height: 8),
        _ToggleSetting(
          label: 'Enable Recording by Default',
          description: 'New sessions will auto-record to disk. Disabled by default.',
          value: settings.recordingEnabled,
          onChanged: (_) => ref
              .read(settingsProvider.notifier)
              .setRecordingEnabled(!settings.recordingEnabled),
          theme: theme,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.tabActiveBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recording Path',
                  style: TextStyle(color: theme.tabActiveText, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                'Where session recordings are saved',
                style: TextStyle(color: theme.textDim, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.panelBorderInactive),
                      ),
                      child: Text(
                        settings.recordingPath,
                        style: TextStyle(
                          color: theme.statusBarForeground,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _editRecordingPath(context, ref, settings, theme),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.statusBarAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Change',
                            style: TextStyle(
                                color: theme.statusBarBackground,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader('Scrollback History', theme),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.tabActiveBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Max scrollback lines',
                      style: TextStyle(color: theme.tabActiveText, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${settings.scrollbackLines} lines',
                    style: TextStyle(
                      color: theme.statusBarAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Higher values use more memory. Applied to new panels only.',
                style: TextStyle(color: theme.textDim, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('1K', style: TextStyle(color: theme.textDim, fontSize: 10)),
                  Expanded(
                    child: Slider(
                      value: settings.scrollbackLines.toDouble(),
                      min: 1000,
                      max: 500000,
                      divisions: 49,
                      activeColor: theme.statusBarAccent,
                      inactiveColor: theme.panelBorderInactive,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setScrollbackLines(v.round()),
                    ),
                  ),
                  Text('500K', style: TextStyle(color: theme.textDim, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader('Panel Footer', theme),
        const SizedBox(height: 8),
        _ToggleSetting(
          label: 'Show Panel Footer',
          description: 'Display environment info bar at the bottom of each panel',
          value: settings.showPanelFooter,
          onChanged: (_) =>
              ref.read(settingsProvider.notifier).togglePanelFooter(),
          theme: theme,
        ),
        const SizedBox(height: 20),
        _SectionHeader('Footer Segments', theme),
        const SizedBox(height: 8),
        _SegmentToggle('shell', 'Shell Name', settings, ref, theme),
        _SegmentToggle('proxy', 'Proxy Status', settings, ref, theme),
        _SegmentToggle('ip', 'IP Address', settings, ref, theme),
        _SegmentToggle('cwd', 'Working Directory', settings, ref, theme),
        _SegmentToggle('env_count', 'Env Var Count', settings, ref, theme),
      ],
    );
  }

  void _editRecordingPath(BuildContext context, WidgetRef ref,
      AppSettings settings, HiTerminalTheme theme) {
    final controller = TextEditingController(text: settings.recordingPath);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.background,
        title: Text('Recording Path',
            style: TextStyle(color: theme.tabActiveText, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the directory path for session recordings:',
                style: TextStyle(color: theme.textDim, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(
                  color: theme.tabActiveText,
                  fontSize: 13,
                  fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.tabActiveBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setRecordingPath(value);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.textDim)),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setRecordingPath(controller.text);
              Navigator.of(ctx).pop();
            },
            child: Text('Save',
                style: TextStyle(color: theme.statusBarAccent)),
          ),
        ],
      ),
    );
  }

  Widget _SegmentToggle(String id, String label, AppSettings settings,
      WidgetRef ref, HiTerminalTheme theme) {
    final enabled = settings.footerSegments.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _ToggleSetting(
        label: label,
        description: null,
        value: enabled,
        onChanged: (_) {
          final segments = List<String>.from(settings.footerSegments);
          if (enabled) {
            segments.remove(id);
          } else {
            segments.add(id);
          }
          ref.read(settingsProvider.notifier).setFooterSegments(segments);
        },
        theme: theme,
      ),
    );
  }
}

class _FooterTab extends ConsumerWidget {
  final HiTerminalTheme theme;
  const _FooterTab({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Panel Footer Preview', theme),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.tabBarBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.panelBorderInactive),
          ),
          child: Row(
            children: [
              if (settings.footerSegments.contains('shell'))
                _footerChip('fish', Icons.terminal, theme),
              if (settings.footerSegments.contains('proxy'))
                _footerChip('proxy: set', Icons.vpn_lock, theme),
              if (settings.footerSegments.contains('ip'))
                _footerChip('192.168.1.x', Icons.language, theme),
              if (settings.footerSegments.contains('cwd'))
                _footerChip('~/project', Icons.folder_outlined, theme),
              if (settings.footerSegments.contains('env_count'))
                _footerChip('42 vars', Icons.settings_ethernet, theme),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The panel footer shows environment information at the bottom of each terminal panel. '
          'Toggle segments in the Profile tab.',
          style: TextStyle(color: theme.textDim, fontSize: 12),
        ),
        const SizedBox(height: 20),
        _SectionHeader('Keyboard Shortcuts', theme),
        const SizedBox(height: 8),
        ..._shortcuts.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(s.$1,
                        style:
                            TextStyle(color: theme.tabActiveText, fontSize: 12)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.tabActiveBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(s.$2,
                        style: TextStyle(
                            color: theme.textDim,
                            fontSize: 11,
                            fontFamily: 'monospace')),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _footerChip(String text, IconData icon, HiTerminalTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.statusBarAccent),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(color: theme.statusBarForeground, fontSize: 10)),
        ],
      ),
    );
  }

  static const _shortcuts = [
    ('New Tab', 'Ctrl+Shift+T'),
    ('Close Tab', 'Ctrl+Shift+W'),
    ('Next Tab', 'Ctrl+Tab'),
    ('Previous Tab', 'Ctrl+Shift+Tab'),
    ('Split Horizontal', 'Ctrl+Shift+H'),
    ('Split Vertical', 'Ctrl+Shift+E'),
    ('Close Panel', 'Ctrl+Shift+X'),
    ('Focus Next Panel', 'Ctrl+]'),
    ('Focus Previous Panel', 'Ctrl+['),
    ('Toggle RTL', 'Ctrl+Shift+R'),
    ('Cycle Theme', 'Ctrl+Shift+K'),
    ('Command Palette', 'Ctrl+Shift+P'),
    ('Settings', 'Ctrl+,'),
    ('Environment Variables', 'Ctrl+Shift+I'),
  ];
}

// Shared widgets
class _SectionHeader extends StatelessWidget {
  final String title;
  final HiTerminalTheme theme;
  const _SectionHeader(this.title, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: theme.statusBarAccent,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final HiTerminalTheme theme;

  const _ToggleSetting({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.tabActiveBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(color: theme.tabActiveText, fontSize: 13)),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(description!,
                        style: TextStyle(color: theme.textDim, fontSize: 11)),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.statusBarAccent,
          ),
        ],
      ),
    );
  }
}
