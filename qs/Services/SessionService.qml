pragma Singleton
pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../Common"

Item {
    id: root

    property string nvidiaCommand: ""

    Process {
        id: detectPrimeRun
        command: ["sh", "-c", "command -v prime-run >/dev/null 2>&1 && printf prime-run"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.nvidiaCommand = text.trim();
            }
        }
    }

    function _exec(command, workingDirectory) {
        Quickshell.execDetached({
            command: command,
            workingDirectory: workingDirectory || Quickshell.env("HOME")
        });
    }

    function _withPrefix(command) {
        const prefix = (SettingsData.launchPrefix || "").trim();
        if (!prefix)
            return command;
        return prefix.split(/\s+/).filter(arg => arg.length > 0).concat(command);
    }

    function launchDesktopEntry(desktopEntry, useNvidia) {
        if (!desktopEntry || !desktopEntry.command || desktopEntry.command.length === 0)
            return;
        let cmd = desktopEntry.command.slice();
        if (useNvidia && nvidiaCommand)
            cmd = [nvidiaCommand].concat(cmd);
        _exec(_withPrefix(cmd), desktopEntry.workingDirectory);
    }

    function launchDesktopAction(desktopEntry, action, useNvidia) {
        if (!action || !action.command || action.command.length === 0)
            return;
        let cmd = action.command.slice();
        if (useNvidia && nvidiaCommand)
            cmd = [nvidiaCommand].concat(cmd);
        _exec(_withPrefix(cmd), desktopEntry?.workingDirectory);
    }
}
