pragma Singleton
pragma ComponentBehavior: Bound

import QtQml

QtObject {
    readonly property bool isRtl: false

    function tr(text, context) {
        return text || "";
    }
}
