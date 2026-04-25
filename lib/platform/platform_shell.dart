import 'dart:io';

class PlatformShell {
  static String get defaultShell {
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['SHELL'] ?? '/bin/bash';
    } else if (Platform.isWindows) {
      return Platform.environment['COMSPEC'] ?? 'cmd.exe';
    }
    return '/bin/sh';
  }

  static List<String> get defaultShellArgs {
    final shell = defaultShell;
    if (Platform.isMacOS || Platform.isLinux) {
      // Use login shell for proper profile loading
      if (shell.endsWith('/zsh') || shell.endsWith('/bash') || shell.endsWith('/fish')) {
        return ['-l'];
      }
    }
    return [];
  }

  static Map<String, String> get defaultEnvironment {
    final env = Map<String, String>.from(Platform.environment);
    env['TERM'] = 'xterm-256color';
    env['COLORTERM'] = 'truecolor';
    return env;
  }
}
