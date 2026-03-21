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
        // We use the same logic as the user's example launcher
        windowListProcess.command = ["sh", "-c", "if command -v hyprctl >/dev/null 2>&1; then hyprctl -j clients 2>/dev/null; elif command -v wmctrl >/dev/null 2>&1; then wmctrl -lx 2>/dev/null; else echo ''; fi"];
        _windowListBuffer = "";
        windowListProcess.running = true;
    }

    function activateWindow(windowId) {
        if (!windowId) return;

        if (windowId.toString().startsWith("address:")) {
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
                root._windowListBuffer += data;
            }
        }

        onExited: (exitStatus) => {
            let parsed = [];
            const text = root._windowListBuffer.trim();

            if (text.startsWith("[")) {
                // Hyprland JSON output
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
                // wmctrl output
                const lines = text.split("\n").filter(l => l.trim().length);
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

            root.windows = parsed;
            root._windowListBuffer = "";
        }
    }

    Process {
        id: winOpProcess
        running: false
    }
}
