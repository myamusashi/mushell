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

    property alias isVolumeOSDShow: root.isVolumeOSDVisible
    property alias isCapsLockOSDShow: root.isCapsLockOSDVisible
    property alias isNumLockOSDShow: root.isNumLockOSDVisible

    readonly property bool isVolumeOSDVisible: osd.isActive("volume")
    readonly property bool isCapsLockOSDVisible: osd.isActive("capslock")
    readonly property bool isNumLockOSDVisible: osd.isActive("numlock")

    readonly property color drawerColors: Configs.generals.transparent ? Qt.alpha(Colours.m3Colors.m3Background, Configs.generals.alpha) : Colours.m3Colors.m3Background

    readonly property string currentLanguage: TranslationManager.currentLanguage

    property alias isClipboardOpen: panel.isClipboardOpen
    property alias isSettingsOpen: panel.isSettingsOpen
    property alias isCalendarOpen: panel.isCalendarOpen
    property alias isScreenCapturePanelOpen: panel.isScreenCapturePanelOpen // qmllint disable
    property alias isLauncherOpen: panel.isLauncherOpen
    property alias isSessionOpen: panel.isSessionOpen
    property alias isMediaPlayerOpen: panel.isMediaPlayerOpen
    property alias isNotificationCenterOpen: panel.isNotificationCenterOpen
    property alias isQuickSettingsOpen: panel.isQuickSettingsOpen
    property alias isWallpaperSwitcherOpen: panel.isWallpaperSwitcherOpen
    property alias isWeatherPanelOpen: panel.isWeatherPanelOpen
    property alias isRecordingPanelOpen: panel.isRecordingPanelOpen

    property bool isBarOpen: Configs.bar.alwaysOpenBar

    property bool isDynamicIslandActive: false

    property bool isLockscreenOpen: false
    property bool isSelectionOpen: false
    property bool isScreenshotSelectionOpen: false
    property bool isWifiScannerOpen: true

    property string scriptPath: `${Paths.projectRoot}/Assets/shell/screen-capture.sh`

    OSDManager {
        id: osd
    }
    PanelManager {
        id: panel
    }

    function showOSD(name) {
        osd.show(name);
    }
    function hideOSD(name) {
        osd.hide(name);
        if (osd.allHidden())
            cleanupTimer.start();
    }
    function toggleOSD(name) {
        osd.toggle(name);
    }
    function isOSDVisible(name) {
        return osd.isActive(name);
    }
    function pauseOSD(name) {
        osd.pause(name);
    }
    function resumeOSD(name) {
        osd.resume(name);
    }

    function setDynamicIslandActive(value) {
        if (root.isDynamicIslandActive === value)
            return;
        root.isDynamicIslandActive = value;
        if (value)
            ToastService.show(qsTr("Drag and drop is active. Drop files onto the island to share them."), qsTr("Dynamic Island"), "application-vnd.oasis.opendocument.text", 5000);
    }

    function setPanel(name, value) {
        if (name === "bar") {
            root.isBarOpen = value;
            return;
        }
        panel.setPanel(name, value);
    }
    function togglePanel(name) {
        if (name === "bar") {
            root.setPanel(name, !root.isBarOpen);
            return;
        }
        panel.togglePanel(name);
    }
    function openPanel(name) {
        panel.openPanel(name);
    }
    function closePanel(name) {
        panel.closePanel(name);
    }

    Timer {
        id: cleanupTimer
        interval: 500
        repeat: false
        onTriggered: gc()
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

        // qmllint disable
        property GlobalShortcut shortcut: GlobalShortcut {
            name: panelController.shortcutName
            onPressed: root.togglePanel(panelController.panelName)
        }
        // qmllint enable
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
            }
        ]
        delegate: PanelController {
            required property var modelData
            panelName: modelData.panel
            shortcutName: modelData.shortcut
        }
    }

    // qmllint disable
    GlobalShortcut {
        name: "dynamicIsland"
        onPressed: root.setDynamicIslandActive(!root.isDynamicIslandActive)
    }
    // qmllint enable

    IpcHandler {
        target: "dynamicIsland"
        function start(): void {
            root.setDynamicIslandActive(true);
        }
        function stop(): void {
            root.setDynamicIslandActive(false);
        }
        function toggle(): void {
            root.setDynamicIslandActive(!root.isDynamicIslandActive);
        }
        function status(): bool {
            return root.isDynamicIslandActive;
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
            ScreenRecorder.isRecording ? ScreenRecorder.stopRecording() : ScreenRecorder.startRecording("", Quickshell.screens[0]?.name ?? "");
        }
        function status(): bool {
            return ScreenRecorder.isRecording;
        }
    }

    IpcHandler {
        target: "brightness"
        function get(): string {
            return JSON.stringify(BrightnessManager.displays());
        }
        function set(percent: int): void {
            BrightnessManager.setBrightnessAll(percent);
        }
    }

    IpcHandler {
        target: "audio"
        function deviceList(): string {
            const m = AudioDevicesWatcher.devices;
            const r = [];
            for (let i = 0; i < m.count(); i++) {
                const d = m.get(i);
                r.push({
                    id: d.id,
                    name: d.name,
                    description: d.description,
                    mediaClass: d.mediaClass,
                    state: d.state,
                    isMonitor: d.isMonitor,
                    monitorOf: d.monitorOf
                });
            }
            return JSON.stringify(r);
        }
        function deviceSet(name: string): void {
            Quickshell.execDetached({
                command: ["wpctl", "set-default", name]
            });
        }
        function profileList() {
            const m = AudioProfilesWatcher.profiles;
            const count = m.count();
            const r = {
                deviceId: AudioProfilesWatcher.deviceId,
                deviceName: AudioProfilesWatcher.deviceName,
                activeIndex: AudioProfilesWatcher.activeIndex,
                profiles: []
            };
            for (let i = 0; i < count; i++) {
                const p = m.get(i);
                r.profiles.push({
                    index: p.index,
                    name: p.name,
                    description: p.description,
                    available: p.available,
                    readable: p.readable
                });
            }
            return JSON.stringify(r);
        }
        function profileSet(name: string): void {
            Quickshell.execDetached({
                command: ["wpctl", "set-profile", String(AudioProfilesWatcher.deviceId), name]
            });
        }
    }

    IpcHandler {
        target: "mpris"
        function togglePlaying() {
            Players.active?.togglePlaying();
        }
        function next() {
            Players.active?.next();
        }
        function previous() {
            Players.active?.previous();
        }
        function stop() {
            Players.active?.stop();
        }
        function status() {
            return Players.active?.isPlaying;
        }
        function list(): string {
            const r = [];
            const list = Players.players;
            for (let i = 0; i < list.length; i++) {
                const p = list[i];
                r.push({
                    identity: p.identity,
                    trackTitle: p.trackTitle,
                    trackArtist: p.trackArtist,
                    playbackStatus: p.playbackStatus,
                    volume: p.volume,
                    status: p.isPlaying
                });
            }
            return JSON.stringify(r);
        }
    }

    IpcHandler {
        target: "idle"
        function on() {
            Configs.idle.enabled = true;
        }
        function off() {
            Configs.idle.enabled = false;
        }
        function status() {
            return Configs.idle.enabled;
        }
    }

    IpcHandler {
        target: "volume"
        function systemGet() {
            return JSON.stringify({
                volume: Pipewire.defaultAudioSink.audio.volume,
                muted: Pipewire.defaultAudioSink.audio.muted
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
            const r = [];
            for (const s of streams)
                r.push({
                    id: s.id,
                    name: s.name,
                    appName: s.properties["application.name"] ?? s.description ?? s.name,
                    mediaName: s.properties["media.name"] ?? "",
                    volume: s.audio.volume,
                    muted: s.audio.muted
                });
            return JSON.stringify(r);
        }
        function appSet(id: int, percent: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.volume = Math.max(0.0, Math.min(1.0, percent / 100));
        }
        function appMute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = true;
        }
        function appUnmute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = false;
        }
        function appToggleMute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = !s.audio.muted;
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

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Configs.clipboard
        function onEnabledChanged() {
            ClipboardManager.enabled = Configs.clipboard.enabled;
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
                    if (onTimeout)
                        Quickshell.execDetached({
                            command: ["sh", "-c", onTimeout]
                        });
                } else if (!isIdle && fired) {
                    fired = false;
                    if (onResume)
                        Quickshell.execDetached({
                            command: ["sh", "-c", onResume]
                        });
                }
            }
        }
    }
}
