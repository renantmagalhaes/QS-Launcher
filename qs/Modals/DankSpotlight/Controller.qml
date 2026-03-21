pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Common"
import "../../Services"
import "Scorer.js" as Scorer
import "ControllerUtils.js" as Utils
import "NavigationHelpers.js" as Nav
import "ItemTransformers.js" as Transform
import "../../Common/Calculator.js" as Calculator

Item {
    id: root

    property string searchQuery: ""
    property string searchMode: "all"
    property string previousSearchMode: "all"
    property bool autoSwitchedToFiles: false
    property bool isFileSearching: false
    property var sections: []
    property var flatModel: []
    property int selectedFlatIndex: 0
    property var selectedItem: null
    property bool isSearching: false
    property var collapsedSections: ({})
    property bool keyboardNavigationActive: false
    property bool active: false
    property var _modeSectionsCache: ({})
    property bool _queryDrivenSearch: false
    property bool _diskCacheConsumed: false
    property var sectionViewModes: ({})
    property int gridColumns: SettingsData.appLauncherGridColumns
    property int viewModeVersion: 0
    property string viewModeContext: "spotlight"

    signal itemExecuted
    signal searchCompleted
    signal modeChanged(string mode)
    signal viewModeChanged(string sectionId, string mode)
    signal searchQueryRequested(string query)

    onActiveChanged: {
        if (!active) {
            sections = [];
            flatModel = [];
            selectedItem = null;
            _clearModeCache();
        }
    }

    onSearchModeChanged: {
        if (searchMode === "apps") {
            _loadAppCategories();
        } else {
            appCategory = "";
            appCategories = [];
        }
    }

    Connections {
        target: SettingsData
        function onSortAppsAlphabeticallyChanged() {
            AppSearchService.invalidateLauncherCache();
            _clearModeCache();
        }
    }

    Connections {
        target: AppSearchService
        function onCacheVersionChanged() {
            if (!active)
                return;
            _clearModeCache();
            if (searchMode === "apps") {
                _loadAppCategories();
                performSearch();
            } else if (!searchQuery && searchMode === "all") {
                performSearch();
            }
        }
    }


    Process {
        id: wtypeProcess
        command: ["wtype", "-M", "ctrl", "-P", "v", "-p", "v", "-m", "ctrl"]
        running: false
    }

    Process {
        id: copyProcess
        running: false
        onExited: pasteTimer.start()
    }

    Timer {
        id: pasteTimer
        interval: 200
        repeat: false
        onTriggered: wtypeProcess.running = true
    }


    readonly property var sectionDefinitions: [
        {
            id: "calculator",
            title: I18n.tr("Calculator"),
            icon: "calculate",
            priority: 0.1,
            defaultViewMode: "list"
        },
        {
            id: "favorites",
            title: I18n.tr("Pinned"),
            icon: "push_pin",
            priority: 1,
            defaultViewMode: "list"
        },
        {
            id: "windows",
            title: I18n.tr("Windows"),
            icon: "window",
            priority: 1.5,
            defaultViewMode: "list"
        },
        {
            id: "apps",
            title: I18n.tr("Applications"),
            icon: "apps",
            priority: 2,
            defaultViewMode: "list"
        },
        {
            id: "files",
            title: I18n.tr("Files"),
            icon: "folder",
            priority: 4,
            defaultViewMode: "list"
        },
        {
            id: "fallback",
            title: I18n.tr("Commands"),
            icon: "terminal",
            priority: 5,
            defaultViewMode: "list"
        }
    ]

    property string fileSearchType: "all"
    property string fileSearchExt: ""
    property string fileSearchFolder: ""
    property string fileSearchSort: "score"

    property var appTriggers: ({})
    property var fileTriggers: ({})
    property var windowTriggers: ({})
    property string appCategory: ""
    property var appCategories: []

    function getSectionViewMode(sectionId) {
        if (sectionViewModes[sectionId])
            return sectionViewModes[sectionId];

        var savedModes = viewModeContext === "appDrawer" ? (SettingsData.appDrawerSectionViewModes || {}) : (SettingsData.spotlightSectionViewModes || {});
        if (savedModes[sectionId])
            return savedModes[sectionId];

        for (var i = 0; i < sectionDefinitions.length; i++) {
            if (sectionDefinitions[i].id === sectionId)
                return sectionDefinitions[i].defaultViewMode || "list";
        }

        return "list";
    }

    function setSectionViewMode(sectionId, mode) {
        sectionViewModes = Object.assign({}, sectionViewModes, {
            [sectionId]: mode
        });
        viewModeVersion++;
        if (viewModeContext === "appDrawer") {
            var savedModes = Object.assign({}, SettingsData.appDrawerSectionViewModes || {}, {
                [sectionId]: mode
            });
            SettingsData.appDrawerSectionViewModes = savedModes;
        } else {
            var savedModes = Object.assign({}, SettingsData.spotlightSectionViewModes || {}, {
                [sectionId]: mode
            });
            SettingsData.spotlightSectionViewModes = savedModes;
        }
        viewModeChanged(sectionId, mode);
    }

    function canChangeSectionViewMode(sectionId) {
        return sectionId === "apps" || sectionId === "files" || sectionId === "windows";
    }

    function canCollapseSection(sectionId) {
        return searchMode === "all";
    }

    property int _searchVersion: 0

    Timer {
        id: searchDebounce
        interval: 60
        onTriggered: root.performSearch()
    }

    Timer {
        id: fileSearchDebounce
        interval: 200
        onTriggered: root.performFileSearch()
    }

    function getOrTransformApp(app) {
        return AppSearchService.getOrTransformApp(app, transformApp);
    }

    function setSearchQuery(query) {
        _searchVersion++;
        _queryDrivenSearch = true;
        searchQuery = query;
        searchDebounce.restart();

        if ((searchMode === "files" || query.startsWith("/")) && query.length > 0) {
            fileSearchDebounce.restart();
        }
    }

    function setMode(mode, isAutoSwitch) {
        if (searchMode === mode)
            return;
        if (isAutoSwitch) {
            previousSearchMode = searchMode;
            autoSwitchedToFiles = true;
        } else {
            autoSwitchedToFiles = false;
        }
        searchMode = mode;
        modeChanged(mode);
        performSearch();
        switch (mode) {
        case "files":
            fileSearchDebounce.restart();
            break;
        case "apps":
            _loadAppCategories();
            break;
        case "windows":
            WindowSearchService.refreshWindows();
            break;
        }
    }

    function restorePreviousMode() {
        if (!autoSwitchedToFiles)
            return;
        autoSwitchedToFiles = false;
        searchMode = previousSearchMode;
        modeChanged(previousSearchMode);
        performSearch();
    }

    function cycleMode(reverse = false) {
        var modes = ["all", "windows", "apps", "files"];
        var currentIndex = modes.indexOf(searchMode);
        if (!reverse)
            var nextIndex = (currentIndex + 1) % modes.length;
        else
            var nextIndex = (currentIndex - 1 + modes.length) % modes.length;
        setMode(modes[nextIndex]);
    }

    function reset() {
        searchQuery = "";
        searchMode = "all";
        previousSearchMode = "all";
        autoSwitchedToFiles = false;
        isFileSearching = false;
        fileSearchType = "all";
        fileSearchExt = "";
        fileSearchFolder = "";
        fileSearchSort = "score";
        sections = [];
        flatModel = [];
        selectedFlatIndex = 0;
        selectedItem = null;
        isSearching = false;
        appCategory = "";
        appCategories = [];
        collapsedSections = {};
        _queryDrivenSearch = false;
    }


    function setAppCategory(category) {
        if (appCategory === category)
            return;
        appCategory = category;
        _queryDrivenSearch = true;
        performSearch();
    }

    function _loadAppCategories() {
        appCategories = AppSearchService.getAllCategories();
    }

    function setFileSearchType(type) {
        if (fileSearchType === type)
            return;
        fileSearchType = type;
        performFileSearch();
    }

    function setFileSearchExt(ext) {
        if (fileSearchExt === ext)
            return;
        fileSearchExt = ext;
        performFileSearch();
    }

    function setFileSearchFolder(folder) {
        if (fileSearchFolder === folder)
            return;
        fileSearchFolder = folder;
        performFileSearch();
    }

    function setFileSearchSort(sort) {
        if (fileSearchSort === sort)
            return;
        fileSearchSort = sort;
        performFileSearch();
    }


    function preserveSelectionAfterUpdate(forceFirst) {
        if (forceFirst)
            return function () {
                return getFirstItemIndex();
            };
        var previousSelectedId = selectedItem?.id || "";
        return function (newFlatModel) {
            if (!previousSelectedId)
                return getFirstItemIndex();
            for (var i = 0; i < newFlatModel.length; i++) {
                if (!newFlatModel[i].isHeader && newFlatModel[i].item?.id === previousSelectedId)
                    return i;
            }
            return getFirstItemIndex();
        };
    }

    function performSearch() {
        var currentVersion = _searchVersion;
        isSearching = true;
        var shouldResetSelection = _queryDrivenSearch;
        _queryDrivenSearch = false;
        var restoreSelection = preserveSelectionAfterUpdate(shouldResetSelection);

        var cachedSections = AppSearchService.getCachedDefaultSections();
        if (!cachedSections && !_diskCacheConsumed && !searchQuery && searchMode === "all") {
            _diskCacheConsumed = true;
            var diskSections = _loadDiskCache();
            if (diskSections) {
                for (var i = 0; i < diskSections.length; i++) {
                    if (collapsedSections[diskSections[i].id] !== undefined)
                        diskSections[i].collapsed = collapsedSections[diskSections[i].id];
                }
                _applyHighlights(diskSections, "");
                flatModel = Scorer.flattenSections(diskSections);
                sections = diskSections;
                selectedFlatIndex = restoreSelection(flatModel);
                updateSelectedItem();
                isSearching = false;
                searchCompleted();
                return;
            }
        }

        if (cachedSections && !searchQuery && searchMode === "all") {
            var modeCache = _getCachedModeData("all");
            if (modeCache) {
                _applyHighlights(modeCache.sections, "");
                sections = modeCache.sections;
                flatModel = modeCache.flatModel;
            } else {
                var newSections = cachedSections.map(function (s) {
                    var copy = Object.assign({}, s, {
                        items: s.items ? s.items.slice() : []
                    });
                    if (collapsedSections[s.id] !== undefined)
                        copy.collapsed = collapsedSections[s.id];
                    return copy;
                });
                _applyHighlights(newSections, "");
                flatModel = Scorer.flattenSections(newSections);
                sections = newSections;
                _setCachedModeData("all", sections, flatModel);
            }
            selectedFlatIndex = restoreSelection(flatModel);
            updateSelectedItem();
            isSearching = false;
            searchCompleted();
            return;
        }

        var allItems = [];

        var calcResult = Calculator.evaluate(searchQuery);
        if (calcResult) {
            allItems.push(Transform.transformCalcResult(calcResult, searchQuery, I18n.tr("Copy")));
        }

        if (searchMode === "files") {
            var fileQuery = searchQuery.startsWith("/") ? searchQuery.substring(1).trim() : searchQuery.trim();
            isFileSearching = fileQuery.length >= 2 && DSearchService.dsearchAvailable;
            sections = [];
            flatModel = [];
            selectedFlatIndex = 0;
            selectedItem = null;
            isSearching = false;
            searchCompleted();
            return;
        }

        if (searchMode === "apps") {
            var isCategoryFiltered = appCategory && appCategory !== I18n.tr("All");
            var cachedSections = AppSearchService.getCachedDefaultSections();
            if (cachedSections && !searchQuery && !isCategoryFiltered) {
                var modeCache = _getCachedModeData("apps");
                if (modeCache) {
                    _applyHighlights(modeCache.sections, "");
                    sections = modeCache.sections;
                    flatModel = modeCache.flatModel;
                } else {
                    var appSectionIds = ["favorites", "apps"];
                    var newSections = cachedSections.filter(function (s) {
                        return appSectionIds.indexOf(s.id) !== -1;
                    }).map(function (s) {
                        var copy = Object.assign({}, s, {
                            items: s.items ? s.items.slice() : []
                        });
                        if (collapsedSections[s.id] !== undefined)
                            copy.collapsed = collapsedSections[s.id];
                        return copy;
                    });
                    _applyHighlights(newSections, "");
                    flatModel = Scorer.flattenSections(newSections);
                    sections = newSections;
                    _setCachedModeData("apps", sections, flatModel);
                }
                selectedFlatIndex = restoreSelection(flatModel);
                updateSelectedItem();
                isSearching = false;
                searchCompleted();
                return;
            }

            if (isCategoryFiltered) {
                var rawApps = AppSearchService.getAppsInCategory(appCategory);
                for (var i = 0; i < rawApps.length; i++) {
                    allItems.push(getOrTransformApp(rawApps[i]));
                }
                // Also include core apps (DMS Settings etc.) that match this category
                var allCoreApps = AppSearchService.getCoreApps("");
                for (var i = 0; i < allCoreApps.length; i++) {
                    var coreAppCats = AppSearchService.getCategoriesForApp(allCoreApps[i]);
                    if (coreAppCats.indexOf(appCategory) !== -1)
                        allItems.push(transformCoreApp(allCoreApps[i]));
                }
            } else {
                var apps = searchApps(searchQuery);
                for (var i = 0; i < apps.length; i++) {
                    allItems.push(apps[i]);
                }
            }

            var scoredItems = Scorer.scoreItems(allItems, searchQuery, getFrecencyForItem);
            var sortAlpha = !searchQuery && SettingsData.sortAppsAlphabetically;
            var newSections = Scorer.groupBySection(scoredItems, sectionDefinitions, sortAlpha, searchQuery ? 50 : 500);

            for (var sid in collapsedSections) {
                for (var i = 0; i < newSections.length; i++) {
                    if (newSections[i].id === sid) {
                        newSections[i].collapsed = collapsedSections[sid];
                    }
                }
            }

            _applyHighlights(newSections, searchQuery);
            flatModel = Scorer.flattenSections(newSections);
            sections = newSections;
            selectedFlatIndex = restoreSelection(flatModel);
            updateSelectedItem();

            isSearching = false;
            searchCompleted();
            return;
        }

        var apps = searchApps(searchQuery);
        for (var i = 0; i < apps.length; i++) {
            allItems.push(apps[i]);
        }

        if (searchMode === "all" || searchMode === "windows") {
            WindowSearchService.refreshWindows();
            var windows = WindowSearchService.windows;
            for (var i = 0; i < windows.length; i++) {
                allItems.push(Transform.transformWindow(windows[i], I18n.tr("Focus"), DesktopEntries));
            }
        }

        if (currentVersion !== _searchVersion) {
            isSearching = false;
            return;
        }

        var scoredItems = Scorer.scoreItems(allItems, searchQuery, getFrecencyForItem);
        var sortAlpha = !searchQuery && SettingsData.sortAppsAlphabetically;
        var newSections = Scorer.groupBySection(scoredItems, sectionDefinitions, sortAlpha, searchQuery ? 50 : 500);

        if (currentVersion !== _searchVersion) {
            isSearching = false;
            return;
        }

        for (var i = 0; i < newSections.length; i++) {
            var sid = newSections[i].id;
            if (collapsedSections[sid] !== undefined) {
                newSections[i].collapsed = collapsedSections[sid];
            }
        }

        _applyHighlights(newSections, searchQuery);
        flatModel = Scorer.flattenSections(newSections);
        sections = newSections;

        if (!AppSearchService.isCacheValid() && !searchQuery && searchMode === "all") {
            AppSearchService.setCachedDefaultSections(sections, flatModel);
            _saveDiskCache(sections);
        }

        selectedFlatIndex = restoreSelection(flatModel);
        updateSelectedItem();


        if (currentVersion !== _searchVersion)
            return;

        for (var i = 0; i < newSections.length; i++) {
            var sid = newSections[i].id;
            if (collapsedSections[sid] !== undefined)
                newSections[i].collapsed = collapsedSections[sid];
        }

        _applyHighlights(newSections, searchQuery);
        flatModel = Scorer.flattenSections(newSections);
        sections = newSections;
        selectedFlatIndex = restoreSelection(flatModel);
        updateSelectedItem();
        isSearching = false;
        searchCompleted();
    }

    function performFileSearch() {
        if (!DSearchService.dsearchAvailable)
            return;
        var fileQuery = "";
        if (searchQuery.startsWith("/")) {
            fileQuery = searchQuery.substring(1).trim();
        } else if (searchMode === "files") {
            fileQuery = searchQuery.trim();
        } else {
            return;
        }

        if (fileQuery.length < 2) {
            isFileSearching = false;
            return;
        }

        isFileSearching = true;
        var params = {
            limit: 20,
            fuzzy: true,
            sort: fileSearchSort || "score",
            desc: true
        };

        if (DSearchService.supportsTypeFilter) {
            params.type = (fileSearchType && fileSearchType !== "all") ? fileSearchType : "all";
        }
        if (fileSearchExt) {
            params.ext = fileSearchExt;
        }
        if (fileSearchFolder) {
            params.folder = fileSearchFolder;
        }

        DSearchService.search(fileQuery, params, function (response) {
            isFileSearching = false;
            if (response.error)
                return;
            var fileItems = [];
            var hits = response.result?.hits || [];

            for (var i = 0; i < hits.length; i++) {
                var hit = hits[i];
                var docTypes = hit.locations?.doc_type;
                var isDir = docTypes ? !!docTypes["dir"] : false;
                fileItems.push(transformFileResult({
                    path: hit.id || "",
                    score: hit.score || 0,
                    is_dir: isDir
                }));
            }

            var fileSections = [];
            var showType = fileSearchType || "all";

            if (showType === "all" && DSearchService.supportsTypeFilter) {
                var onlyFiles = [];
                var onlyDirs = [];
                for (var j = 0; j < fileItems.length; j++) {
                    if (fileItems[j].data?.is_dir)
                        onlyDirs.push(fileItems[j]);
                    else
                        onlyFiles.push(fileItems[j]);
                }
                if (onlyFiles.length > 0) {
                    fileSections.push({
                        id: "files",
                        title: I18n.tr("Files"),
                        icon: "insert_drive_file",
                        priority: 4,
                        items: onlyFiles,
                        collapsed: collapsedSections["files"] || false,
                        flatStartIndex: 0
                    });
                }
                if (onlyDirs.length > 0) {
                    fileSections.push({
                        id: "folders",
                        title: I18n.tr("Folders"),
                        icon: "folder",
                        priority: 4.1,
                        items: onlyDirs,
                        collapsed: collapsedSections["folders"] || false,
                        flatStartIndex: 0
                    });
                }
            } else {
                var filesIcon = showType === "dir" ? "folder" : showType === "file" ? "insert_drive_file" : "folder";
                var filesTitle = showType === "dir" ? I18n.tr("Folders") : I18n.tr("Files");
                if (fileItems.length > 0) {
                    fileSections.push({
                        id: "files",
                        title: filesTitle,
                        icon: filesIcon,
                        priority: 4,
                        items: fileItems,
                        collapsed: collapsedSections["files"] || false,
                        flatStartIndex: 0
                    });
                }
            }

            var newSections;
            if (searchMode === "files") {
                newSections = fileSections;
            } else {
                var existingNonFile = sections.filter(function (s) {
                    return s.id !== "files" && s.id !== "folders";
                });
                newSections = existingNonFile.concat(fileSections);
            }
            newSections.sort(function (a, b) {
                return a.priority - b.priority;
            });
            _applyHighlights(newSections, searchQuery);
            flatModel = Scorer.flattenSections(newSections);
            sections = newSections;
            selectedFlatIndex = getFirstItemIndex();
            updateSelectedItem();
        });
    }

    function searchApps(query) {
        var apps = AppSearchService.searchApplications(query);
        var items = [];

        for (var i = 0; i < apps.length; i++) {
            items.push(getOrTransformApp(apps[i]));
        }

        var coreApps = AppSearchService.getCoreApps(query);
        for (var i = 0; i < coreApps.length; i++) {
            items.push(transformCoreApp(coreApps[i]));
        }

        return items;
    }

    function transformApp(app) {
        var appId = app.id || app.execString || app.exec || "";
        var override = SessionData.getAppOverride(appId);
        return Transform.transformApp(app, override, [], I18n.tr("Launch"));
    }

    function transformCoreApp(app) {
        return Transform.transformCoreApp(app, I18n.tr("Open"));
    }


    function getFrecencyForItem(item) {
        if (item.type !== "app")
            return null;

        var appId = item.id;
        var usageRanking = AppUsageHistoryData.appUsageRanking || {};

        var idVariants = [appId, appId.replace(".desktop", "")];
        var usageData = null;

        for (var i = 0; i < idVariants.length; i++) {
            if (usageRanking[idVariants[i]]) {
                usageData = usageRanking[idVariants[i]];
                break;
            }
        }

        return {
            usageCount: usageData?.usageCount || 0
        };
    }

    function getFirstItemIndex() {
        return Nav.getFirstItemIndex(flatModel);
    }

    function _getCachedModeData(mode) {
        return _modeSectionsCache[mode] || null;
    }

    function _setCachedModeData(mode, sectionsData, flatModelData) {
        var cache = Object.assign({}, _modeSectionsCache);
        cache[mode] = {
            sections: sectionsData,
            flatModel: flatModelData
        };
        _modeSectionsCache = cache;
    }

    function _clearModeCache() {
        _modeSectionsCache = {};
    }

    function _saveDiskCache(sectionsData) {
        var serializable = [];
        for (var i = 0; i < sectionsData.length; i++) {
            var s = sectionsData[i];
            var items = [];
            var srcItems = s.items || [];
            for (var j = 0; j < srcItems.length; j++) {
                var it = srcItems[j];
                items.push({
                    id: it.id,
                    type: it.type,
                    name: it.name || "",
                    subtitle: it.subtitle || "",
                    icon: it.icon || "",
                    iconType: it.iconType || "image",
                    iconFull: it.iconFull || "",
                    section: it.section || "",
                    isCore: it.isCore || false
                });
            }
            serializable.push({
                id: s.id,
                title: s.title || "",
                icon: s.icon || "",
                priority: s.priority || 0,
                items: items
            });
        }
        CacheData.saveLauncherCache(serializable);
    }

    function _actionsFromDesktopEntry(appId) {
        if (!appId)
            return [];
        var entry = DesktopEntries.heuristicLookup(appId);
        if (!entry || !entry.actions || entry.actions.length === 0)
            return [];
        var result = [];
        for (var i = 0; i < entry.actions.length; i++) {
            result.push({
                name: entry.actions[i].name,
                icon: "play_arrow",
                actionData: entry.actions[i]
            });
        }
        return result;
    }

    function _loadDiskCache() {
        var cached = CacheData.loadLauncherCache();
        if (!cached || !Array.isArray(cached) || cached.length === 0)
            return null;

        var sectionsData = [];
        for (var i = 0; i < cached.length; i++) {
            var s = cached[i];
            var items = [];
            var srcItems = s.items || [];
            for (var j = 0; j < srcItems.length; j++) {
                var it = srcItems[j];
                items.push({
                    id: it.id || "",
                    type: it.type || "app",
                    name: it.name || "",
                    subtitle: it.subtitle || "",
                    icon: it.icon || "",
                    iconType: it.iconType || "image",
                    iconFull: it.iconFull || "",
                    section: it.section || "",
                    isCore: it.isCore || false,
                    data: {
                        id: it.id
                    },
                    actions: _actionsFromDesktopEntry(it.id),
                    primaryAction: it.type === "app" && !it.isCore ? {
                        name: I18n.tr("Launch"),
                        icon: "open_in_new",
                        action: "launch"
                    } : null,
                    _diskCached: true,
                    _hName: "",
                    _hSub: "",
                    _hRich: false,
                    _preScored: undefined
                });
            }
            sectionsData.push({
                id: s.id || "",
                title: s.title || "",
                icon: s.icon || "",
                priority: s.priority || 0,
                items: items,
                collapsed: false,
                flatStartIndex: 0
            });
        }
        return sectionsData;
    }

    function updateSelectedItem() {
        if (selectedFlatIndex >= 0 && selectedFlatIndex < flatModel.length) {
            var entry = flatModel[selectedFlatIndex];
            selectedItem = entry.isHeader ? null : entry.item;
        } else {
            selectedItem = null;
        }
    }

    function _applyHighlights(sectionsData, query) {
        if (!query || query.length === 0) {
            for (var i = 0; i < sectionsData.length; i++) {
                var items = sectionsData[i].items;
                for (var j = 0; j < items.length; j++) {
                    var item = items[j];
                    item._hName = item.name || "";
                    item._hSub = item.subtitle || "";
                    item._hRich = false;
                }
            }
            return;
        }

        var highlightColor = Theme.primary;
        var nameColor = Theme.surfaceText;
        var subColor = Theme.surfaceVariantText;
        var lowerQuery = query.toLowerCase();

        for (var i = 0; i < sectionsData.length; i++) {
            var items = sectionsData[i].items;
            for (var j = 0; j < items.length; j++) {
                var item = items[j];
                item._hName = _highlightField(item.name || "", lowerQuery, query.length, nameColor, highlightColor);
                item._hSub = _highlightField(item.subtitle || "", lowerQuery, query.length, subColor, highlightColor);
                item._hRich = true;
            }
        }
    }

    function _highlightField(text, lowerQuery, queryLen, baseColor, highlightColor) {
        if (!text)
            return "";
        var idx = text.toLowerCase().indexOf(lowerQuery);
        if (idx === -1)
            return text;
        var before = text.substring(0, idx);
        var match = text.substring(idx, idx + queryLen);
        var after = text.substring(idx + queryLen);
        return '<span style="color:' + baseColor + '">' + before + '</span><span style="color:' + highlightColor + '; font-weight:600">' + match + '</span><span style="color:' + baseColor + '">' + after + '</span>';
    }

    function getCurrentSectionViewMode() {
        if (selectedFlatIndex < 0 || selectedFlatIndex >= flatModel.length)
            return "list";
        var entry = flatModel[selectedFlatIndex];
        if (!entry || entry.isHeader)
            return "list";
        return getSectionViewMode(entry.sectionId);
    }

    function getGridColumns(sectionId) {
        return Nav.getGridColumns(getSectionViewMode(sectionId), gridColumns);
    }

    function _cancelPendingSelectionReset() {
        _queryDrivenSearch = false;
    }

    function selectNext() {
        keyboardNavigationActive = true;
        _cancelPendingSelectionReset();
        var newIndex = Nav.calculateNextIndex(flatModel, selectedFlatIndex, null, null, gridColumns, getSectionViewMode);
        if (newIndex !== selectedFlatIndex) {
            selectedFlatIndex = newIndex;
            updateSelectedItem();
        }
    }

    function selectPrevious() {
        keyboardNavigationActive = true;
        _cancelPendingSelectionReset();
        var newIndex = Nav.calculatePrevIndex(flatModel, selectedFlatIndex, null, null, gridColumns, getSectionViewMode);
        if (newIndex !== selectedFlatIndex) {
            selectedFlatIndex = newIndex;
            updateSelectedItem();
        }
    }

    function selectRight() {
        keyboardNavigationActive = true;
        _cancelPendingSelectionReset();
        var newIndex = Nav.calculateRightIndex(flatModel, selectedFlatIndex, getSectionViewMode);
        if (newIndex !== selectedFlatIndex) {
            selectedFlatIndex = newIndex;
            updateSelectedItem();
        }
    }

    function selectLeft() {
        keyboardNavigationActive = true;
        _cancelPendingSelectionReset();
        var newIndex = Nav.calculateLeftIndex(flatModel, selectedFlatIndex, getSectionViewMode);
        if (newIndex !== selectedFlatIndex) {
            selectedFlatIndex = newIndex;
            updateSelectedItem();
        }
    }

    function selectNextSection() {
        keyboardNavigationActive = true;
        _cancelPendingSelectionReset();
        var newIndex = Nav.calculateNextSectionIndex(flatModel, selectedFlatIndex);
        if (newIndex !== selectedFlatIndex) {
            selectedFlatIndex = newIndex;
            updateSelectedItem();
        }
    }

    function selectPreviousSection() {
        keyboardNavigationActive = true;
        _cancelPendingSelectionReset();
        var newIndex = Nav.calculatePrevSectionIndex(flatModel, selectedFlatIndex);
        if (newIndex !== selectedFlatIndex) {
            selectedFlatIndex = newIndex;
            updateSelectedItem();
        }
    }

    function selectPageDown(visibleItems) {
        keyboardNavigationActive = true;
        _cancelPendingSelectionReset();
        var newIndex = Nav.calculatePageDownIndex(flatModel, selectedFlatIndex, visibleItems);
        if (newIndex !== selectedFlatIndex) {
            selectedFlatIndex = newIndex;
            updateSelectedItem();
        }
    }

    function selectPageUp(visibleItems) {
        keyboardNavigationActive = true;
        _cancelPendingSelectionReset();
        var newIndex = Nav.calculatePageUpIndex(flatModel, selectedFlatIndex, visibleItems);
        if (newIndex !== selectedFlatIndex) {
            selectedFlatIndex = newIndex;
            updateSelectedItem();
        }
    }

    function selectIndex(index) {
        keyboardNavigationActive = false;
        if (index >= 0 && index < flatModel.length && !flatModel[index].isHeader) {
            selectedFlatIndex = index;
            updateSelectedItem();
        }
    }

    function toggleSection(sectionId) {
        _clearModeCache();
        var newCollapsed = Object.assign({}, collapsedSections);
        var currentState = newCollapsed[sectionId];

        if (currentState === undefined) {
            for (var i = 0; i < sections.length; i++) {
                if (sections[i].id === sectionId) {
                    currentState = sections[i].collapsed || false;
                    break;
                }
            }
        }

        newCollapsed[sectionId] = !currentState;
        collapsedSections = newCollapsed;

        var newSections = sections.slice();
        for (var i = 0; i < newSections.length; i++) {
            if (newSections[i].id === sectionId) {
                newSections[i] = Object.assign({}, newSections[i], {
                    collapsed: newCollapsed[sectionId]
                });
            }
        }
        flatModel = Scorer.flattenSections(newSections);
        sections = newSections;

        if (selectedFlatIndex >= flatModel.length) {
            selectedFlatIndex = getFirstItemIndex();
        }
        updateSelectedItem();
    }

    function executeSelected() {
        if (searchDebounce.running) {
            searchDebounce.stop();
            performSearch();
        }
        if (!selectedItem)
            return;
        executeItem(selectedItem);
    }

    function executeItem(item) {
        if (!item)
            return;

        switch (item.type) {
        case "app":
            if (item.isCore) {
                AppSearchService.executeCoreApp(item.data);
            } else if (item.data?.isAction) {
                launchAppAction(item.data);
            } else {
                launchApp(item.data);
            }
            break;
        case "file":
            openFile(item.data?.path);
            break;
        case "window":
            WindowSearchService.activateWindow(item.data?.windowId);
            break;
        default:
            return;
        }

        itemExecuted();
    }

    function executeAction(item, action) {
        if (!item || !action)
            return;
        switch (action.action) {
        case "launch":
            executeItem(item);
            break;
        case "open":
            openFile(item.data.path);
            break;
        case "open_folder":
            openFolder(item.data.path);
            break;
        case "copy_path":
            copyToClipboard(item.data.path);
            break;
        case "open_terminal":
            openTerminal(item.data.path);
            break;
        case "copy":
            copyToClipboard(item.name);
            break;
        case "focus":
            executeItem(item);
            break;
        case "execute":
            executeItem(item);
            break;
        case "launch_dgpu":
            if (item.type === "app" && item.data) {
                launchAppWithNvidia(item.data);
            }
            break;
        default:
            if (item.type === "app" && action.actionData) {
                launchAppAction({
                    parentApp: item.data,
                    actionData: action.actionData
                });
            }
        }

        itemExecuted();
    }

    function _resolveDesktopEntry(app) {
        if (!app)
            return null;
        if (app.command)
            return app;
        var id = app.id || app.execString || app.exec || "";
        if (!id)
            return null;
        return DesktopEntries.heuristicLookup(id);
    }

    function launchApp(app) {
        var entry = _resolveDesktopEntry(app);
        if (!entry)
            return;
        SessionService.launchDesktopEntry(entry);
        AppUsageHistoryData.addAppUsage(entry);
    }

    function launchAppWithNvidia(app) {
        var entry = _resolveDesktopEntry(app);
        if (!entry)
            return;
        SessionService.launchDesktopEntry(entry, true);
        AppUsageHistoryData.addAppUsage(entry);
    }

    function launchAppAction(actionItem) {
        if (!actionItem || !actionItem.actionData)
            return;
        var entry = _resolveDesktopEntry(actionItem.parentApp);
        if (!entry)
            return;
        SessionService.launchDesktopAction(entry, actionItem.actionData);
        AppUsageHistoryData.addAppUsage(entry);
    }

    function openFile(path) {
        if (!path)
            return;
        Qt.openUrlExternally("file://" + path);
    }

    function openFolder(path) {
        if (!path)
            return;
        var folder = path.substring(0, path.lastIndexOf("/"));
        Qt.openUrlExternally("file://" + folder);
    }

    function openTerminal(path) {
        if (!path)
            return;
        var terminal = Quickshell.env("TERMINAL") || "xterm";
        Quickshell.execDetached({
            command: [terminal],
            workingDirectory: path
        });
    }

    function copyToClipboard(text) {
        if (!text)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", text]);
    }
}
