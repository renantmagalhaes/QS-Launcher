pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"
import "../../Services"
import "Scorer.js" as Scorer
import "NavigationHelpers.js" as Nav
import "ItemTransformers.js" as Transform
import "../../Common/Calculator.js" as Calculator

Item {
    id: root

    property string searchQuery: ""
    property string searchMode: "all"
    property var sections: []
    property var flatModel: []
    property int selectedFlatIndex: 0
    property var selectedItem: null
    property bool keyboardNavigationActive: false
    property bool active: false
    property bool isFileSearching: false
    property int gridColumns: SettingsData.appLauncherGridColumns
    property int viewModeVersion: 0
    property var appCategories: []
    property string appCategory: ""
    property bool autoSwitchedToFiles: false

    signal itemExecuted
    signal modeChanged(string mode)
    signal searchCompleted

    readonly property var sectionDefinitions: [
        { id: "calculator", title: I18n.tr("Calculator"), icon: "calculate", priority: 0.1, defaultViewMode: "list" },
        { id: "windows", title: I18n.tr("Windows"), icon: "window", priority: 1, defaultViewMode: "list" },
        { id: "apps", title: I18n.tr("Applications"), icon: "apps", priority: 2, defaultViewMode: "list" }
    ]

    Timer {
        id: searchDebounce
        interval: 50
        onTriggered: root.performSearch()
    }

    function setSearchQuery(query) {
        searchQuery = query || "";
        searchDebounce.restart();
    }

    function setMode(mode) {
        if (searchMode === mode)
            return;
        searchMode = mode;
        modeChanged(mode);
        performSearch();
    }

    function restorePreviousMode() {
    }

    function setAppCategory(category) {
        appCategory = category || "";
        performSearch();
    }

    function cycleMode(reverse) {
        const modes = ["all", "windows", "apps"];
        const currentIndex = modes.indexOf(searchMode);
        const nextIndex = reverse ? (currentIndex - 1 + modes.length) % modes.length : (currentIndex + 1) % modes.length;
        setMode(modes[nextIndex]);
    }

    function getSectionViewMode(sectionId) {
        return "list";
    }

    function getCurrentSectionViewMode() {
        return "list";
    }

    function getGridColumns(sectionId) {
        return gridColumns;
    }

    function canChangeSectionViewMode(sectionId) {
        return false;
    }

    function canCollapseSection(sectionId) {
        return searchMode === "all";
    }

    function toggleSection(sectionId) {
        for (let i = 0; i < sections.length; i++) {
            if (sections[i].id === sectionId)
                sections[i].collapsed = !sections[i].collapsed;
        }
        flatModel = Scorer.flattenSections(sections);
        updateSelectedItem();
    }

    function getOrTransformApp(app) {
        return AppSearchService.getOrTransformApp(app, transformApp);
    }

    function transformApp(app) {
        return Transform.transformApp(app, null, [], I18n.tr("Launch"));
    }

    function performSearch() {
        const allItems = [];
        const query = searchQuery.trim();
        const desktopEntries = typeof DesktopEntries !== "undefined" ? DesktopEntries : null;

        const calcResult = Calculator.evaluate(query);
        if (calcResult)
            allItems.push(Transform.transformCalcResult(calcResult, query, I18n.tr("Copy")));

        if (searchMode === "all" || searchMode === "windows") {
            WindowSearchService.refreshWindows();
            const windows = WindowSearchService.windows || [];
            for (let i = 0; i < windows.length; i++)
                allItems.push(Transform.transformWindow(windows[i], I18n.tr("Focus"), desktopEntries));
        }

        if (searchMode === "apps" || query.length > 0) {
            const apps = AppSearchService.searchApplications(query);
            for (let i = 0; i < apps.length; i++)
                allItems.push(getOrTransformApp(apps[i]));
        }

        const scoredItems = Scorer.scoreItems(allItems, query, null);
        const grouped = Scorer.groupBySection(scoredItems, sectionDefinitions, SettingsData.sortAppsAlphabetically, query ? 50 : 500);

        for (let i = 0; i < grouped.length; i++) {
            if (grouped[i].collapsed === undefined)
                grouped[i].collapsed = false;
        }

        _applyHighlights(grouped, query);
        sections = grouped;
        flatModel = Scorer.flattenSections(grouped);
        selectedFlatIndex = getFirstItemIndex();
        updateSelectedItem();
        searchCompleted();
    }

    function _applyHighlights(sectionsData, query) {
        if (!query) {
            for (let i = 0; i < sectionsData.length; i++) {
                const items = sectionsData[i].items || [];
                for (let j = 0; j < items.length; j++) {
                    items[j]._hName = items[j].name || "";
                    items[j]._hSub = items[j].subtitle || "";
                    items[j]._hRich = false;
                }
            }
            return;
        }

        const highlightColor = Theme.primary;
        const nameColor = Theme.surfaceText;
        const subColor = Theme.surfaceVariantText;
        const lowerQuery = query.toLowerCase();

        for (let i = 0; i < sectionsData.length; i++) {
            const items = sectionsData[i].items || [];
            for (let j = 0; j < items.length; j++) {
                const item = items[j];
                item._hName = _highlightField(item.name || "", lowerQuery, query.length, nameColor, highlightColor);
                item._hSub = _highlightField(item.subtitle || "", lowerQuery, query.length, subColor, highlightColor);
                item._hRich = true;
            }
        }
    }

    function _highlightField(text, lowerQuery, queryLen, baseColor, highlightColor) {
        if (!text)
            return "";
        const idx = text.toLowerCase().indexOf(lowerQuery);
        if (idx === -1)
            return text;
        const before = _escapeStyledText(text.substring(0, idx));
        const match = _escapeStyledText(text.substring(idx, idx + queryLen));
        const after = _escapeStyledText(text.substring(idx + queryLen));
        return '<font color="' + baseColor + '">' + before + '</font><b><font color="' + highlightColor + '">' + match + '</font></b><font color="' + baseColor + '">' + after + '</font>';
    }

    function _escapeStyledText(text) {
        return String(text)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;");
    }

    function getFirstItemIndex() {
        return Nav.getFirstItemIndex(flatModel);
    }

    function updateSelectedItem() {
        if (selectedFlatIndex >= 0 && selectedFlatIndex < flatModel.length) {
            const entry = flatModel[selectedFlatIndex];
            selectedItem = entry.isHeader ? null : entry.item;
        } else {
            selectedItem = null;
        }
    }

    function selectNext() {
        keyboardNavigationActive = true;
        const nextIndex = Nav.calculateNextIndex(flatModel, selectedFlatIndex, null, null, gridColumns, getSectionViewMode);
        if (nextIndex !== selectedFlatIndex) {
            selectedFlatIndex = nextIndex;
            updateSelectedItem();
        }
    }

    function selectPrevious() {
        keyboardNavigationActive = true;
        const nextIndex = Nav.calculatePrevIndex(flatModel, selectedFlatIndex, null, null, gridColumns, getSectionViewMode);
        if (nextIndex !== selectedFlatIndex) {
            selectedFlatIndex = nextIndex;
            updateSelectedItem();
        }
    }

    function selectRight() {
        selectNext();
    }

    function selectLeft() {
        selectPrevious();
    }

    function selectNextSection() {
        keyboardNavigationActive = true;
        const nextIndex = Nav.calculateNextSectionIndex(flatModel, selectedFlatIndex);
        if (nextIndex !== selectedFlatIndex) {
            selectedFlatIndex = nextIndex;
            updateSelectedItem();
        }
    }

    function selectPreviousSection() {
        keyboardNavigationActive = true;
        const nextIndex = Nav.calculatePrevSectionIndex(flatModel, selectedFlatIndex);
        if (nextIndex !== selectedFlatIndex) {
            selectedFlatIndex = nextIndex;
            updateSelectedItem();
        }
    }

    function selectPageDown(visibleItems) {
        keyboardNavigationActive = true;
        const nextIndex = Nav.calculatePageDownIndex(flatModel, selectedFlatIndex, visibleItems);
        if (nextIndex !== selectedFlatIndex) {
            selectedFlatIndex = nextIndex;
            updateSelectedItem();
        }
    }

    function selectPageUp(visibleItems) {
        keyboardNavigationActive = true;
        const nextIndex = Nav.calculatePageUpIndex(flatModel, selectedFlatIndex, visibleItems);
        if (nextIndex !== selectedFlatIndex) {
            selectedFlatIndex = nextIndex;
            updateSelectedItem();
        }
    }

    function executeSelected() {
        if (!selectedItem)
            return;
        executeItem(selectedItem);
    }

    function executeItem(item) {
        if (!item)
            return;

        switch (item.type) {
        case "app":
            launchApp(item.data);
            break;
        case "window":
            WindowSearchService.activateWindow(item.data?.windowId);
            break;
        case "calc":
            copyToClipboard(item.data?.result || item.name || "");
            break;
        }

        itemExecuted();
    }

    function executeAction(item, action) {
        if (!item || !action)
            return;
        if (action.action === "launch")
            executeItem(item);
    }

    function _resolveDesktopEntry(app) {
        if (!app)
            return null;
        if (app.command)
            return app;
        const id = app.id || app.execString || app.exec || "";
        if (!id)
            return null;
        if (typeof DesktopEntries === "undefined")
            return null;
        return DesktopEntries.heuristicLookup(id);
    }

    function launchApp(app) {
        const entry = _resolveDesktopEntry(app);
        if (!entry)
            return;
        SessionService.launchDesktopEntry(entry);
    }

    function copyToClipboard(text) {
        if (!text)
            return;
        const value = String(text);

        if (Quickshell.env("WAYLAND_DISPLAY") !== "") {
            Quickshell.execDetached(["wl-copy", value]);
            return;
        }

        if (Quickshell.env("DISPLAY") !== "") {
            Quickshell.execDetached([
                "sh",
                "-c",
                "if command -v xclip >/dev/null 2>&1; then printf '%s' \"$1\" | xclip -selection clipboard -in; elif command -v xsel >/dev/null 2>&1; then printf '%s' \"$1\" | xsel --clipboard --input; else exit 1; fi",
                "spotlight-clipboard",
                value
            ]);
            return;
        }

        Quickshell.execDetached([
            "sh",
            "-c",
            "if command -v wl-copy >/dev/null 2>&1; then wl-copy \"$1\"; elif command -v xclip >/dev/null 2>&1; then printf '%s' \"$1\" | xclip -selection clipboard -in; elif command -v xsel >/dev/null 2>&1; then printf '%s' \"$1\" | xsel --clipboard --input; else exit 1; fi",
            "spotlight-clipboard",
            value
        ]);
    }
}
