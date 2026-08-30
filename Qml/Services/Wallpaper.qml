pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    property Item colorSourceImage: null
    property int wallpaperType: 0
    property string pendingVideoPath: ""
    property string thumbnailJobPath: ""
    property var thumbnailAvailability: ({})
    property var thumbnailCheckQueue: []
    property var checkBatch: []
    readonly property string thumbnailCheckScript: "while [ $# -ge 2 ]; do [ -s \"$1\" ] && printf '%s\\n' \"$2\"; shift 2; done"
    readonly property var visibleWallpapers: WallpaperFileModels.filteredWallpaperList.filter(path => wallpaperType === 1 ? isVideo(path) : !isVideo(path))

    function setWallpaper(path, colorSource) {
        Quickshell.execDetached({
            command: ["sh", "-c", `printf '%s' ${JSON.stringify(path)} > ${JSON.stringify(Paths.currentWallpaperFile)}`]
        });
        if (colorSource !== "" && colorSourceImage)
            colorSourceImage.source = "file://" + colorSource;
    }

    function updateWallpaperColors(path) {
        if (path === "" || !colorSourceImage)
            return;
        colorSourceImage.source = "file://" + thumbnailPathFor(path);
    }

    function setVideoWallpaper(path) {
        pendingVideoPath = path;
        thumbnailJobPath = path;
    }

    function isVideo(path) {
        return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path);
    }

    function thumbnailPathFor(path) {
        return isVideo(path) ? `${Paths.cacheDir}/vast-shell/vast-wallpaper-${Qt.md5(path)}.png` : path;
    }

    function markThumbnail(path, exists) {
        const previous = thumbnailAvailability[path];
        if (path === "" || previous === exists)
            return;
        const updated = Object.assign({}, thumbnailAvailability);
        updated[path] = exists;
        thumbnailAvailability = updated;
        if (path !== Paths.currentWallpaper)
            return;
        if (!exists) {
            if (previous === undefined)
                ensureThumbnail(path);
            return;
        }
        if (path === Paths.currentWallpaper && pendingVideoPath === "")
            updateWallpaperColors(path);
    }

    function ensureThumbnail(path) {
        if (path === "" || thumbnailAvailability[path] === true || thumbnailJobPath === path)
            return;
        thumbnailJobPath = path;
    }

    function requestThumbnailChecks() {
        for (const path of WallpaperFileModels.filteredWallpaperList) {
            if (!isVideo(path) || thumbnailAvailability[path] !== undefined || thumbnailCheckQueue.includes(path))
                continue;
            thumbnailCheckQueue.push(path);
        }
        drainThumbnailChecks();
    }

    function drainThumbnailChecks() {
        if (thumbnailChecker.running || thumbnailCheckQueue.length === 0)
            return;
        checkBatch = thumbnailCheckQueue.splice(0, thumbnailCheckQueue.length);
        const args = ["sh", "-c", thumbnailCheckScript, "sh"];
        for (const path of checkBatch)
            args.push(thumbnailPathFor(path), path);
        thumbnailChecker.command = args;
        thumbnailChecker.running = true;
    }

    Connections {
        target: WallpaperFileModels
        function onFilteredWallpaperListChanged(): void {
            root.requestThumbnailChecks();
        }
    }

    Connections {
        target: Paths
        function onCurrentWallpaperChanged(): void {
            root.updateWallpaperColors(Paths.currentWallpaper);
        }
    }

    Connections {
        target: Configs.colors
        function onSchemeChanged(): void {
            root.updateWallpaperColors(Paths.currentWallpaper);
        }
    }

    Process {
        id: thumbnailGenerator

        command: ["mkdir", "-p", `${Paths.cacheDir}/vast-shell`]
        running: true
    }

    Process {
        id: thumbnailChecker

        stdout: SplitParser {
            onRead: data => root.markThumbnail(data, true)
        }

        onExited: { // qmllint disable signal-handler-parameters
            for (const path of root.checkBatch)
                if (root.thumbnailAvailability[path] === undefined)
                    root.markThumbnail(path, false);
            root.checkBatch = [];
            root.drainThumbnailChecks();
        }
    }

    Process {
        id: thumbnailExtractor

        command: ["sh", "-c", `test -s ${JSON.stringify(root.thumbnailPathFor(root.thumbnailJobPath))} || ffmpeg -y -loglevel error -i ${JSON.stringify(root.thumbnailJobPath)} -frames:v 1 ${JSON.stringify(root.thumbnailPathFor(root.thumbnailJobPath))}`]
        running: root.thumbnailJobPath !== ""
        onExited: function (exitCode, exitStatus) { // qmllint disable signal-handler-parameters
            const job = root.thumbnailJobPath;
            root.thumbnailJobPath = "";
            root.markThumbnail(job, exitCode === 0);
            if (root.pendingVideoPath === "")
                return;
            if (exitCode === 0) {
                if (root.colorSourceImage)
                    root.colorSourceImage.source = "file://" + root.thumbnailPathFor(root.pendingVideoPath);
            } else {
                root.pendingVideoPath = "";
            }
        }
    }
}
