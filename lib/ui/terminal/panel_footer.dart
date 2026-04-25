import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/terminal_theme_data.dart';
import '../../state/settings_state.dart';
import '../../state/theme_state.dart';

class PanelFooter extends ConsumerWidget {
  const PanelFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);

    if (!settings.showPanelFooter) return const SizedBox.shrink();

    final segments = settings.footerSegments;
    final env = Platform.environment;

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.tabBarBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
      ),
      child: Row(
        children: [
          if (segments.contains('shell'))
            _Segment(
              icon: Icons.terminal,
              text: _getShellName(),
              theme: theme,
            ),
          if (segments.contains('proxy')) _proxySegment(env, theme),
          if (segments.contains('ip'))
            _Segment(
              icon: Icons.language,
              text: _getIpHint(env),
              theme: theme,
            ),
          if (segments.contains('cwd'))
            _Segment(
              icon: Icons.folder_outlined,
              text: _getCwd(),
              theme: theme,
            ),
          if (segments.contains('env_count'))
            _Segment(
              icon: Icons.settings_ethernet,
              text: '${env.length} vars',
              theme: theme,
            ),
        ],
      ),
    );
  }

  String _getShellName() {
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['SHELL']?.split('/').last ?? 'sh';
    }
    return 'cmd';
  }

  Widget _proxySegment(Map<String, String> env, HiTerminalTheme theme) {
    final hasProxy = env.containsKey('http_proxy') ||
        env.containsKey('HTTP_PROXY') ||
        env.containsKey('https_proxy') ||
        env.containsKey('HTTPS_PROXY') ||
        env.containsKey('ALL_PROXY') ||
        env.containsKey('all_proxy');

    if (!hasProxy) {
      return _Segment(
        icon: Icons.vpn_lock_outlined,
        text: 'no proxy',
        theme: theme,
        dimmed: true,
      );
    }

    final proxyValue = env['http_proxy'] ??
        env['HTTP_PROXY'] ??
        env['https_proxy'] ??
        env['HTTPS_PROXY'] ??
        env['ALL_PROXY'] ??
        env['all_proxy'] ??
        '';

    // Extract host from proxy URL
    String display = 'proxy';
    try {
      final uri = Uri.parse(proxyValue);
      display = uri.host.isNotEmpty ? uri.host : 'proxy: set';
    } catch (_) {
      display = 'proxy: set';
    }

    return _Segment(
      icon: Icons.vpn_lock,
      text: display,
      theme: theme,
      accent: true,
    );
  }

  String _getIpHint(Map<String, String> env) {
    // Try common env vars for IP
    return env['SSH_CONNECTION']?.split(' ').lastOrNull ??
        env['HOSTNAME'] ??
        Platform.localHostname;
  }

  String _getCwd() {
    try {
      final cwd = Directory.current.path;
      final home = Platform.environment['HOME'] ?? '';
      if (home.isNotEmpty && cwd.startsWith(home)) {
        return '~${cwd.substring(home.length)}';
      }
      return cwd;
    } catch (_) {
      return '?';
    }
  }
}

class _Segment extends StatelessWidget {
  final IconData icon;
  final String text;
  final HiTerminalTheme theme;
  final bool dimmed;
  final bool accent;

  const _Segment({
    required this.icon,
    required this.text,
    required this.theme,
    this.dimmed = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent
        ? theme.statusBarAccent
        : dimmed
            ? theme.textDim
            : theme.statusBarForeground;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 9),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
