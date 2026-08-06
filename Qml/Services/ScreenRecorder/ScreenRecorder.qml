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

    property string pendingVideoPath
    property string pendingOutputDir
    property var pendingCallback

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

        onNotify: (summary, body, urgency, icon, app) => {
            root.sendNotification(summary, body, urgency, icon, app);
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

                const fi = root.pendingVideoPath.split("/").pop();
                const baseName = fi.substring(0, fi.lastIndexOf("."));
                const thumb = root.pendingOutputDir + "/" + baseName + ".png";

                ffmpegProcess.seek = formatted;
                ffmpegProcess.videoPath = root.pendingVideoPath;
                ffmpegProcess.thumb = thumb;
                ffmpegProcess.running = true;
            }
        }
    }

    Process {
        id: ffmpegProcess

        property string seek
        property string videoPath
        property string thumb

        command: ["ffmpeg", "-ss", seek, "-i", videoPath, "-vframes", "1", "-q:v", "2", "-vf", "scale=256:-1", thumb, "-y", "-v", "error"]

        // qmllint disable
        onExited: (exitCode, exitStatus) => {
            // qmllint enable
            const vp = root.pendingVideoPath;
            const tp = (exitCode === 0) ? ffmpegProcess.thumb : "";
            const cb = root.pendingCallback;
            root.pendingVideoPath = "";
            root.pendingOutputDir = "";
            root.pendingCallback = null;
            root.thumbnailReady(vp, tp);
            if (cb)
                cb(vp, tp);
        }
    }

    Process {
        id: actionNotifyProcess

        property string file

        stdout: StdioCollector {
            onStreamFinished: {
                const action = text.trim();
                if (action === "default")
                    Quickshell.execDetached({
                        command: ["xdg-open", actionNotifyProcess.file]
                    });
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
        root.generate(videoPath, outputDir, (vp, tp) => {
            root.thumbnailReady(vp, tp);
        });
    }

    function generate(videoPath, outputDir, callback) {
        pendingVideoPath = videoPath;
        pendingOutputDir = outputDir;
        pendingCallback = callback;
        ffprobeProcess.videoPath = videoPath;
        ffprobeProcess.running = true;
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

    function sendNotification(summary, body, urgency, icon, app) {
        const args = ["-a", app || "screengrab"];
        if (urgency && urgency !== "normal")
            args.push("-u", urgency);
        if (icon)
            args.push("-i", icon);
        args.push(summary, body);
        Quickshell.execDetached({
            command: ["notify-send"].concat(args)
        });
    }

    function gotoLink(file, thumb, showNotification) {
        if (showNotification) {
            const args = ["notify-send", "-a", "screengrab"];
            if (thumb)
                args.push("-i", thumb);
            args.push("--action", "default=open link", "--wait", "Capture Saved", file);
            actionNotifyProcess.file = file;
            actionNotifyProcess.command = args;
            actionNotifyProcess.running = true;
        } else {
            Quickshell.execDetached({
                command: ["xdg-open", file]
            });
        }
    }
}
