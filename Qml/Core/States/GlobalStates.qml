pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Vast.Translation

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

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
    property alias isSettingsOpen: panel.isSettingsOpen // qmllint disable
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

    function showOSD(name): void {
        osd.show(name);
    }
    function hideOSD(name): void {
        osd.hide(name);
        if (osd.allHidden())
            cleanupTimer.start();
    }
    function toggleOSD(name): void {
        osd.toggle(name);
    }
    function isOSDVisible(name): bool {
        return osd.isActive(name);
    }
    function pauseOSD(name): void {
        osd.pause(name);
    }
    function resumeOSD(name): void {
        osd.resume(name);
    }

    function setDynamicIslandActive(value): void {
        if (root.isDynamicIslandActive === value)
            return;
        root.isDynamicIslandActive = value;
        if (value)
            ToastService.show(qsTr("Drag and drop is active. Drop files onto the island to share them."), qsTr("Dynamic Island"), "application-vnd.oasis.opendocument.text", 5000);
    }

    function setPanel(name, value): void {
        if (name === "bar") {
            root.isBarOpen = value;
            return;
        }
        panel.setPanel(name, value);
    }
    function togglePanel(name): void {
        if (name === "bar") {
            root.setPanel(name, !root.isBarOpen);
            return;
        }
        panel.togglePanel(name);
    }
    function openPanel(name): void {
        panel.openPanel(name);
    }
    function closePanel(name): void {
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

    Connections {
        target: KeylockState

        function onCapsLockChanged() {
            root.showOSD("capslock");
        }
        function onNumLockChanged() {
            root.showOSD("numlock");
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
