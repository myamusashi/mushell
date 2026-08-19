pragma Singleton

import Qt.labs.folderlistmodel
import QtQuick
import Quickshell

import qs.Core.Utils

Singleton {
    id: root

    property string currentWallpaper: Paths.currentWallpaper
    property string searchQuery: ""
    property string debouncedSearchQuery: ""
    property var wallpaperList: []
    property var filteredWallpaperList: {
        if (debouncedSearchQuery === "")
            return wallpaperList;

        const query = debouncedSearchQuery.toLowerCase();
        return wallpaperList.filter(path => {
            const fileName = path.split('/').pop().toLowerCase();
            return fileName.includes(query);
        });
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
