pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Utils

Singleton {
    id: root

    property alias greeterConfig: greeterConfigJson
    property string lastStaticTarget: ""
    property string lastVideoTarget: ""
    property bool videoThumbPending: false
    property int thumbnailVersion: 0

    function thumbnailCachePathFor(path) {
        return `${Paths.cacheDir}/vast-shell/greeter-wallpaper-${Qt.md5(path)}.png`;
    }

    function uploadStatic(path) {
        const extension = root.extensionOf(path);
        if (extension === "") {
            console.warn("[GreeterConfig] upload static: invalid path", path);
            return;
        }
        root.lastStaticTarget = "/etc/vast-shell/wallpaper." + extension;
        staticUpload.command = [Paths.projectRoot + "/Assets/shell/pkexec.sh", "sh", "-c", `mkdir -p /etc/vast-shell && cp -f ${JSON.stringify(path)} ${JSON.stringify(root.lastStaticTarget)}`];
        staticUpload.running = true;
    }

    function uploadVideo(path) {
        const extension = root.extensionOf(path);
        if (extension === "") {
            console.warn("[GreeterConfig] upload video: invalid path", path);
            return;
        }
        root.lastVideoTarget = "/etc/vast-shell/wallpaper." + extension;
        videoUpload.command = [Paths.projectRoot + "/Assets/shell/pkexec.sh", "sh", "-c", `mkdir -p /etc/vast-shell && cp -f ${JSON.stringify(path)} ${JSON.stringify(root.lastVideoTarget)}`];
        videoUpload.running = true;
    }

    function extensionOf(path) {
        if (!path || typeof path !== "string")
            return "";
        const clean = path.startsWith("file://") ? decodeURIComponent(path.slice(7)) : path;
        const basename = clean.split("/").pop();
        if (!basename)
            return "";
        const parts = basename.split(".");
        return parts.length > 1 ? parts.pop().toLowerCase() : "";
    }

    FileView {
        id: greeterFile

        path: Paths.shellDir + "/greeter.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onSaved: etcSync.running = true

        JsonAdapter { // qmllint disable
            id: greeterConfigJson

            property bool useVideoWallpaper: false
            property string staticWallpaper: "/etc/vast-shell/wallpaper.png"
            property string videoWallpaper: "/etc/vast-shell/wallpaper.mp4"
        }
    }

    Component.onCompleted: {
        const videoPath = root.greeterConfig.videoWallpaper;
        if (root.greeterConfig.useVideoWallpaper && videoPath !== "") {
            videoThumbGen.command = ["ffmpeg", "-y", "-loglevel", "error", "-i", videoPath, "-frames:v", "1", root.thumbnailCachePathFor(videoPath)];
            root.videoThumbPending = true;
        }
    }

    Process {
        id: staticUpload

        stderr: SplitParser {
            onRead: data => console.log("[GreeterConfig] upload static stderr:", data)
        }
        onExited: function (exitCode, exitStatus) { // qmllint disable signal-handler-parameters
            console.log("[GreeterConfig] upload static exited:", exitCode, root.lastStaticTarget);
            if (exitCode === 0) {
                root.greeterConfig.staticWallpaper = root.lastStaticTarget;
                root.thumbnailVersion++;
            }
        }
    }

    Process {
        id: videoUpload

        stderr: SplitParser {
            onRead: data => console.log("[GreeterConfig] upload video stderr:", data)
        }
        onExited: function (exitCode, exitStatus) { // qmllint disable signal-handler-parameters
            console.log("[GreeterConfig] upload video exited:", exitCode, root.lastVideoTarget);
            if (exitCode === 0) {
                root.greeterConfig.videoWallpaper = root.lastVideoTarget;
                videoThumbGen.command = ["ffmpeg", "-y", "-loglevel", "error", "-i", root.lastVideoTarget, "-frames:v", "1", root.thumbnailCachePathFor(root.lastVideoTarget)];
                root.videoThumbPending = true;
            }
        }
    }

    Process {
        id: videoThumbGen

        running: root.videoThumbPending
        stderr: SplitParser {
            onRead: data => console.log("[GreeterConfig] video thumb stderr:", data)
        }
        onExited: function (exitCode, exitStatus) { // qmllint disable signal-handler-parameters
            root.videoThumbPending = false;
            console.log("[GreeterConfig] video thumbnail:", exitCode === 0 ? "ok" : "failed", root.lastVideoTarget);
            root.thumbnailVersion++;
        }
    }

    Process {
        id: etcSync

        command: [Paths.projectRoot + "/Assets/shell/pkexec.sh", "sh", "-c", `mkdir -p /etc/vast-shell && install -m 644 ${JSON.stringify(Paths.shellDir + "/greeter.json")} /etc/vast-shell/greeter.json`]
        stderr: SplitParser {
            onRead: data => console.log("[GreeterConfig] pkexec stderr:", data)
        }
    }
}
