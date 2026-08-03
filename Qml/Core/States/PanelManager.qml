pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    readonly property var panelProps: ({
            "calendar": "isCalendarOpen",
            "screenCapture": "isScreenCapturePanelOpen",
            "launcher": "isLauncherOpen",
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
    property bool isSessionOpen: false
    property bool isMediaPlayerOpen: false
    property bool isNotificationCenterOpen: false
    property bool isQuickSettingsOpen: false
    property bool isWallpaperSwitcherOpen: false
    property bool isWeatherPanelOpen: false
    property bool isRecordingPanelOpen: false

    function setPanel(name, value) {
        const prop = panelProps[name];
        if (prop)
            root[prop] = value;
        else
            console.warn("Unknown panel:", name);
    }

    function togglePanel(name) {
        const prop = panelProps[name];
        if (prop)
            setPanel(name, !root[prop]);
    }

    function openPanel(name) {
        setPanel(name, true);
    }
    function closePanel(name) {
        setPanel(name, false);
    }
}
