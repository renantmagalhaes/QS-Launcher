pragma Singleton
pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import Quickshell

Item {
    id: root

    property var applications: []
    property var _transformCache: ({})
    property int cacheVersion: 0

    function refreshApplications() {
        if (typeof DesktopEntries !== "undefined") {
            applications = DesktopEntries.applications.values || [];
        } else {
            applications = [
                { id: "firefox", name: "Firefox", icon: "firefox", comment: "Web Browser", exec: "firefox" },
                { id: "terminal", name: "Terminal", icon: "utilities-terminal", comment: "Shell", exec: "xterm" },
                { id: "files", name: "Files", icon: "folder", comment: "File Manager", exec: "nautilus" }
            ];
        }
        _transformCache = ({});
        cacheVersion++;
    }

    Component.onCompleted: refreshApplications()

    function invalidateLauncherCache() {
        _transformCache = ({});
        cacheVersion++;
    }

    function getCategoryIcon(category) {
        return "apps";
    }

    function getOrTransformApp(app, transformFn) {
        const id = app.id || app.execString || app.exec || "";
        if (!id)
            return transformFn(app);
        if (_transformCache[id])
            return _transformCache[id];
        const transformed = transformFn(app);
        _transformCache[id] = transformed;
        return transformed;
    }

    function _tokens(text) {
        return (text || "").toLowerCase().trim().split(/[\s._-]+/).filter(token => token.length > 0);
    }

    function searchApplications(query) {
        const visible = applications.slice();
        if (!query)
            return visible.sort((a, b) => (a.name || "").localeCompare(b.name || ""));

        const q = query.toLowerCase().trim();
        return visible.filter(app => {
            const haystacks = [
                app.name || "",
                app.comment || "",
                app.genericName || "",
                app.id || ""
            ];
            for (let i = 0; i < haystacks.length; i++) {
                const value = haystacks[i].toLowerCase();
                if (value.includes(q))
                    return true;
            }
            const tokens = _tokens((app.name || "") + " " + (app.comment || "") + " " + (app.id || ""));
            return tokens.some(token => token.startsWith(q));
        }).sort((a, b) => (a.name || "").localeCompare(b.name || ""));
    }
}
