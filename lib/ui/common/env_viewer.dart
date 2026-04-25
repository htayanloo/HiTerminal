import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../core/theme/terminal_theme_data.dart';
import 'design_tokens.dart';

void showEnvViewer(BuildContext context, HiTerminalTheme theme) {
  showAnimatedDialog(
    context: context,
    builder: (_) => EnvViewerDialog(theme: theme),
  );
}

class EnvViewerDialog extends StatefulWidget {
  final HiTerminalTheme theme;

  const EnvViewerDialog({super.key, required this.theme});

  @override
  State<EnvViewerDialog> createState() => _EnvViewerDialogState();
}

class _EnvViewerDialogState extends State<EnvViewerDialog> {
  final _searchController = TextEditingController();
  late final Map<String, String> _env;
  List<MapEntry<String, String>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _env = Map<String, String>.from(Platform.environment);
    _filtered = _env.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _env.entries
          .where((e) =>
              e.key.toLowerCase().contains(q) ||
              e.value.toLowerCase().contains(q))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    // Highlight important vars
    final proxyVars = _filtered.where((e) => _isProxyVar(e.key)).toList();

    return Dialog(
      backgroundColor: t.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: t.panelBorderInactive),
      ),
      child: SizedBox(
        width: 650,
        height: 520,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.settings_ethernet,
                      color: t.statusBarAccent, size: 20),
                  const SizedBox(width: 8),
                  Text('Environment Variables',
                      style: TextStyle(
                          color: t.tabActiveText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.statusBarAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_filtered.length}',
                        style: TextStyle(
                            color: t.statusBarBackground,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: t.textDim, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: t.tabActiveText, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search variables... (try "proxy", "path", "home")',
                  hintStyle: TextStyle(color: t.textDim),
                  prefixIcon: Icon(Icons.search, color: t.textDim, size: 18),
                  filled: true,
                  fillColor: t.tabActiveBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Proxy summary bar
            if (proxyVars.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: t.statusBarAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: t.statusBarAccent.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.vpn_lock,
                        size: 14, color: t.statusBarAccent),
                    const SizedBox(width: 8),
                    Text(
                      '${proxyVars.length} proxy variable(s) detected',
                      style: TextStyle(
                          color: t.statusBarAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            if (proxyVars.isNotEmpty) const SizedBox(height: 4),
            // Variables list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final entry = _filtered[index];
                  final isProxy = _isProxyVar(entry.key);
                  final isPath = entry.key == 'PATH';
                  final isImportant = _isImportantVar(entry.key);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isProxy
                          ? t.statusBarAccent.withAlpha(13)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                            color: t.panelBorderInactive.withAlpha(51)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isProxy)
                          Padding(
                            padding: const EdgeInsets.only(right: 4, top: 1),
                            child: Icon(Icons.vpn_lock,
                                size: 11, color: t.statusBarAccent),
                          )
                        else if (isImportant)
                          Padding(
                            padding: const EdgeInsets.only(right: 4, top: 1),
                            child: Icon(Icons.star,
                                size: 11, color: Colors.amber),
                          )
                        else
                          const SizedBox(width: 15),
                        SizedBox(
                          width: 200,
                          child: SelectableText(
                            entry.key,
                            style: TextStyle(
                              color: isProxy
                                  ? t.statusBarAccent
                                  : isPath
                                      ? Colors.amber
                                      : isImportant
                                          ? t.tabActiveText
                                          : t.statusBarForeground,
                              fontSize: 11,
                              fontWeight: isProxy || isImportant
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            entry.value,
                            style: TextStyle(
                              color: t.statusBarForeground.withAlpha(204),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isProxyVar(String key) {
    final k = key.toLowerCase();
    return k.contains('proxy');
  }

  bool _isImportantVar(String key) {
    const important = {
      'HOME', 'USER', 'SHELL', 'PATH', 'LANG', 'TERM',
      'EDITOR', 'VISUAL', 'SSH_AUTH_SOCK', 'DISPLAY',
      'XDG_RUNTIME_DIR', 'HOSTNAME', 'PWD', 'OLDPWD',
    };
    return important.contains(key);
  }
}
