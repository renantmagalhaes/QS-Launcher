# Standalone Spotlight Launcher

A portable, standalone application launcher built with Quickshell.

## Features

- **Standalone Mode**: Runs without any external shell backend or IPC socket.
- **Backend Fallbacks**:
    - **Mock Apps**: Provides a curated list of applications (Firefox, Terminal, etc.) when the system application database is unavailable.
- **Window Switching**: Search and switch between open windows using `hyprctl` (Hyprland) or `wmctrl` (Other compositors).
- **Embedded Calculator**: Perform calculations directly in the search bar (e.g., `5*5+(10/2)`).
- **Default Theming**: Includes a premium Material 3 color palette for immediate use.
    - **Silent Execution**: Suppresses backend-related warnings and process errors.
- **IPC Support**: Can be toggled, shown, or hidden via the `quickshell ipc` command.
- **Relocated Assets**: All fonts, icons, shaders, and translations are self-contained.

## Usage

### 1. Launch the Shell
To open Spotlight immediately:

```bash
quickshell -p main.qml
```

To start it hidden in the background (daemon mode) for compositor autostart:

```bash
SPOTLIGHT_START_HIDDEN=1 quickshell -d -n -p main.qml
```

### 2. Toggle the Launcher
To show or hide the launcher while it is running:

```bash
quickshell ipc --path main.qml call launcher toggle
```

### 3. (Optional) Create a Shell Alias
Add this to your shell configuration (e.g., `~/.zshrc` or `~/.bashrc`):

```bash
alias spotlight='quickshell ipc --path main.qml call launcher toggle'
```

### 4. Start-Or-Toggle Helper
This repo includes a small helper script named `spotlight`. It toggles an existing instance, or starts the daemon hidden and then shows the launcher on first run:

```bash
./spotlight
```

## Shortcuts
Once launched, you can map the toggle command to a keyboard shortcut in your compositor (Hyprland, Sway, etc.) for quick access.

### Hyprland Example
```ini
bind = SUPER, Space, exec, quickshell ipc --path /path/to/Spotlight/main.qml call launcher toggle
```

### Niri Example
```ron
binds {
    Mod+Space { spawn "quickshell" "ipc" "--path" "/path/to/Spotlight/main.qml" "call" "launcher" "toggle"; }
}
```
