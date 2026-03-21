pragma Singleton
pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import Quickshell
import "../Common/fzf.js" as Fzf

Item {
    id: root

    property var applications: []
    property var _transformCache: ({})
    property var _searchEntries: []
    property var _finder: null
    property int cacheVersion: 0
    property int maxSearchResults: 24

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
        _searchEntries = [];
        _finder = null;
        cacheVersion++;
    }

    Component.onCompleted: refreshApplications()

    function invalidateLauncherCache() {
        _transformCache = ({});
        _searchEntries = [];
        _finder = null;
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

    function _buildSearchText(app) {
        const parts = [
            app.name || "",
            app.genericName || "",
            app.comment || "",
            app.id || "",
            app.execString || "",
            app.exec || ""
        ];
        const keywords = app.keywords || [];
        for (let i = 0; i < keywords.length; i++)
            parts.push(keywords[i] || "");
        return parts.join(" ").replace(/\s+/g, " ").trim();
    }

    function _ensureFinder() {
        if (_finder)
            return _finder;

        _searchEntries = applications.map(app => ({
            app: app,
            text: _buildSearchText(app)
        }));

        _finder = new Fzf.Finder(_searchEntries, {
            selector: function (entry) {
                return entry.text;
            },
            limit: maxSearchResults,
            tiebreakers: [Fzf.byLengthAsc, Fzf.byStartAsc]
        });

        return _finder;
    }

    function searchApplications(query, maxResults) {
        const visible = applications.slice();
        if (!query)
            return visible.sort((a, b) => (a.name || "").localeCompare(b.name || ""));

        const q = query.trim();
        if (!q)
            return visible.sort((a, b) => (a.name || "").localeCompare(b.name || ""));

        const finder = _ensureFinder();
        const limit = Math.max(1, maxResults || maxSearchResults);
        const matches = finder.find(q).map(result => result.item.app);
        if (matches.length > limit)
            matches.length = limit;
        return matches;
    }
}
