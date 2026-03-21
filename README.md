# Standalone Spotlight Launcher

A portable, standalone version of the DankMaterialShell Spotlight launcher, designed to run independently of the `dms` Go backend and IPC socket.

## Features

- **Standalone Mode**: Runs without the `dms` binary or IPC socket.
- **Backend Fallbacks**:
    - **Mock Apps**: Provides a curated list of applications (Firefox, Terminal, etc.) when the system application database is unavailable.
    - **Default Theming**: Includes a premium Material 3 color palette for immediate use.
    - **Silent Execution**: Suppresses backend-related warnings and process errors.
- **IPC Support**: Can be toggled, shown, or hidden via the `quickshell ipc` command.
- **Relocated Assets**: All fonts, icons, shaders, and translations are self-contained.

## Usage

### 1. Launch the Shell
To start the Spotlight launcher in the background (daemon mode) and prevent duplicate instances:

```bash
quickshell -d -n -p main.qml
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
