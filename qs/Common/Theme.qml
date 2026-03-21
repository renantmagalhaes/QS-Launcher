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

    readonly property string currentThemeName: (typeof SettingsData !== "undefined" && SettingsData.themeName) ? SettingsData.themeName : "default"
    readonly property var palettes: ({
        "default": {
            isLightMode: false,
            primary: "#8fd17f",
            primaryText: "#0d1b0d",
            primaryContainer: "#20311d",
            primaryHover: "#2b4126",
            primaryHoverLight: "#1b2618",
            primaryPressed: "#31492c",
            primarySelected: "#3c5d35",
            secondary: "#99c6ff",
            surface: "#111411",
            surfaceLight: "#1a201a",
            surfaceHover: "#1d241d",
            surfacePressed: "#222a22",
            surfaceContainer: "#161b16",
            surfaceContainerHigh: "#1d241d",
            surfaceText: "#edf4ea",
            surfaceVariantText: "#a9b6a7",
            surfaceVariantAlpha: "#243024",
            outline: "#5c6a5b",
            outlineMedium: "#374137",
            outlineStrong: "#465246",
            outlineButton: "#93a18f",
            error: "#ff8b8b"
        },
        "midnight": {
            isLightMode: false,
            primary: "#79a8ff",
            primaryText: "#08111f",
            primaryContainer: "#13233d",
            primaryHover: "#1a3155",
            primaryHoverLight: "#122440",
            primaryPressed: "#223d66",
            primarySelected: "#294873",
            secondary: "#9ed0ff",
            surface: "#090d16",
            surfaceLight: "#101827",
            surfaceHover: "#131d2f",
            surfacePressed: "#182338",
            surfaceContainer: "#0c1220",
            surfaceContainerHigh: "#11192b",
            surfaceText: "#e8eefc",
            surfaceVariantText: "#9ba9c4",
            surfaceVariantAlpha: "#1c2940",
            outline: "#4d5d79",
            outlineMedium: "#2f3c53",
            outlineStrong: "#5e708d",
            outlineButton: "#8b9ab8",
            error: "#ff8f96"
        },
        "dark": {
            isLightMode: false,
            primary: "#7cc7ff",
            primaryText: "#06131b",
            primaryContainer: "#163041",
            primaryHover: "#1c4156",
            primaryHoverLight: "#152f3f",
            primaryPressed: "#24536d",
            primarySelected: "#2c6280",
            secondary: "#93d7c5",
            surface: "#121212",
            surfaceLight: "#1b1b1b",
            surfaceHover: "#222222",
            surfacePressed: "#292929",
            surfaceContainer: "#181818",
            surfaceContainerHigh: "#202020",
            surfaceText: "#f2f2f2",
            surfaceVariantText: "#b0b0b0",
            surfaceVariantAlpha: "#2a2a2a",
            outline: "#626262",
            outlineMedium: "#3c3c3c",
            outlineStrong: "#767676",
            outlineButton: "#a1a1a1",
            error: "#ff8f8f"
        },
        "catppuccin": {
            isLightMode: false,
            primary: "#cba6f7",
            primaryText: "#1e1e2e",
            primaryContainer: "#45325f",
            primaryHover: "#5a417a",
            primaryHoverLight: "#3b2c50",
            primaryPressed: "#6c4f90",
            primarySelected: "#7b5ca0",
            secondary: "#89dceb",
            surface: "#1e1e2e",
            surfaceLight: "#313244",
            surfaceHover: "#3a3b4f",
            surfacePressed: "#45475a",
            surfaceContainer: "#181825",
            surfaceContainerHigh: "#24273a",
            surfaceText: "#cdd6f4",
            surfaceVariantText: "#a6adc8",
            surfaceVariantAlpha: "#313244",
            outline: "#6c7086",
            outlineMedium: "#45475a",
            outlineStrong: "#7f849c",
            outlineButton: "#bac2de",
            error: "#f38ba8"
        },
        "dark-purple": {
            isLightMode: false,
            primary: "#b48ef7",
            primaryText: "#130a1f",
            primaryContainer: "#30194a",
            primaryHover: "#3e2161",
            primaryHoverLight: "#291640",
            primaryPressed: "#512b7d",
            primarySelected: "#603394",
            secondary: "#d7b8ff",
            surface: "#140f1d",
            surfaceLight: "#1c1528",
            surfaceHover: "#241a33",
            surfacePressed: "#2b1f3d",
            surfaceContainer: "#181222",
            surfaceContainerHigh: "#21192f",
            surfaceText: "#f1e9ff",
            surfaceVariantText: "#bba9d6",
            surfaceVariantAlpha: "#2d2240",
            outline: "#695b80",
            outlineMedium: "#3e3350",
            outlineStrong: "#7c6c96",
            outlineButton: "#bcaed1",
            error: "#ff93b3"
        }
    })
    readonly property var palette: palettes[currentThemeName] || palettes.default

    property bool isLightMode: palette.isLightMode

    property color primary: palette.primary
    property color primaryText: palette.primaryText
    property color primaryContainer: palette.primaryContainer
    property color primaryHover: palette.primaryHover
    property color primaryHoverLight: palette.primaryHoverLight
    property color primaryPressed: palette.primaryPressed
    property color primarySelected: palette.primarySelected
    property color secondary: palette.secondary

    property color surface: palette.surface
    property color surfaceLight: palette.surfaceLight
    property color surfaceHover: palette.surfaceHover
    property color surfacePressed: palette.surfacePressed
    property color surfaceContainer: palette.surfaceContainer
    property color surfaceContainerHigh: palette.surfaceContainerHigh
    property color surfaceText: palette.surfaceText
    property color surfaceVariantText: palette.surfaceVariantText
    property color surfaceVariantAlpha: palette.surfaceVariantAlpha

    property color outline: palette.outline
    property color outlineMedium: palette.outlineMedium
    property color outlineStrong: palette.outlineStrong
    property color outlineButton: palette.outlineButton
    property color error: palette.error

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
