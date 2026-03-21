pragma Singleton
pragma ComponentBehavior: Bound

import QtQml

QtObject {
    id: root

    property bool isLightMode: false
    property string launcherLastMode: "all"

    function setLauncherLastMode(mode) {
        launcherLastMode = mode || "all";
    }

    function getAppOverride(appId) {
        return null;
    }
}
