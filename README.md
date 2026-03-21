# Spotlight

`Spotlight` is a standalone application launcher built with Quickshell.

This project was inspired by [AvengeMedia/DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), but the goal here is much narrower: most of the native shell pieces were stripped out so this can run as a focused launcher that replaces tools like `rofi`.

## What It Does

- Launch desktop applications from your installed desktop entries
- Switch to already open windows
- Evaluate quick calculator expressions directly in the search field
- Run as a small Quickshell daemon and expose IPC actions for `toggle`, `show`, and `hide`
- Start even when the desktop entry database is unavailable by falling back to a tiny mock app list

## How It Works

The included `spotlight` script is the main entrypoint.

When an instance is already running, it toggles the launcher through Quickshell IPC. If nothing is running yet, it starts Quickshell in daemon mode, waits for IPC to come up, and then shows the launcher.

```bash
./spotlight
```

## Manual Commands

Start the launcher directly:

```bash
quickshell -p main.qml
```

Start hidden in daemon mode:

```bash
SPOTLIGHT_START_HIDDEN=1 quickshell -d -n -p main.qml
```

Toggle an existing instance:

```bash
quickshell ipc --path main.qml call launcher toggle
```

Show or hide it explicitly:

```bash
quickshell ipc --path main.qml call launcher show
quickshell ipc --path main.qml call launcher hide
```

## Search Modes

- `All`: calculator, windows, and app results together
- `Windows`: only open windows
- `Apps`: only installed applications

Shortcuts inside the launcher:

- `Enter`: execute the selected result
- `Esc`: close the launcher
- `Up` / `Down`, `Tab` / `Shift+Tab`: move selection
- `Ctrl+1`: All
- `Ctrl+2`: Windows
- `Ctrl+3`: Apps

## Themes

Theme selection is controlled in `qs/Common/SettingsData.qml` through:

```qml
property string themeName: "default"
```

Available themes are currently:

- `default`
- `midnight`
- `dracula`
- `nord`
- `tokyo-night`
- `gruvbox`
- `rose-pine`
- `dark`
- `catppuccin`
- `dark-purple`

To switch themes, change it for example to:

```qml
property string themeName: "midnight"
```

To revert, set it back to `default`.

The actual palette definitions live in `qs/Common/Theme.qml`, so adding more themes is just a matter of adding another named palette there and selecting it with `themeName`.

## Window Switching Backends

Window lookup and focus use the first available backend:

- `hyprctl` on Hyprland
- `wmctrl` on other X11-capable environments
- `xdotool` as an activation fallback for some window IDs

## Example Keybinds

Hyprland:

```ini
bind = SUPER, Space, exec, /path/to/Spotlight/spotlight
```

Niri:

```ron
binds {
    Mod+Space { spawn "/path/to/Spotlight/spotlight"; }
}
```

## Notes

- Quickshell is required
- This repo is intentionally scoped as a standalone launcher, not a full desktop shell
- Assets, widgets, and styling from the original shell were kept where useful, but the overall target is a simple launcher workflow
