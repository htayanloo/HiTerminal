import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/recording/history_manager.dart';
import '../../core/recording/session_recorder.dart';
import '../../core/theme/terminal_theme_data.dart';
import '../../state/tab_state.dart';
import '../../state/theme_state.dart';
import 'design_tokens.dart';
import 'toast.dart';

void showHistoryViewer(BuildContext context) {
  showAnimatedDialog(
    context: context,
    builder: (_) => const _HistoryViewerDialog(),
  );
}

class _HistoryViewerDialog extends ConsumerStatefulWidget {
  const _HistoryViewerDialog();

  @override
  ConsumerState<_HistoryViewerDialog> createState() =>
      _HistoryViewerDialogState();
}

class _HistoryViewerDialogState extends ConsumerState<_HistoryViewerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _historyManager = HistoryManager();

  // Current session commands
  List<CommandEntry> _currentCommands = [];

  // All sessions
  List<SessionInfo> _sessions = [];
  bool _loadingSessions = true;

  // Search results
  List<CommandEntry> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentCommands();
    _loadSessions();
    _searchController.addListener(_onSearch);
  }

  void _loadCurrentCommands() {
    final tabState = ref.read(tabListProvider);
    final activeTab = tabState.activeTab;
    final panel = activeTab.panels[activeTab.activePanelId];
    if (panel != null) {
      setState(() {
        _currentCommands = panel.session.recorder.commands;
      });
    }
  }

  Future<void> _loadSessions() async {
    final sessions = await _historyManager.listSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _loadingSessions = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchController.text;
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _historyManager.searchCommands(query).then((results) {
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        width: 700,
        height: 550,
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.tabBarBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: theme.statusBarAccent, size: 20),
                  const SizedBox(width: 8),
                  Text('Command History',
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
                          Icon(Icons.close, color: theme.textDim, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              color: theme.tabBarBackground,
              child: TabBar(
                controller: _tabController,
                labelColor: theme.tabActiveText,
                unselectedLabelColor: theme.textDim,
                indicatorColor: theme.statusBarAccent,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Current Session'),
                  Tab(text: 'All Sessions'),
                  Tab(text: 'Search'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCurrentSession(theme),
                  _buildAllSessions(theme),
                  _buildSearch(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSession(HiTerminalTheme theme) {
    if (_currentCommands.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 48, color: theme.textDim),
            const SizedBox(height: 12),
            Text('No commands yet in this session',
                style: TextStyle(color: theme.textDim, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.tabActiveBackground,
          child: Row(
            children: [
              Icon(Icons.circle, size: 8, color: Colors.green),
              const SizedBox(width: 8),
              Text('Recording active',
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_currentCommands.length} commands',
                  style: TextStyle(color: theme.textDim, fontSize: 11)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: _currentCommands.length,
            itemBuilder: (context, index) {
              final cmd = _currentCommands[_currentCommands.length - 1 - index];
              return _CommandTile(
                command: cmd,
                theme: theme,
                onCopy: () => _copyCommand(cmd.command),
                onPaste: () => _pasteToTerminal(cmd.command),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllSessions(HiTerminalTheme theme) {
    if (_loadingSessions) {
      return Center(
          child: CircularProgressIndicator(color: theme.statusBarAccent));
    }

    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: theme.textDim),
            const SizedBox(height: 12),
            Text('No recorded sessions yet',
                style: TextStyle(color: theme.textDim, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _SessionTile(
          session: session,
          theme: theme,
          onTap: () => _showSessionCommands(context, session, theme),
          onDelete: () async {
            await _historyManager.deleteSession(session);
            _loadSessions();
          },
        );
      },
    );
  }

  Widget _buildSearch(HiTerminalTheme theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: theme.tabActiveText, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search all command history...',
              hintStyle: TextStyle(color: theme.textDim),
              prefixIcon: Icon(Icons.search, color: theme.textDim, size: 18),
              filled: true,
              fillColor: theme.tabActiveBackground,
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
        if (_searching)
          Padding(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(color: theme.statusBarAccent),
          )
        else if (_searchResults.isEmpty && _searchController.text.length >= 2)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No results found',
                style: TextStyle(color: theme.textDim)),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final cmd = _searchResults[index];
                return _CommandTile(
                  command: cmd,
                  theme: theme,
                  onCopy: () => _copyCommand(cmd.command),
                  onPaste: () => _pasteToTerminal(cmd.command),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showSessionCommands(
      BuildContext context, SessionInfo session, HiTerminalTheme theme) async {
    final commands = await _historyManager.loadCommands(session.commandFile);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.panelBorderInactive),
        ),
        child: SizedBox(
          width: 600,
          height: 450,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.tabBarBackground,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description,
                        color: theme.statusBarAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(session.baseName,
                          style: TextStyle(
                              color: theme.tabActiveText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${commands.length} commands',
                        style:
                            TextStyle(color: theme.textDim, fontSize: 11)),
                    const SizedBox(width: 12),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.close,
                            color: theme.textDim, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: commands.isEmpty
                    ? Center(
                        child: Text('No commands in this session',
                            style: TextStyle(color: theme.textDim)))
                    : ListView.builder(
                        itemCount: commands.length,
                        itemBuilder: (ctx, i) => _CommandTile(
                          command: commands[i],
                          theme: theme,
                          onCopy: () => _copyCommand(commands[i].command),
                          onPaste: () =>
                              _pasteToTerminal(commands[i].command),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyCommand(String command) {
    Clipboard.setData(ClipboardData(text: command));
    HiToast.show(context, 'Copied to clipboard', icon: Icons.copy);
  }

  void _pasteToTerminal(String command) {
    final tabState = ref.read(tabListProvider);
    final panel =
        tabState.activeTab.panels[tabState.activeTab.activePanelId];
    if (panel != null) {
      panel.session.terminal.paste(command);
    }
    Navigator.of(context).pop();
  }
}

class _CommandTile extends StatefulWidget {
  final CommandEntry command;
  final HiTerminalTheme theme;
  final VoidCallback onCopy;
  final VoidCallback onPaste;

  const _CommandTile({
    required this.command,
    required this.theme,
    required this.onCopy,
    required this.onPaste,
  });

  @override
  State<_CommandTile> createState() => _CommandTileState();
}

class _CommandTileState extends State<_CommandTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final time = widget.command.timestamp;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: _hovered ? t.tabActiveBackground : Colors.transparent,
        child: Row(
          children: [
            Text(
              timeStr,
              style: TextStyle(
                  color: t.textDim, fontSize: 10, fontFamily: 'monospace'),
            ),
            const SizedBox(width: 12),
            Text('\$', style: TextStyle(color: t.statusBarAccent, fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.command.command,
                style: TextStyle(
                  color: t.tabActiveText,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_hovered) ...[
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onCopy,
                  child: Tooltip(
                    message: 'Copy',
                    child: Icon(Icons.copy_outlined, size: 14, color: t.textDim),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onPaste,
                  child: Tooltip(
                    message: 'Paste to terminal',
                    child:
                        Icon(Icons.send_outlined, size: 14, color: t.statusBarAccent),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatefulWidget {
  final SessionInfo session;
  final HiTerminalTheme theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final s = widget.session;
    final date = s.startedAt;
    final dateStr = date != null
        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : 'Unknown';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _hovered ? t.tabActiveBackground : Colors.transparent,
          child: Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: t.statusBarAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr,
                        style: TextStyle(
                            color: t.tabActiveText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '${s.commandCount} commands  •  ${s.formattedSize}',
                      style: TextStyle(color: t.textDim, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (_hovered)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Icon(Icons.delete_outline,
                        size: 16, color: t.textDim),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 16, color: t.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
