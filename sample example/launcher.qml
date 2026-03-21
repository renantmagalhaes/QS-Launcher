import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Window {
    id: launcher
    title: "qs-launcher"
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: Qt.rgba(0, 0, 0, 0.8)
    width: 560
    height: 360

    property string query: ""
    property var openWindows: []
    property string windowListBuffer: ""

    function activateWindow(windowId) {
        if (!windowId) {
            return;
        }

        if (windowId.startsWith('address:')) {
            // Hyprland focuses by structured address dispatcher args
            winOpProcess.command = ["hyprctl", "dispatch", "focuswindow", windowId];
        } else if (windowId.startsWith('0x')) {
            // older style address without prefix
            winOpProcess.command = ["hyprctl", "dispatch", "focuswindow", "address:" + windowId];
        } else {
            // X11 fallback
            winOpProcess.command = ["xdotool", "windowactivate", "--sync", windowId];
        }
        winOpProcess.running = true;
    }

    function launchSelected() {
        if (list.currentItem && list.currentItem.modelData) {
            const item = list.currentItem.modelData;
            if (item.windowId) {
                activateWindow(item.windowId);
            } else if (item.execute) {
                item.execute();
            }
            launcher.windowState = Qt.WindowMinimized; // minimize instead of hide
        }
    }

    Process {
        id: addressSaver
        command: ["sh", "-c", "echo " + Qt.application.pid + " > /tmp/qs-pid && hyprctl -j clients | jq -r '.[] | select(.title == \"qs-launcher\") | .address' > /tmp/qs-launcher-address"]
        running: false
    }

    Timer {
        interval: 3000
        running: true
        repeat: false
        onTriggered: addressSaver.running = true
    }

    Process {
        id: windowListProcess
        command: ["sh", "-c", "if command -v hyprctl >/dev/null 2>&1; then hyprctl -j clients 2>/dev/null | jq -c '.[]' 2>/dev/null; elif command -v wmctrl >/dev/null 2>&1; then wmctrl -lx 2>/dev/null; else echo ''; fi"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                launcher.windowListBuffer += data;
            }
        }

        onExited: function(exitStatus) {
            if (exitStatus !== 0) {
                console.warn("Could not read window list, exitStatus", exitStatus);
            }

            let parsed = [];
            const text = launcher.windowListBuffer.trim();

            if (text.startsWith('[')) {
                try {
                    const list = JSON.parse(text);
                    if (Array.isArray(list)) {
                        parsed = list.map(win => ({
                            name: (win.title || win.appId || win.class || "<unnamed>") + " [window]",
                            icon: "application-x-window",
                            windowId: win.address ? "address:" + win.address : (win.id ? win.id : ""),
                            isWindow: true,
                            kind: "window"
                        }));
                    }
                } catch (e) {
                    console.warn("hyprctl JSON parse failed", e);
                }
            } else if (text.length > 0) {
                const lines = text.split('\n').filter(l => l.trim().length);
                parsed = lines.map(line => {
                    const cols = line.trim().split(/\s+/);
                    const windowId = cols[0];
                    const classRaw = cols[2] || "";
                    const className = classRaw.split('.')[1] || classRaw;
                    const title = cols.slice(4).join(' ');
                    const displayName = title ? title : (className ? className : "<unnamed>");
                    return {
                        name: displayName,
                        icon: "application-x-window",
                        windowId: windowId,
                        isWindow: true,
                        kind: "window"
                    };
                });
            }

            launcher.openWindows = parsed;
            launcher.windowListBuffer = "";
        }
    }

    Timer {
        id: windowRefreshTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            windowListProcess.command = ["sh", "-c", "if command -v hyprctl >/dev/null 2>&1; then hyprctl -j clients 2>/dev/null; elif command -v wmctrl >/dev/null 2>&1; then wmctrl -lx 2>/dev/null; else echo ''; fi"];
            launcher.windowListBuffer = "";
            windowListProcess.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            IconImage {
                Layout.leftMargin: 10
                source: Quickshell.iconPath("nix-snowflake", true)
                Layout.preferredWidth: 25
                Layout.preferredHeight: 25
            }

            TextField {
                id: input
                Layout.fillWidth: true
                placeholderText: "Run…"
                font.pixelSize: 18
                color: "white"
                focus: true

                padding: 15

                onTextChanged: {
                    launcher.query = text;
                    // reset selection to first item of the filtered list
                    list.currentIndex = filtered.values.length > 0 ? 0 : -1;
                }

                background: Rectangle {
                    border.width: 0
                    color: "transparent"
                }

                // Quit
                Keys.onEscapePressed: launcher.windowState = Qt.WindowMinimized
                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key == Qt.Key_Up || event.key == Qt.Key_P && ctrl) {
                        event.accepted = true;
                        if (list.currentIndex > 0)
                            list.currentIndex--;
                    } else if (event.key == Qt.Key_Down || event.key == Qt.Key_N && ctrl) {
                        event.accepted = true;
                        if (list.currentIndex < list.count - 1)
                            list.currentIndex++;
                    } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
                        event.accepted = true;
                        launcher.launchSelected();
                    } else if (event.key == Qt.Key_C && ctrl) {
                        event.accepted = true;
                        Qt.quit(); // Ctrl+C to quit
                    } else if (event.key == Qt.Key_Q && ctrl) {
                        event.accepted = true;
                        Qt.quit(); // Ctrl+Q to quit
                    }
                }
            }
        }

        // Filtered model: apps + open windows matching the query
        ScriptModel {
            id: filtered
            values: {
                const appEntries = [...DesktopEntries.applications.values];
                const windowEntries = launcher.openWindows || [];
                const allEntries = [...appEntries, ...windowEntries];
                const q = launcher.query.trim().toLowerCase();

                if (q === "") {
                    return allEntries;
                } else {
                    return allEntries.filter(d => d.name && d.name.toLowerCase().includes(q));
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filtered.values
            currentIndex: filtered.values.length > 0 ? 0 : -1
            keyNavigationWraps: true
            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: 80
            highlight: Rectangle {
                radius: 4
                opacity: 0.45
                color: input.palette.highlight
            }

            delegate: Item {
                id: entry
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 36

                MouseArea {
                    anchors.fill: parent
                    onClicked: list.currentIndex = entry.index
                    onDoubleClicked: launcher.launchSelected()
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    IconImage {
                        source: Quickshell.iconPath(modelData.isWindow ? "application-x-window" : modelData.icon, true)
                        width: 23
                        height: 23
                    }
                    Text {
                        id: label
                        color: "white"
                        text: modelData.name
                        font.pointSize: 13
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Enter also works while ListView has focus
            Keys.onReturnPressed: launcher.launchSelected()
        }
    }
}
