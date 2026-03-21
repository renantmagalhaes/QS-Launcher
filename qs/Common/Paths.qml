pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtCore
import QtQml

QtObject {
    id: root

    readonly property url home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]

    function stringify(path: url): string {
        return path.toString().replace(/%20/g, " ");
    }

    function strip(path: url): string {
        return stringify(path).replace("file://", "");
    }

    function toFileUrl(path: string): string {
        return path.startsWith("file://") ? path : "file://" + path;
    }

    function expandTilde(path: string): string {
        return strip(path.replace("~", stringify(root.home)));
    }

    function resolveIconPath(iconName: string): string {
        if (!iconName)
            return "";
        if (iconName.startsWith("~") || iconName.startsWith("/"))
            return toFileUrl(expandTilde(iconName));
        if (iconName.startsWith("file://"))
            return iconName;
        return Quickshell.iconPath(iconName, true) || "";
    }

    function resolveIconUrl(iconName: string): string {
        if (!iconName)
            return "";
        if (iconName.startsWith("~") || iconName.startsWith("/") || iconName.startsWith("file://"))
            return resolveIconPath(iconName);
        return "image://icon/" + iconName;
    }
}
