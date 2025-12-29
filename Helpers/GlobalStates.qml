pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import qs.Services

Singleton {
    id: root

    readonly property int osdDisplayDuration: 2000
    readonly property int cleanupDelay: 500

    property bool isCalendarOpen: false
    property bool isScreenCapturePanelOpen: false
    property bool isLauncherOpen: false
    property bool isBarOpen: false
    property bool isSessionOpen: false
    property bool isMediaPlayerOpen: false
    property bool isNotificationCenterOpen: false
    property bool isQuickSettingsOpen: false
    property bool isWallpaperSwitcherOpen: false
    property bool isOverviewOpen: false
    property bool isRecordPanelOpen: false
	property bool isWeatherPanelOpen: false
	property bool hideOuterBorder: false

    readonly property bool isVolumeOSDVisible: _activeOSDs["volume"] || false
    readonly property bool isCapsLockOSDVisible: _activeOSDs["capslock"] || false
    readonly property bool isNumLockOSDVisible: _activeOSDs["numlock"] || false

    readonly property alias isVolumeOSDShow: root.isVolumeOSDVisible
    readonly property alias isCapsLockOSDShow: root.isCapsLockOSDVisible
    readonly property alias isNumLockOSDShow: root.isNumLockOSDVisible

    property string scriptPath: `${Quickshell.shellDir}/Assets/screen-capture.sh`

    property var _activeOSDs: ({})
    property var _osdTimers: ({})

    function showOSD(osdName) {
        if (!osdName)
            return;

        _activeOSDs[osdName] = true;
        _activeOSDsChanged();
        _startOSDTimer(osdName);
    }

    function hideOSD(osdName) {
        if (!osdName)
            return;

        _activeOSDs[osdName] = false;
        _activeOSDsChanged();
        _stopOSDTimer(osdName);
        _checkAndClosePanelWindow();
    }

    function toggleOSD(osdName) {
        if (_activeOSDs[osdName]) {
            hideOSD(osdName);
        } else {
            showOSD(osdName);
        }
    }

    function isOSDVisible(osdName) {
        return _activeOSDs[osdName] || false;
    }

    function togglePanel(panelName) {
        switch (panelName) {
        case "calendar":
            isCalendarOpen = !isCalendarOpen;
            break;
        case "screenCapture":
            isScreenCapturePanelOpen = !isScreenCapturePanelOpen;
            break;
        case "launcher":
            isLauncherOpen = !isLauncherOpen;
            break;
        case "bar":
            isBarOpen = !isBarOpen;
            break;
        case "session":
            isSessionOpen = !isSessionOpen;
            break;
        case "mediaPlayer":
            isMediaPlayerOpen = !isMediaPlayerOpen;
            break;
        case "notificationCenter":
            isNotificationCenterOpen = !isNotificationCenterOpen;
            break;
        case "quickSettings":
            isQuickSettingsOpen = !isQuickSettingsOpen;
            break;
        case "wallpaperSwitcher":
            isWallpaperSwitcherOpen = !isWallpaperSwitcherOpen;
            break;
        case "overview":
            isOverviewOpen = !isOverviewOpen;
			break;
		case "weather":
            isWeatherPanelOpen = !isWeatherPanelOpen;
            break;
        case "recordPanel":
            isRecordPanelOpen = !isRecordPanelOpen;
            break;
        }
    }

    function openPanel(panelName) {
        switch (panelName) {
        case "calendar":
            isCalendarOpen = true;
            break;
        case "screenCapture":
            isScreenCapturePanelOpen = true;
            break;
        case "launcher":
            isLauncherOpen = true;
            break;
        case "bar":
            isBarOpen = true;
            break;
        case "session":
            isSessionOpen = true;
            break;
        case "mediaPlayer":
            isMediaPlayerOpen = true;
            break;
        case "notificationCenter":
            isNotificationCenterOpen = true;
            break;
        case "quickSettings":
            isQuickSettingsOpen = true;
            break;
        case "wallpaperSwitcher":
            isWallpaperSwitcherOpen = true;
            break;
        case "overview":
            isOverviewOpen = true;
			break;
		case "weather":
            isWeatherPanelOpen = true;
            break;
        case "recordPanel":
            isRecordPanelOpen = true;
            break;
        }
    }

    function closePanel(panelName) {
        switch (panelName) {
        case "calendar":
            isCalendarOpen = false;
            break;
        case "screenCapture":
            isScreenCapturePanelOpen = false;
            break;
        case "launcher":
            isLauncherOpen = false;
            break;
        case "bar":
            isBarOpen = false;
            break;
        case "session":
            isSessionOpen = false;
            break;
        case "mediaPlayer":
            isMediaPlayerOpen = false;
            break;
        case "notificationCenter":
            isNotificationCenterOpen = false;
            break;
        case "quickSettings":
            isQuickSettingsOpen = false;
            break;
        case "wallpaperSwitcher":
            isWallpaperSwitcherOpen = false;
            break;
        case "overview":
            isOverviewOpen = false;
			break;
		case "weather":
            isWeatherPanelOpen = false;
            break;
        case "recordPanel":
            isRecordPanelOpen = false;
            break;
        }
    }

    function _startOSDTimer(osdName) {
        _stopOSDTimer(osdName);

        var timer = Qt.createQmlObject('import QtQuick; Timer {}', root, "osdTimer_" + osdName);

        timer.interval = osdDisplayDuration;
        timer.repeat = false;

        timer.triggered.connect(function () {
            hideOSD(osdName);
            timer.destroy();
            _osdTimers[osdName] = null;
        });

        _osdTimers[osdName] = timer;
        timer.start();
    }

    function _stopOSDTimer(osdName) {
        if (_osdTimers[osdName]) {
            _osdTimers[osdName].stop();
            _osdTimers[osdName].destroy();
            _osdTimers[osdName] = null;
        }
    }

    function _checkAndClosePanelWindow() {
        var anyVisible = Object.keys(_activeOSDs).some(function (key) {
            return _activeOSDs[key] === true;
        });

        if (!anyVisible) {
            cleanupTimer.start();
        }
    }

    Timer {
        id: cleanupTimer

        interval: root.cleanupDelay
        repeat: false
        onTriggered: gc()
    }

    Connections {
        target: KeyLockState.state

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

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
