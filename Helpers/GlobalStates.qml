pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import qs.Services

Singleton {
    id: root

    property bool isCalendarOpen: false
    property bool isScreenCapturePanelOpen: false
    property bool isLauncherOpen: false
    property bool isBarOpen: false
    property bool isSessionOpen: false
    property bool isMediaPlayerOpen: false
    property bool isNotificationCenterOpen: false
    property bool isQuickSettingsOpen: false
    property bool isWallpaperSwitcherOpen: false
    property bool isVolumeOSDShow: false
    property bool isCapsLockOSDShow: false
    property bool isNumLockOSDShow: false
	property bool isOverviewOpen: false
	property bool isRecordPanelOpen: false

    property string scriptPath: `${Quickshell.shellDir}/Assets/screen-capture.sh`

    property var osdTimers: ({
                                 "capslock": null,
                                 "numlock": null,
                                 "volume": null
                             })

    function startOSDTimer(osdName) {
        var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 2000; repeat: false; }', root, "dynamicTimer");

        timer.triggered.connect(function () {
            closeOSD(osdName);
            timer.destroy();
            osdTimers[osdName] = null;

            checkAndClosePanelWindow();
        });

        if (osdTimers[osdName]) {
            osdTimers[osdName].stop();
            osdTimers[osdName].destroy();
        }

        osdTimers[osdName] = timer;
        timer.start();
    }

    function closeOSD(osdName) {
        if (osdName === "capslock")
            isCapsLockOSDShow = false;
        else if (osdName === "numlock")
            isNumLockOSDShow = false;
        else if (osdName === "volume")
            isVolumeOSDShow = false;
    }

    function checkAndClosePanelWindow() {
        if (!isVolumeOSDShow && !isCapsLockOSDShow && !isNumLockOSDShow)
            cleanup.start();
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: gc()
    }

    Connections {
        target: KeyLockState.state

        function onCapsLockChanged() {
            root.isCapsLockOSDShow = true;
            root.startOSDTimer("capslock");
        }
        function onNumLockChanged() {
            root.isNumLockOSDShow = true;
            root.startOSDTimer("numlock");
        }
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio

        function onVolumeChanged() {
            root.isVolumeOSDShow = true;
            root.startOSDTimer("volume");
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
