pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.Audio

import qs.Core.Configs
import "shellUtils.js" as Utils

Singleton {
    id: root

    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/screenshot"
    readonly property string videoDir: Quickshell.env("HOME") + "/Videos/Shell"
    readonly property string thumbnailDir: Quickshell.env("HOME") + "/.cache/thumbnails/normal"

    readonly property bool connectedAudioDevice: AudioDevicesWatcher.connected
    readonly property int audioDevicesCount: AudioDevicesWatcher.devices.count()

    property bool isRecording: false
    property string currentOutputFile: ""
    property int recordingPid: -1
    property int recordingElapsedSeconds: 0

    property string audioDevice: ""
    property string audioDeviceDescription: ""
    property string videoCodec: ""
    property string audioCodec: ""
    property string driDevice: ""
    property string encodeResolution: ""
    property string lowPower: "auto"
    property string bitrate: "5 MB"
    property int maxFps: 60
    property bool historyMode: false
    property bool includeAudio: false
    property bool showCursor: true

    property var _thumbnailQueue: []
    property var _currentThumbnailJob: null
    property bool _thumbnailBusy: false

    property var _cache: []
    property var defaultSink: sinks()[0] ?? null
    property var defaultSource: sources()[0] ?? null

    signal devicesChanged

    signal thumbnailReady(string videoPath, string thumbnailPath)

    readonly property string pidFile: "/tmp/wl-screenrec.pid"
    readonly property string videoStateFile: "/tmp/wl-screenrec.video"

    onAudioDeviceChanged: {}
    onAudioDeviceDescriptionChanged: {}
    onVideoCodecChanged: {
        if (!_loadingFromConfig)
            Configs.screenRecorder.videoCodec = root.videoCodec;
    }
    onAudioCodecChanged: {
        if (!_loadingFromConfig)
            Configs.screenRecorder.audioCodec = root.audioCodec;
    }
    onDriDeviceChanged: {}
    onEncodeResolutionChanged: {}
    onLowPowerChanged: {
        if (!_loadingFromConfig)
            Configs.screenRecorder.lowPower = root.lowPower;
    }
    onBitrateChanged: {
        if (!_loadingFromConfig)
            Configs.screenRecorder.bitrate = root.bitrate;
    }
    onMaxFpsChanged: {
        if (!_loadingFromConfig)
            Configs.screenRecorder.maxFps = root.maxFps;
    }
    onHistoryModeChanged: {
        if (!_loadingFromConfig)
            Configs.screenRecorder.historyMode = root.historyMode;
    }
    onIncludeAudioChanged: {}
    onShowCursorChanged: {
        if (!_loadingFromConfig)
            Configs.screenRecorder.showCursor = root.showCursor;
    }
    property bool _loadingFromConfig: false
    onIsRecordingChanged: {
        if (root.isRecording) {
            root.recordingElapsedSeconds = 0;
            elapsedTimer.start();
        } else {
            elapsedTimer.stop();
        }
    }
    onCurrentOutputFileChanged: {}

    Connections {
        target: AudioDevicesWatcher

        function onDevicesChanged() {
            root.rebuild();
        }
        function onConnectedChanged() {
            root.rebuild();
        }
    }

    Screenshotter {
        id: screenshotter

        screenshotDir: root.screenshotDir

        onNotify: (summary, body, urgency, icon, app, actions) => {
            root.sendNotification(summary, body, urgency, icon, app, actions);
        }
    }

    Process {
        id: recordingProcess

        stdinEnabled: false

        onStarted: {
            const pid = Number(processId);
            if (pid > 0) {
                root.recordingPid = pid;
                root.isRecording = true;
                writePidFile.running = true;
            }
        }
        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            root.recordingPid = -1;
            if (root.isRecording) {
                root.isRecording = false;
                const vid = root.currentOutputFile;
                root.currentOutputFile = "";
                killTimer.running = false;
                root.cleanupFiles();
                root.onRecordingStopped(vid);
            }
        }
    }

    Process {
        id: writePidFile

        command: ["sh", "-c", "echo " + root.recordingPid + " > " + root.pidFile + "; echo '" + root.currentOutputFile.replace(/'/g, "'\\''") + "' > " + root.videoStateFile]
        running: false
    }

    Timer {
        id: elapsedTimer

        interval: 1000
        repeat: true
        onTriggered: root.recordingElapsedSeconds++
    }

    Process {
        id: removePidFile

        command: ["rm", "-f", root.pidFile, root.videoStateFile]
        running: false
    }

    Process {
        id: checkProcess

        running: false
        command: ["sh", "-c", "cat /tmp/wl-screenrec.pid 2>/dev/null; echo '---'; cat /tmp/wl-screenrec.video 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text;
                const parts = out.split("---");
                const pidStr = (parts[0] || "").trim();
                const videoStr = (parts[1] || "").trim();
                const pid = parseInt(pidStr, 10);

                if (pid > 0 && videoStr) {
                    verifyProcess.targetPid = pid;
                    verifyProcess.targetVideo = videoStr;
                    verifyProcess.command = ["kill", "-s", "0", String(pid)];
                    verifyProcess.running = true;
                } else {
                    root.cleanupFiles();
                }
            }
        }
    }

    Process {
        id: verifyProcess

        property int targetPid: -1
        property string targetVideo: ""
        running: false

        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            const pid = verifyProcess.targetPid;
            const video = verifyProcess.targetVideo;
            verifyProcess.targetPid = -1;
            verifyProcess.targetVideo = "";

            if (pid > 0 && video) {
                if (code === 0) {
                    root.recordingPid = pid;
                    root.isRecording = true;
                    root.currentOutputFile = video;
                    root.sendNotification("Recording Restored", "Adopted active recording from previous session.", "normal", "", "screenrecord");
                } else {
                    root.cleanupFiles();
                }
            }
        }
    }

    Timer {
        id: killTimer

        onTriggered: {
            if (root.isRecording && root.recordingPid > 0)
                recordingProcess.signal(9);
        }
    }

    Process {
        id: ffprobeProcess
        property string videoPath
        property string outputDir
        property var callback: null

        command: ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", videoPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                const duration = parseFloat(trimmed);
                const ts = isNaN(duration) ? 0 : duration / 2.0;

                const h = Math.floor(ts / 3600);
                const m = Math.floor((ts % 3600) / 60);
                const s = Math.floor(ts % 60);
                const formatted = String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");

                const fileName = ffprobeProcess.videoPath.split("/").pop();
                const dot = fileName.lastIndexOf(".");
                if (dot <= 0) {
                    root._finishThumbnailJob(ffprobeProcess.videoPath, "", ffprobeProcess.callback);
                    return;
                }

                ffmpegProcess.seek = formatted;
                ffmpegProcess.videoPath = ffprobeProcess.videoPath;
                ffmpegProcess.outputDir = ffprobeProcess.outputDir;
                ffmpegProcess.thumb = ffprobeProcess.outputDir + "/" + fileName.substring(0, dot) + ".png";
                ffmpegProcess.callback = ffprobeProcess.callback;
                ffmpegProcess.running = true;
            }
        }
    }

    Process {
        id: ffmpegProcess

        property string seek
        property string videoPath
        property string thumb
        property string outputDir
        property var callback: null

        // mkdir -p first: requested output dir may not exist yet (e.g. ~/.cache/video-thumbnails)
        command: ["sh", "-c", "mkdir -p \"$1\" && exec ffmpeg -ss \"$2\" -i \"$3\" -vframes 1 -q:v 2 -vf scale=256:-1 \"$4\" -y -v error", "sh", outputDir, seek, videoPath, thumb]

        // qmllint disable
        onExited: (exitCode, exitStatus) => {
            // qmllint enable
            root._finishThumbnailJob(ffmpegProcess.videoPath, exitCode === 0 ? ffmpegProcess.thumb : "", ffmpegProcess.callback);
        }
    }

    // one live instance per actionable notification; collects the chosen
    // action identifier from `notify-send --wait` and opens the target
    Component {
        id: actionNotifyComponent

        Process {
            id: actionProcess

            property string filePath: ""
            property string dirPath: ""

            stdout: StdioCollector {
                onStreamFinished: {
                    const action = text.trim();
                    const target = action === "folder" ? actionProcess.dirPath : actionProcess.filePath;
                    if ((action === "open" || action === "folder" || action === "default") && target)
                        Quickshell.execDetached({
                            command: ["xdg-open", target]
                        });
                    Qt.callLater(actionProcess.destroy);
                }
            }
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached({
            command: ["mkdir", "-p", root.screenshotDir, root.videoDir, root.thumbnailDir]
        });
        root.checkActiveRecording();
        root.isRecordingChanged();
        root.currentOutputFileChanged();
        root._loadingFromConfig = true;
        root.maxFps = Configs.screenRecorder.maxFps;
        root.bitrate = Configs.screenRecorder.bitrate;
        root.videoCodec = Configs.screenRecorder.videoCodec;
        root.audioCodec = Configs.screenRecorder.audioCodec;
        root.lowPower = Configs.screenRecorder.lowPower;
        root.showCursor = Configs.screenRecorder.showCursor;
        root.historyMode = Configs.screenRecorder.historyMode;
        root._loadingFromConfig = false;
    }

    function rebuild() {
        const m = AudioDevicesWatcher.devices;
        const arr = [];
        for (let i = 0; i < m.count(); i++)
            arr.push(m.get(i));
        _cache = arr;
        devicesChanged();
    }

    function all() {
        return _cache;
    }

    function sinks() {
        return _cache.filter(d => d.mediaClass === "sink" && !d.isMonitor);
    }
    function sources() {
        return _cache.filter(d => d.mediaClass === "source" && !d.isMonitor);
    }
    function monitors() {
        return _cache.filter(d => d.isMonitor);
    }
    function inputs() {
        return _cache.filter(d => d.mediaClass === "source");
    }

    function byName(name) {
        return _cache.find(d => d.name === name) ?? null;
    }
    function byId(id) {
        return _cache.find(d => d.id === id) ?? null;
    }

    function checkActiveRecording() {
        checkProcess.running = true;
    }

    function cleanupFiles() {
        removePidFile.running = true;
    }

    function startRecording(geometry, output) {
        if (root.isRecording) {
            root.sendNotification("Recording Active", "A recording is already in progress.", "critical", "dialog-warning", "Screen Record");
            return;
        }

        const cfg = {
            videoCodec: root.videoCodec,
            audioCodec: root.audioCodec,
            encodeResolution: root.encodeResolution,
            driDevice: root.driDevice,
            lowPower: root.lowPower,
            maxFps: root.maxFps,
            bitrate: root.bitrate,
            showCursor: root.showCursor,
            historyMode: root.historyMode,
            includeAudio: root.includeAudio,
            audioDevice: root.audioDevice
        };

        const path = Utils.videoPath(root.videoDir);
        root.currentOutputFile = path;

        const args = Utils.buildWlScreenrecArgs(cfg, geometry, output);
        args.push("-f", path);

        recordingProcess.command = args;
        recordingProcess.running = true;
    }

    function startRecordingToplevel(appId) {
        if (root.isRecording) {
            root.sendNotification("Recording Active", "A recording is already in progress.", "critical", "dialog-warning", "Screen Record");
            return;
        }

        const cfg = {
            videoCodec: root.videoCodec,
            audioCodec: root.audioCodec,
            encodeResolution: root.encodeResolution,
            driDevice: root.driDevice,
            lowPower: root.lowPower,
            maxFps: root.maxFps,
            bitrate: root.bitrate,
            showCursor: root.showCursor,
            historyMode: root.historyMode,
            includeAudio: root.includeAudio,
            audioDevice: root.audioDevice
        };

        const path = Utils.videoPath(root.videoDir);
        root.currentOutputFile = path;

        const args = Utils.buildWlScreenrecArgs(cfg, "", "", "app-id=" + appId);
        args.push("-f", path);

        recordingProcess.command = args;
        recordingProcess.running = true;
    }

    function recordSelection(geometry) {
        if (root.isRecording) {
            stopRecording();
            return;
        }
        startRecording(geometry, "");
    }

    function recordToplevel(appId) {
        if (root.isRecording) {
            stopRecording();
            return;
        }
        startRecordingToplevel(appId);
    }

    function stopRecording() {
        if (!root.isRecording || root.recordingPid <= 0) {
            root.sendNotification("Recording Failed", "No active recording found.", "critical", "dialog-error", "Screen Record");
            return;
        }

        recordingProcess.signal(2);

        killTimer.interval = 10000;
        killTimer.repeat = false;
        killTimer.running = true;
    }

    function saveHistory() {
        if (root.isRecording && root.recordingPid > 0) {
            recordingProcess.signal(10);
            root.sendNotification("Replay Saved", "History buffer written to disk.", "normal", "", "screenrecord");
        }
    }

    function createThumbnail(videoPath, outputDir) {
        root.generate(videoPath, outputDir, null);
    }

    function generate(videoPath, outputDir, callback) {
        const active = root._currentThumbnailJob;
        if (active && active.videoPath === videoPath && active.outputDir === outputDir)
            return;
        for (const job of root._thumbnailQueue)
            if (job.videoPath === videoPath && job.outputDir === outputDir)
                return;
        root._thumbnailQueue.push({
            videoPath: videoPath,
            outputDir: outputDir,
            callback: callback
        });
        root._startNextThumbnailJob();
    }

    function _startNextThumbnailJob() {
        if (root._thumbnailBusy || root._thumbnailQueue.length === 0)
            return;
        const job = root._thumbnailQueue.shift();
        root._currentThumbnailJob = job;
        root._thumbnailBusy = true;
        ffprobeProcess.videoPath = job.videoPath;
        ffprobeProcess.outputDir = job.outputDir;
        ffprobeProcess.callback = job.callback;
        ffprobeProcess.running = true;
    }

    function _finishThumbnailJob(videoPath, thumbnailPath, callback) {
        root.thumbnailReady(videoPath, thumbnailPath);
        if (callback)
            callback(videoPath, thumbnailPath);
        root._currentThumbnailJob = null;
        root._thumbnailBusy = false;
        root._startNextThumbnailJob();
    }

    function screenshotWindow(action) {
        screenshotter.screenshotWindow(action);
    }

    function pickWindowForRecord(callback) {
        screenshotter.pickWindowForRecord(callback);
    }

    function screenshotSelection(action) {
        screenshotter.screenshotSelection(action);
    }

    function screenshotAllOutputs(action) {
        screenshotter.screenshotAllOutputs(action);
    }

    function screenshotOutput(out, action) {
        screenshotter.getMonitors(monitors => {
            if (monitors.length === 0) {
                root.sendNotification("Screenshot Failed", "No monitors found.", "critical", "dialog-error", "Screen Capture");
                return;
            }
            screenshotter.screenshotOutput(out && monitors.includes(out) ? out : monitors[0], action);
        });
    }

    function onRecordingStopped(videoPath) {
        root.generate(videoPath, root.thumbnailDir, (vp, tp) => {
            if (tp)
                root.sendNotification("Recording Stopped", "Video saved to " + vp, "normal", tp, "screenrecord");
            else
                root.sendNotification("Recording Stopped", "Video saved to " + vp, "normal", "video-x-generic", "screenrecord");
            root.gotoLink(vp, tp, false);
        });
    }

    function sendNotification(summary, body, urgency, icon, app, actions) {
        const args = ["notify-send", "-a", app || "screengrab"];
        if (urgency && urgency !== "normal")
            args.push("-u", urgency);
        if (icon)
            args.push("-i", icon);

        const hasActions = actions && actions.length > 0;
        if (hasActions) {
            args.push("--wait");
            for (let i = 0; i < actions.length; i++)
                args.push("--action=" + actions[i].id + "=" + actions[i].label);
        }
        args.push(summary, body);

        if (!hasActions) {
            Quickshell.execDetached({
                command: args
            });
            return;
        }

        // --wait keeps the client alive so action clicks come back on stdout
        const proc = actionNotifyComponent.createObject(root, {
            filePath: body,
            dirPath: body.substring(0, Math.max(body.lastIndexOf("/"), 0)) || "/"
        });
        proc.command = args;
        proc.running = true;
    }

    function gotoLink(file, thumb, showNotification) {
        if (showNotification)
            root.sendNotification("Capture Saved", file, "normal", thumb ?? "", "screengrab", [
                {
                    "id": "default",
                    "label": qsTr("Open")
                }
            ]);
        else
            Quickshell.execDetached({
                command: ["xdg-open", file]
            });
    }
}
