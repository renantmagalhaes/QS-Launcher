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
        "dracula": {
            isLightMode: false,
            primary: "#bd93f9",
            primaryText: "#0d0813",
            primaryContainer: "#3f3354",
            primaryHover: "#51406d",
            primaryHoverLight: "#342a46",
            primaryPressed: "#624e84",
            primarySelected: "#725c99",
            secondary: "#8be9fd",
            surface: "#282a36",
            surfaceLight: "#323544",
            surfaceHover: "#3a3d4d",
            surfacePressed: "#44475a",
            surfaceContainer: "#232530",
            surfaceContainerHigh: "#2c2f3c",
            surfaceText: "#f8f8f2",
            surfaceVariantText: "#bcc2cd",
            surfaceVariantAlpha: "#3b3e4d",
            outline: "#6d7086",
            outlineMedium: "#4d5062",
            outlineStrong: "#8b90a7",
            outlineButton: "#c5c9d4",
            error: "#ff5555"
        },
        "nord": {
            isLightMode: false,
            primary: "#88c0d0",
            primaryText: "#0f151b",
            primaryContainer: "#30414d",
            primaryHover: "#3c5160",
            primaryHoverLight: "#293944",
            primaryPressed: "#4a6476",
            primarySelected: "#577588",
            secondary: "#81a1c1",
            surface: "#2e3440",
            surfaceLight: "#3b4252",
            surfaceHover: "#434c5e",
            surfacePressed: "#4c566a",
            surfaceContainer: "#2b313c",
            surfaceContainerHigh: "#353c49",
            surfaceText: "#eceff4",
            surfaceVariantText: "#d8dee9",
            surfaceVariantAlpha: "#434c5e",
            outline: "#6d7a90",
            outlineMedium: "#4b5568",
            outlineStrong: "#8a98b0",
            outlineButton: "#c7d0de",
            error: "#bf616a"
        },
        "tokyo-night": {
            isLightMode: false,
            primary: "#7aa2f7",
            primaryText: "#0b1020",
            primaryContainer: "#24304d",
            primaryHover: "#2f3d63",
            primaryHoverLight: "#202b45",
            primaryPressed: "#405384",
            primarySelected: "#4b619a",
            secondary: "#bb9af7",
            surface: "#1a1b26",
            surfaceLight: "#24283b",
            surfaceHover: "#2b3048",
            surfacePressed: "#323857",
            surfaceContainer: "#16161e",
            surfaceContainerHigh: "#1f2335",
            surfaceText: "#c0caf5",
            surfaceVariantText: "#a9b1d6",
            surfaceVariantAlpha: "#2a2f45",
            outline: "#565f89",
            outlineMedium: "#3b4261",
            outlineStrong: "#7d88b4",
            outlineButton: "#b7c0ea",
            error: "#f7768e"
        },
        "gruvbox": {
            isLightMode: false,
            primary: "#d79921",
            primaryText: "#1d1607",
            primaryContainer: "#4f3e18",
            primaryHover: "#674f1d",
            primaryHoverLight: "#443514",
            primaryPressed: "#7d6224",
            primarySelected: "#93742b",
            secondary: "#83a598",
            surface: "#282828",
            surfaceLight: "#32302f",
            surfaceHover: "#3c3836",
            surfacePressed: "#504945",
            surfaceContainer: "#242424",
            surfaceContainerHigh: "#2d2b2a",
            surfaceText: "#ebdbb2",
            surfaceVariantText: "#d5c4a1",
            surfaceVariantAlpha: "#3f3a35",
            outline: "#7c6f64",
            outlineMedium: "#5a524b",
            outlineStrong: "#a89984",
            outlineButton: "#d5c4a1",
            error: "#fb4934"
        },
        "rose-pine": {
            isLightMode: false,
            primary: "#c4a7e7",
            primaryText: "#191724",
            primaryContainer: "#403551",
            primaryHover: "#513f65",
            primaryHoverLight: "#372d46",
            primaryPressed: "#624d79",
            primarySelected: "#71598b",
            secondary: "#9ccfd8",
            surface: "#191724",
            surfaceLight: "#1f1d2e",
            surfaceHover: "#26233a",
            surfacePressed: "#2f2b45",
            surfaceContainer: "#161320",
            surfaceContainerHigh: "#211f30",
            surfaceText: "#e0def4",
            surfaceVariantText: "#908caa",
            surfaceVariantAlpha: "#2a273f",
            outline: "#6e6a86",
            outlineMedium: "#403d52",
            outlineStrong: "#b0acd0",
            outlineButton: "#cfcbe6",
            error: "#eb6f92"
        },
        "dark": {
            isLightMode: false,
            primary: "#f2f2f2",
            primaryText: "#0f0f0f",
            primaryContainer: "#d8d8d8",
            primaryHover: "#e4e4e4",
            primaryHoverLight: "#cfcfcf",
            primaryPressed: "#000000", // selection
            primarySelected: "#000000",
            secondary: "#bdbdbd",
            surface: "#121212",
            surfaceLight: "#1b1b1b",
            surfaceHover: "#222222",
            surfacePressed: "#292929",
            surfaceContainer: "#181818",
            surfaceContainerHigh: "#202020",
            surfaceText: "#ffffff",
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
