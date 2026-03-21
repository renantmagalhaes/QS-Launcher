pragma Singleton
pragma ComponentBehavior: Bound

import QtQml
import Quickshell

QtObject {
    id: root

    readonly property bool isHyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
    readonly property bool useHyprlandFocusGrab: isHyprland

    function getFocusedScreen() {
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function getScreenScale(screen) {
        return screen?.devicePixelRatio ?? 1;
    }
}
