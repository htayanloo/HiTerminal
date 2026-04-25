# HiTerminal

A powerful cross-platform terminal emulator built with Flutter, featuring first-class RTL/Persian language support.

## Features

- **Cross-Platform** - Runs on macOS, Windows, and Linux
- **RTL Support** - Correct rendering of Persian, Arabic, and Hebrew text with BiDi algorithm
- **Split Panels** - Horizontal and vertical splits with drag-and-drop rearrangement
- **Tabs** - Multiple tabs with drag reordering
- **5 Built-in Themes** - Catppuccin Mocha, Dracula, Nord, Solarized Dark, Tokyo Night
- **Command Palette** - Quick access to all commands (Ctrl+Shift+P)
- **Session Recording** - Text logging and screen video recording (MP4 via FFmpeg)
- **Command History** - Searchable history across all sessions
- **Environment Viewer** - Browse and search environment variables
- **Settings** - Font size/family, themes, profiles, recording, scrollback configuration
- **Panel Footer** - Per-panel environment info (shell, proxy, IP, CWD)
- **Right-Click Context Menu** - Split, rename, copy, paste, clear, and more
- **50K Line Scrollback** - Configurable up to 500K lines
- **Toast Notifications** - Visual feedback for actions
- **Window Controls** - Custom title bar with controls on Windows/Linux

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl+Shift+P` | Command Palette |
| `Ctrl+Shift+T` | New Tab |
| `Ctrl+Shift+W` | Close Tab |
| `Ctrl+Tab` | Next Tab |
| `Ctrl+Shift+Tab` | Previous Tab |
| `Ctrl+Shift+H` | Split Horizontal |
| `Ctrl+Shift+E` | Split Vertical |
| `Ctrl+Shift+X` | Close Panel |
| `Ctrl+]` / `Ctrl+[` | Focus Next/Previous Panel |
| `Ctrl+Shift+R` | Toggle RTL |
| `Ctrl+Shift+K` | Cycle Theme |
| `Ctrl+,` | Settings |
| `Ctrl+Shift+I` | Environment Variables |
| `Ctrl+Shift+Y` | Command History |
| `Ctrl+=` / `Ctrl+-` | Zoom In/Out |

## Screenshots

*Coming soon*

## Building from Source

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.41.2+)
- For video recording: [FFmpeg](https://ffmpeg.org/)

### Build

```bash
# Get dependencies
flutter pub get

# Build for your platform
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

### Run in development

```bash
flutter run -d macos    # or windows, linux
```

### Linux Dependencies

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

## Architecture

```
lib/
├── core/           # Business logic (terminal, RTL, themes, recording)
├── state/          # Riverpod state management
├── ui/             # Flutter widgets
│   ├── shell/      # App shell, tab bar, status bar
│   ├── terminal/   # Terminal panel, RTL overlay, footer
│   ├── panels/     # Split panel system
│   ├── settings/   # Settings dialog
│   └── common/     # Shared widgets (palette, menus, toasts)
└── platform/       # Platform-specific code
```

## CI/CD

GitHub Actions builds for all 3 platforms on every push to `main`. Tagged releases (`v*`) automatically create GitHub Releases with downloadable binaries.

## License

MIT
