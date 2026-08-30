pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    property string state: "idle"
    property string errorMessage: ""
    property string fgPath: ""
    readonly property bool generating: generateFg.running

    readonly property string cacheDir: Paths.home + "/.cache/vast-shell/depthwp"
    readonly property string scriptPath: Paths.projectRoot + "/Assets/shell/extract-fg.sh"
    readonly property bool currentWallpaperIsVideo: /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(Paths.currentWallpaper)

    function onToggle(enabled) {
        if (enabled) {
            checkOrGenerate();
        } else {
            Configs.wallpaper.depthWallpaperEnabled = false;
            state = "idle";
        }
    }

    function checkOrGenerate() {
        if (currentWallpaperIsVideo) {
            Configs.wallpaper.depthWallpaperEnabled = false;
            state = "idle";
            return;
        }
        if (Configs.wallpaper.depthWallpaperSource !== "" && Configs.wallpaper.depthFgPath !== "") {
            if (!Configs.wallpaper.depthWallpaperEnabled)
                Configs.wallpaper.depthWallpaperEnabled = true;
            fgPath = Configs.wallpaper.depthFgPath;
            state = "done";
        } else {
            generateFg.running = true;
        }
    }

    function runRembg() {
        if (currentWallpaperIsVideo)
            return;
        state = "processing";
        ToastService.show(qsTr("Generating depth wallpaper\u2026"), qsTr("Depth Wallpaper"), "image", 0);
        generateFg.running = true;
    }

    Process {
        id: generateFg

        property int exitedCode: 0
        command: ["bash", root.scriptPath, root.cleanPath(Paths.currentWallpaper), root.cacheDir]

        stdout: SplitParser {
            onRead: data => {
                if (/FOREGROUND/.test(data)) {
                    var path = data.split(" ")[1];
                    root.fgPath = path;
                    Configs.wallpaper.depthFgPath = path;
                    Configs.wallpaper.depthWallpaperSource = root.cleanPath(Paths.currentWallpaper);
                    Configs.wallpaper.depthWallpaperEnabled = true;
                    root.state = "done";
                }
            }
        }

        onRunningChanged: {
            if (generateFg.running) {
                root.state = "processing";
            } else if (root.state === "processing" && generateFg.exitedCode !== 0) {
                root.state = "error";
                root.errorMessage = "Foreground extraction failed";
            }
        }

        onExited: function (code) { // qmllint disable
            if (code === 0 && root.state === "done") {
                ToastService.show(qsTr("Depth wallpaper ready"), qsTr("Depth Wallpaper"), "image", 5000);
            } else if (code !== 0 && root.state !== "done") {
                root.state = "error";
                root.errorMessage = "Foreground extraction failed (exit " + code + ")";
                ToastService.show(qsTr("Foreground extraction failed"), qsTr("Depth Wallpaper"), "error", 5000);
            }
            exitedCode = code;
        }
    }

    function cleanPath(path) {
        return path.replace(/^file:\/\//, "");
    }

    Connections {
        target: Configs.wallpaper

        function onDepthWallpaperEnabledChanged() {
            if (Configs.wallpaper.depthWallpaperEnabled && root.state !== "done" && root.state !== "processing") {
                root.checkOrGenerate();
            }
        }
    }

    Connections {
        target: Paths

        function onCurrentWallpaperChanged() {
            if (root.currentWallpaperIsVideo) {
                Configs.wallpaper.depthWallpaperEnabled = false;
                root.state = "idle";
                root.fgPath = "";
                return;
            }
            if (Configs.wallpaper.autoProcessedDepthWallpaper && Configs.wallpaper.depthWallpaperEnabled) {
                root.state = "idle";
                root.fgPath = "";
                root.runRembg();
            }
        }
    }
}
