import 'package:flutter/material.dart';

import 'ui/shell/app_shell.dart';

class HiTerminalApp extends StatelessWidget {
  const HiTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiTerminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
      ),
      home: const AppShell(),
    );
  }
}
