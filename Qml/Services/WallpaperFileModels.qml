pragma Singleton

import Qt.labs.folderlistmodel
import QtQuick
import Quickshell

import Vast.Search

import qs.Core.Utils

Singleton {
    id: root

    property string currentWallpaper: Paths.currentWallpaper
    property string searchQuery: ""
    property string debouncedSearchQuery: ""
    property var wallpaperList: []
    readonly property var filteredWallpaperList: {
        if (debouncedSearchQuery === "")
            return wallpaperList;

        const query = debouncedSearchQuery.trim();
        if (query === "")
            return wallpaperList;

        // fzy scores grow with needle length, so the floor is per query character
        const minScore = query.length * SearchEngine.fileThreshold;
        const scored = [];
        for (const path of wallpaperList) {
            const result = SearchEngine.score(query, path.split('/').pop());
            if (result >= minScore)
                scored.push([result, path]);
        }
        return scored.sort((a, b) => b[0] - a[0]).map(entry => entry[1]);
    }

    FolderListModel {
        id: wallpaperFolder

        folder: Qt.resolvedUrl(Paths.wallpaperDir)
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi", "*.m4v"]
        showDirs: false
        showDotAndDotDot: false
        showHidden: false

        onCountChanged: {
            let list = [];
            for (let i = 0; i < count; i++) {
                list.push(get(i, "filePath"));
            }
            root.wallpaperList = list;
        }
    }
}
