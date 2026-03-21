import QtQuick
import Quickshell
import Quickshell.Io
import "qs/Common"
import "qs/Services"
import "qs/Modals/DankSpotlight"

ShellRoot {
    id: root

    DankSpotlightModal {
        id: launcher

        Component.onCompleted: {
            if (Quickshell.env("SPOTLIGHT_START_HIDDEN") === "1")
                return;

            Qt.callLater(() => {
                launcher.show();
            });
        }
    }

    IpcHandler {
        id: launcherIpc
        target: "launcher"

        function toggle() {
            launcher.toggle();
        }

        function show() {
            launcher.show();
        }

        function hide() {
            launcher.hide();
        }
    }
}
