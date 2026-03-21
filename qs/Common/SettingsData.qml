pragma Singleton
pragma ComponentBehavior: Bound

import QtQml

QtObject {
    id: root

    enum AnimationSpeed {
        None,
        Short,
        Medium,
        Long
    }

    property int animationSpeed: SettingsData.AnimationSpeed.Short
    property bool enableRippleEffects: true
    property bool sortAppsAlphabetically: true
    property int appLauncherGridColumns: 4
    property var spotlightSectionViewModes: ({})
    property var appDrawerSectionViewModes: ({})
    property string themeName: "default"

    property string dankLauncherV2Size: "small"
    property bool dankLauncherV2UnloadOnClose: false
    property bool dankLauncherV2BorderEnabled: true
    property string dankLauncherV2BorderColor: "outline"
    property int dankLauncherV2BorderThickness: 1
    property bool modalDarkenBackground: true
    property bool modalElevationEnabled: true
    property bool popupElevationEnabled: true

    property string launchPrefix: ""

    function getCursorEnvironment() {
        return ({});
    }
}
