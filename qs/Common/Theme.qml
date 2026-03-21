pragma Singleton
pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import "../Common"

QtObject {
    id: root

    readonly property string defaultFontFamily: "Inter Variable"
    readonly property string defaultMonoFontFamily: "Fira Code"
    property string fontFamily: defaultFontFamily
    property string monoFontFamily: defaultMonoFontFamily
    property int fontWeight: Font.Normal

    property bool isLightMode: false

    property color primary: "#8fd17f"
    property color primaryText: "#0d1b0d"
    property color primaryContainer: "#20311d"
    property color primaryHover: "#2b4126"
    property color primaryHoverLight: "#1b2618"
    property color primaryPressed: "#31492c"
    property color primarySelected: "#3c5d35"
    property color secondary: "#99c6ff"

    property color surface: "#111411"
    property color surfaceLight: "#1a201a"
    property color surfaceHover: "#1d241d"
    property color surfacePressed: "#222a22"
    property color surfaceContainer: "#161b16"
    property color surfaceContainerHigh: "#1d241d"
    property color surfaceText: "#edf4ea"
    property color surfaceVariantText: "#a9b6a7"
    property color surfaceVariantAlpha: "#243024"

    property color outline: "#5c6a5b"
    property color outlineMedium: "#374137"
    property color outlineStrong: "#465246"
    property color outlineButton: "#93a18f"
    property color error: "#ff8b8b"

    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16

    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 18
    readonly property int iconSize: 20
    readonly property int cornerRadius: 12

    readonly property real popupTransparency: 0.96
    readonly property int shortDuration: 140
    readonly property int shorterDuration: 110
    readonly property int modalAnimationDuration: 180
    readonly property int currentAnimationSpeed: SettingsData.animationSpeed
    readonly property bool elevationEnabled: false
    readonly property var elevationLevel2: ({
        "blurPx": 18,
        "spreadPx": 0
    })
    readonly property var elevationLevel3: ({
        "blurPx": 24,
        "spreadPx": 0
    })
    readonly property string elevationLightDirection: "down"
    readonly property real elevationBlurMax: 64

    readonly property int standardEasing: Easing.OutCubic
    readonly property var expressiveDurations: ({
        "expressiveDefaultSpatial": 220
    })
    readonly property var expressiveCurves: ({
        "standard": [0.2, 0, 0, 1, 1, 1],
        "standardDecel": [0, 0, 0, 1, 1, 1],
        "expressiveDefaultSpatial": [0.2, 0, 0, 1, 1, 1],
        "emphasized": [0.2, 0, 0, 1, 1, 1]
    })

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function elevationOffsetXFor(level, direction, fallbackOffset) {
        return 0;
    }

    function elevationOffsetYFor(level, direction, fallbackOffset) {
        return fallbackOffset || 0;
    }

    function elevationShadowColor(level) {
        return Qt.rgba(0, 0, 0, 0.35);
    }
}
