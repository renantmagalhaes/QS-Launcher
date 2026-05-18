pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../Common"

Item {
    id: root

    property var windows: []
    property string _windowListBuffer: ""

    function refreshWindows() {
        // We use the same logic as the user's example launcher, plus support for wlr-foreign-toplevel-management (wlrctl)
        windowListProcess.command = ["sh", "-c", "if [ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ] && command -v hyprctl >/dev/null 2>&1; then hyprctl -j clients 2>/dev/null; elif [ \"$XDG_CURRENT_DESKTOP\" = \"MangoWM\" ] || [ \"$XDG_CURRENT_DESKTOP\" = \"mango\" ] || [ \"$WAYLAND_DISPLAY\" != \"\" ]; then if command -v wlrctl >/dev/null 2>&1; then wlrctl toplevel list; elif command -v nix-shell >/dev/null 2>&1; then nix-shell -p wlrctl --run \"wlrctl toplevel list\"; fi; elif command -v wmctrl >/dev/null 2>&1; then wmctrl -lx 2>/dev/null; else echo ''; fi"];
        _windowListBuffer = "";
        windowListProcess.running = true;
    }

    function activateWindow(windowId) {
        if (!windowId) return;

        if (windowId.toString().startsWith("wlrctl:")) {
            // wlrctl focus
            const spec = windowId.toString().substring(7); // remove "wlrctl:"
            const pipeIdx = spec.indexOf("|");
            let appId = "";
            let title = "";
            if (pipeIdx !== -1) {
                appId = spec.substring(0, pipeIdx);
                title = spec.substring(pipeIdx + 1);
            } else {
                appId = spec;
            }
            
            let focusCommand = "";
            if (appId && title) {
                focusCommand = "if command -v wlrctl >/dev/null 2>&1; then wlrctl toplevel focus app_id:\"" + appId + "\" title:\"" + title + "\"; elif command -v nix-shell >/dev/null 2>&1; then nix-shell -p wlrctl --run \"wlrctl toplevel focus app_id:\\\"" + appId + "\\\" title:\\\"" + title + "\\\"\"; fi";
            } else if (appId) {
                focusCommand = "if command -v wlrctl >/dev/null 2>&1; then wlrctl toplevel focus app_id:\"" + appId + "\"; elif command -v nix-shell >/dev/null 2>&1; then nix-shell -p wlrctl --run \"wlrctl toplevel focus app_id:\\\"" + appId + "\\\"\"; fi";
            }
            winOpProcess.command = ["sh", "-c", focusCommand];
        } else if (windowId.toString().startsWith("address:")) {
            // Hyprland address
            winOpProcess.command = ["hyprctl", "dispatch", "focuswindow", windowId];
        } else if (windowId.toString().startsWith("0x")) {
            // Older style address or wmctrl ID
            if (CompositorService.isHyprland) {
                winOpProcess.command = ["hyprctl", "dispatch", "focuswindow", "address:" + windowId];
            } else {
                winOpProcess.command = ["wmctrl", "-ia", windowId];
            }
        } else {
            // X11 fallback
            winOpProcess.command = ["xdotool", "windowactivate", "--sync", windowId];
        }
        winOpProcess.running = true;
    }

    Process {
        id: windowListProcess
        running: false

        stdout: SplitParser {
            onRead: data => {
                root._windowListBuffer += data + "\n";
            }
        }

        onExited: (exitStatus) => {
            let parsed = [];
            const text = root._windowListBuffer.trim();

            if (text.startsWith("[")) {
                try {
                    const list = JSON.parse(text);
                    if (Array.isArray(list)) {
                        parsed = list.map(win => ({
                            id: win.address ? "address:" + win.address : (win.pid ? "pid:" + win.pid : win.title),
                            name: win.title || win.initialTitle || win.appId || win.class || "Unknown",
                            comment: win.initialTitle || win.class || "",
                            class: win.class || win.initialClass || win.appId || "",
                            icon: "application-x-window",
                            windowId: win.address ? "address:" + win.address : "",
                            isWindow: true,
                            workspace: win.workspace ? win.workspace.name : ""
                        }));
                    }
                } catch (e) {
                    console.warn("WindowSearchService: Hyprland JSON parse failed", e);
                }
            } else if (text.length > 0) {
                const lines = text.split("\n").filter(l => l.trim().length);
                if (lines.length > 0 && !lines[0].trim().startsWith("0x") && lines[0].includes(":")) {
                    parsed = lines.map(line => {
                        const colonIdx = line.indexOf(":");
                        let appId = "";
                        let title = "";
                        if (colonIdx !== -1) {
                            appId = line.substring(0, colonIdx).trim();
                            title = line.substring(colonIdx + 1).trim();
                        } else {
                            appId = line.trim();
                            title = appId;
                        }
                        
                        const id = "wlrctl:" + appId + "|" + title;
                        return {
                            id: id,
                            name: title || appId || "Unknown",
                            comment: appId || "",
                            class: appId || "",
                            icon: "application-x-window",
                            windowId: id,
                            isWindow: true
                        };
                    });
                } else {
                    parsed = lines.map(line => {
                        const cols = line.trim().split(/\s+/);
                        const windowId = cols[0];
                        const classRaw = cols[2] || "";
                        const className = classRaw.split(".")[1] || classRaw;
                        const title = cols.slice(4).join(" ");
                        return {
                            id: windowId,
                            name: title || className || "Unknown",
                            comment: className || "",
                            class: className || "",
                            icon: "application-x-window",
                            windowId: windowId,
                            isWindow: true
                        };
                    });
                }
            }

            root.windows = parsed;
            root._windowListBuffer = "";
        }
    }

    Process {
        id: winOpProcess
        running: false
    }
}
