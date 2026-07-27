pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Vast

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services.ScreenRecorder

Singleton {
    id: root

    readonly property alias isVolumeOSDShow: root.isVolumeOSDVisible
    readonly property alias isCapsLockOSDShow: root.isCapsLockOSDVisible
    readonly property alias isNumLockOSDShow: root.isNumLockOSDVisible

    readonly property bool isVolumeOSDVisible: activeOSDs["volume"] || false
    readonly property bool isCapsLockOSDVisible: activeOSDs["capslock"] || false
    readonly property bool isNumLockOSDVisible: activeOSDs["numlock"] || false

    readonly property color drawerColors: Configs.generals.transparent ? Qt.alpha(Colours.m3Colors.m3Background, Configs.generals.alpha) : Colours.m3Colors.m3Background
    readonly property int osdDisplayDuration: 5000
    readonly property int cleanupDelay: 500
    readonly property string currentLanguage: TranslationManager.currentLanguage

    readonly property var osdTimers: ({
            "volume": volumeTimer,
            "capslock": capslockTimer,
            "numlock": numlockTimer
        })

    readonly property var panelProps: ({
            "calendar": "isCalendarOpen",
            "screenCapture": "isScreenCapturePanelOpen",
            "launcher": "isLauncherOpen",
            "bar": "isBarOpen",
            "session": "isSessionOpen",
            "mediaPlayer": "isMediaPlayerOpen",
            "notificationCenter": "isNotificationCenterOpen",
            "quickSettings": "isQuickSettingsOpen",
            "wallpaperSwitcher": "isWallpaperSwitcherOpen",
            "weather": "isWeatherPanelOpen",
            "settings": "isSettingsOpen",
            "clipboard": "isClipboardOpen",
            "recordingPanel": "isRecordingPanelOpen"
        })

    property bool isClipboardOpen: false
    property bool isSettingsOpen: false
    property bool isCalendarOpen: false
    property bool isScreenCapturePanelOpen: false
    property bool isLauncherOpen: false
    property bool isBarOpen: Configs.bar.alwaysOpenBar
    property bool isSessionOpen: false
    property bool isMediaPlayerOpen: false
    property bool isNotificationCenterOpen: false
    property bool isQuickSettingsOpen: false
    property bool isWallpaperSwitcherOpen: false
    property bool isWeatherPanelOpen: false
    property bool isLockscreenOpen: false
    property bool isSelectionOpen: false
    property bool isScreenshotSelectionOpen: false
    property bool isRecordingPanelOpen: false

    property bool isWifiScannerOpen: true

    property string scriptPath: `${Paths.projectRoot}/Assets/shell/screen-capture.sh`

    property var activeOSDs: ({})
    property var pausedOSDs: ({})

    function setPanel(name: string, value: bool): void {
        const prop = panelProps[name];
        if (prop)
            root[prop] = value;
        else
            console.warn("Unknown panel:", name);
    }

    function togglePanel(name: string): void {
        const prop = panelProps[name];
        if (prop)
            setPanel(name, !root[prop]);
    }

    function openPanel(name: string): void {
        setPanel(name, true);
    }
    function closePanel(name: string): void {
        setPanel(name, false);
    }

    function showOSD(osdName) {
        if (!osdName)
            return;
        activeOSDs[osdName] = true;
        activeOSDsChanged();
        if (!pausedOSDs[osdName])
            startOSDTimer(osdName);
    }

    function hideOSD(osdName) {
        if (!osdName)
            return;
        activeOSDs[osdName] = false;
        pausedOSDs[osdName] = false;
        activeOSDsChanged();
        stopOSDTimer(osdName);
        checkAndClosePanelWindow();
    }

    function toggleOSD(osdName) {
        activeOSDs[osdName] ? hideOSD(osdName) : showOSD(osdName);
    }

    function isOSDVisible(osdName) {
        return activeOSDs[osdName] || false;
    }

    function pauseOSD(osdName) {
        if (!osdName || !activeOSDs[osdName])
            return;
        pausedOSDs[osdName] = true;
        stopOSDTimer(osdName);
    }

    function resumeOSD(osdName) {
        if (!osdName || !activeOSDs[osdName])
            return;
        pausedOSDs[osdName] = false;
        startOSDTimer(osdName);
    }

    component OSDTimer: Timer {
        required property string osdName
        interval: root.osdDisplayDuration
        repeat: false
        onTriggered: root.hideOSD(osdName)
    }

    function startOSDTimer(osdName: string): void {
        osdTimers[osdName]?.restart();
    }

    function stopOSDTimer(osdName: string): void {
        osdTimers[osdName]?.stop();
    }

    function checkAndClosePanelWindow() {
        const anyVisible = Object.keys(activeOSDs).some(key => activeOSDs[key] === true);
        if (!anyVisible)
            cleanupTimer.start();
    }

    OSDTimer {
        id: volumeTimer

        osdName: "volume"
    }
    OSDTimer {
        id: capslockTimer

        osdName: "capslock"
    }
    OSDTimer {
        id: numlockTimer

        osdName: "numlock"
    }

    component PanelController: QtObject {
        id: panelController

        required property string panelName
        required property string shortcutName

        property IpcHandler ipc: IpcHandler {
            target: panelController.panelName

            function open(): void {
                root.openPanel(panelController.panelName);
            }
            function close(): void {
                root.closePanel(panelController.panelName);
            }
            function toggle(): void {
                root.togglePanel(panelController.panelName);
            }
        }

        property GlobalShortcut shortcut: GlobalShortcut {
            name: panelController.shortcutName
            onPressed: root.togglePanel(panelController.panelName)
        }
    }

    Variants {
        model: [
            {
                panel: "wallpaperSwitcher",
                shortcut: "wallpaperSwitcher"
            },
            {
                panel: "bar",
                shortcut: "bar"
            },
            {
                panel: "launcher",
                shortcut: "launcher"
            },
            {
                panel: "screenCapture",
                shortcut: "screenCapture"
            },
            {
                panel: "quickSettings",
                shortcut: "quickSettings"
            },
            {
                panel: "session",
                shortcut: "session"
            },
            {
                panel: "weather",
                shortcut: "weather"
            },
            {
                panel: "settings",
                shortcut: "settings"
            },
            {
                panel: "clipboard",
                shortcut: "clipboard"
            },
            {
                panel: "recordingPanel",
                shortcut: "recordingPanel"
            },
        ]
        delegate: PanelController {
            required property var modelData
            panelName: modelData.panel
            shortcutName: modelData.shortcut
        }
    }

    IpcHandler {
        target: "toast"

        function open(header: string, description: string, icon: string, duration: int): void {
            ToastService.show(description, header, icon, duration);
        }
    }

    IpcHandler {
        target: "img"

        function set(path: string): void {
            ImageCache.preload(path, Qt.size(Screen.width, Screen.height));

            Quickshell.execDetached({
                command: ["sh", "-c", `printf '%s' ${JSON.stringify(path)} > ${JSON.stringify(Paths.currentWallpaperFile)}`]
            });
            Quickshell.execDetached({
                command: ["matugen", "image", path, "--source-color-index", "2"]
            });
        }
        function get(): string {
            return Paths.currentWallpaper;
        }
    }

    IpcHandler {
        target: "capture"

        function screen(action: string): void {
            ScreenRecorder.screenshotOutput(Quickshell.screens[0]?.name ?? "", action);
        }
        function region(action: string): void {
            ScreenRecorder.screenshotSelection(action);
        }
        function window(action: string): void {
            ScreenRecorder.screenshotWindow(action);
        }
    }

    IpcHandler {
        target: "recorder"

        function start(): void {
            ScreenRecorder.startRecording("", Quickshell.screens[0]?.name ?? "");
        }
        function stop(): void {
            ScreenRecorder.stopRecording();
        }
        function toggle(): void {
            if (ScreenRecorder.isRecording)
                ScreenRecorder.stopRecording();
            else
                ScreenRecorder.startRecording("", Quickshell.screens[0]?.name ?? "");
        }
        function status(): bool {
            return ScreenRecorder.isRecording;
        }
    }

    IpcHandler {
        target: "brightness"

        function get(): string {
            const list = BrightnessManager.displays();
            return JSON.stringify(list);
        }
        function set(percent: int): void {
            BrightnessManager.setBrightnessAll(percent);
        }
    }

    IpcHandler {
        target: "audio"

        function deviceList(): string {
            const model = AudioDevicesWatcher.devices;
            const count = model.count();
            const result = [];
            for (let i = 0; i < count; i++) {
                const d = model.get(i);
                result.push({
                    id: d.id,
                    name: d.name,
                    description: d.description,
                    mediaClass: d.mediaClass,
                    state: d.state,
                    isMonitor: d.isMonitor,
                    monitorOf: d.monitorOf
                });
            }
            return JSON.stringify(result);
        }

        function deviceSet(name: string): void {
            Quickshell.execDetached({
                command: ["wpctl", "set-default", name]
            });
        }

        function profileList(): string {
            const model = AudioProfilesWatcher.profiles;
            const count = model.count();
            const result = {
                deviceId: AudioProfilesWatcher.deviceId,
                deviceName: AudioProfilesWatcher.deviceName,
                activeIndex: AudioProfilesWatcher.activeIndex,
                profiles: []
            };
            for (let i = 0; i < count; i++) {
                const p = model.get(i);
                result.profiles.push({
                    index: p.index,
                    name: p.name,
                    description: p.description,
                    available: p.available,
                    readable: p.readable
                });
            }
            return JSON.stringify(result);
        }

        function profileSet(name: string): void {
            Quickshell.execDetached({
                command: ["wpctl", "set-profile", String(AudioProfilesWatcher.deviceId), name]
            });
        }
    }

    IpcHandler {
        target: "mpris"

        function togglePlaying(): void {
            Players.active?.togglePlaying();
        }
        function next(): void {
            Players.active?.next();
        }
        function previous(): void {
            Players.active?.previous();
        }
        function stop(): void {
            Players.active?.stop();
        }
        function status(): bool {
            return Players.active?.isPlaying;
        }
        function list(): string {
            const result = [];
            const list = Players.players;
            for (let i = 0; i < list.length; i++) {
                const p = list[i];
                result.push({
                    identity: p.identity,
                    trackTitle: p.trackTitle,
                    trackArtist: p.trackArtist,
                    playbackStatus: p.playbackStatus,
                    volume: p.volume,
                    status: p.isPlaying
                });
            }
            return JSON.stringify(result);
        }
    }

    IpcHandler {
        target: "idle"

        function on(): void {
            Configs.idle.enabled = true;
        }
        function off(): void {
            Configs.idle.enabled = false;
        }
        function status(): bool {
            return Configs.idle.enabled;
        }
    }

    IpcHandler {
        target: "volume"

        function systemGet(): string {
            const sink = Pipewire.defaultAudioSink;
            return JSON.stringify({
                volume: sink.audio.volume,
                muted: sink.audio.muted
            });
        }
        function systemSet(percent: int): void {
            Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Math.min(1.0, percent / 100));
        }
        function systemMute(): void {
            Pipewire.defaultAudioSink.audio.muted = true;
        }
        function systemUnmute(): void {
            Pipewire.defaultAudioSink.audio.muted = false;
        }
        function systemToggleMute(): void {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
        function appList(): string {
            const streams = Pipewire.nodes.values.filter(n => n.isStream);
            const result = [];
            for (const s of streams) {
                result.push({
                    id: s.id,
                    name: s.name,
                    appName: s.properties["application.name"] ?? s.description ?? s.name,
                    mediaName: s.properties["media.name"] ?? "",
                    volume: s.audio.volume,
                    muted: s.audio.muted
                });
            }
            return JSON.stringify(result);
        }
        function appSet(id: int, percent: int): void {
            const streams = Pipewire.nodes.values.filter(n => n.isStream);
            for (const s of streams) {
                if (s.id === id) {
                    s.audio.volume = Math.max(0.0, Math.min(1.0, percent / 100));
                    break;
                }
            }
        }
        function appMute(id: int): void {
            const streams = Pipewire.nodes.values.filter(n => n.isStream);
            for (const s of streams) {
                if (s.id === id) {
                    s.audio.muted = true;
                    break;
                }
            }
        }
        function appUnmute(id: int): void {
            const streams = Pipewire.nodes.values.filter(n => n.isStream);
            for (const s of streams) {
                if (s.id === id) {
                    s.audio.muted = false;
                    break;
                }
            }
        }
        function appToggleMute(id: int): void {
            const streams = Pipewire.nodes.values.filter(n => n.isStream);
            for (const s of streams) {
                if (s.id === id) {
                    s.audio.muted = !s.audio.muted;
                    break;
                }
            }
        }
    }

    IpcHandler {
        target: "keylock"

        function capslock(): bool {
            return KeylockState.capsLock;
        }
        function numlock(): bool {
            return KeylockState.numLock;
        }
    }

    Timer {
        id: cleanupTimer

        interval: root.cleanupDelay
        repeat: false
        onTriggered: gc()
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Configs.clipboard

        function onEnabledChanged() {
            if (Configs.clipboard.enabled)
                ClipboardManager.enabled = true;
            else
                ClipboardManager.enabled = false;
        }
    }

    Connections {
        target: KeylockState

        function onCapsLockChanged() {
            root.showOSD("capslock");
        }
        function onNumLockChanged() {
            root.showOSD("numlock");
        }
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio

        function onVolumeChanged() {
            root.showOSD("volume");
        }
    }

    Instantiator {
        model: Configs.idle.timeouts
        delegate: IdleMonitor {
            required property var modelData
            readonly property int timeoutMonitor: modelData.timeoutMonitor ?? 60
            readonly property string onTimeout: modelData["on-timeout"] ?? ""
            readonly property string onResume: modelData["on-resume"] ?? ""
            property bool fired: false

            enabled: Configs.idle.enabled
            respectInhibitors: true
            timeout: timeoutMonitor

            onIsIdleChanged: {
                if (isIdle && !fired) {
                    fired = true;
                    if (onTimeout) {
                        Quickshell.execDetached({
                            command: ["sh", "-c", onTimeout]
                        });
                    }
                } else if (!isIdle && fired) {
                    fired = false;
                    if (onResume) {
                        Quickshell.execDetached({
                            command: ["sh", "-c", onResume]
                        });
                    }
                }
            }
        }
    }
}
