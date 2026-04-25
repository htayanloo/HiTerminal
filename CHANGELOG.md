# Changelog

## v0.1.0 - 2026-04-25

### Initial Release

**Core Terminal**
- Cross-platform terminal emulator (macOS, Windows, Linux)
- xterm.dart + flutter_pty for terminal emulation and PTY
- 50K line scrollback buffer (configurable up to 500K)
- Platform shell auto-detection (zsh, bash, fish, cmd, powershell)

**RTL/Persian Support**
- BiDi text rendering overlay for correct RTL display
- RTL character detection for Arabic, Persian, Hebrew
- Persian-specific handling (ZWNJ, Persian digits, Yeh)
- Per-session RTL toggle (Ctrl+Shift+R)

**Split Panels**
- Horizontal and vertical panel splitting
- Binary split tree model for nested layouts
- Drag-and-drop panel rearrangement with visual drop zones
- Resizable dividers with hover/drag animations
- Editable panel titles (double-click to rename)
- Panel grouping support

**Tabs**
- Multiple tabs with independent terminal sessions
- Drag-and-drop tab reordering
- Animated close buttons

**Themes**
- 5 built-in themes: Catppuccin Mocha, Dracula, Nord, Solarized Dark, Tokyo Night
- 28 UI color properties per theme
- Real-time theme switching (Ctrl+Shift+K)
- Theme picker in status bar

**Command Palette**
- Searchable command list (Ctrl+Shift+P)
- Keyboard navigation (arrow keys + enter)
- All actions with shortcut hints

**Recording**
- Text session recording (commands + I/O with timestamps)
- Screen video recording (MP4 via FFmpeg streaming)
- Blinking REC/VID indicators in status bar
- Recording off by default, configurable in settings
- Copyable output path on stop

**Command History**
- In-memory command tracking (always active)
- Disk persistence (when recording enabled)
- Searchable across all sessions
- Copy/paste commands back to terminal

**Settings**
- Appearance: theme picker with color previews, window opacity
- Font: size slider, 10 monospace font families with preview
- Profile: RTL toggle, recording settings, scrollback, panel footer
- Footer: keyboard shortcuts reference

**Status Bar**
- Shell badge, panel info, recording indicators
- Proxy detection, font size, RTL toggle
- Theme picker, env viewer, settings access
- Clock, tooltips on all items
- Responsive hiding for narrow windows

**Environment Viewer**
- Searchable env variable browser (Ctrl+Shift+I)
- Proxy variable highlighting
- Important variable starring

**UI Polish**
- Design token system (spacing, sizing, typography, animation)
- Animated dividers (hover/drag states)
- Dialog fade+scale transitions
- Button press feedback (scale animation)
- Toast notifications with copyable paths
- Custom window controls for Windows/Linux

**CI/CD**
- GitHub Actions workflow for macOS, Windows, Linux builds
- Auto-release on version tags with DMG/ZIP/tar.gz
