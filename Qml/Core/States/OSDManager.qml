pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    implicitWidth: 0
    implicitHeight: 0

    property var activeOSDs: ({})
    property var pausedOSDs: ({})
    readonly property bool anyVisible: Object.keys(activeOSDs).some(k => activeOSDs[k] === true)
    readonly property int displayDuration: 5000

    function show(name): void {
        if (!name)
            return;
        activeOSDs[name] = true;
        activeOSDsChanged();
        if (!pausedOSDs[name])
            timers[name]?.restart();
    }

    function hide(name): void {
        if (!name)
            return;
        activeOSDs[name] = false;
        pausedOSDs[name] = false;
        activeOSDsChanged();
        timers[name]?.stop();
    }

    function toggle(name): void {
        activeOSDs[name] ? hide(name) : show(name);
    }

    function isActive(name): bool {
        return activeOSDs[name] || false;
    }

    function pause(name): void {
        if (!name || !activeOSDs[name])
            return;
        pausedOSDs[name] = true;
        timers[name]?.stop();
    }

    function resume(name): void {
        if (!name || !activeOSDs[name])
            return;
        pausedOSDs[name] = false;
        timers[name]?.restart();
    }

    function allHidden(): bool {
        return !anyVisible;
    }

    readonly property var timers: ({
            "volume": volumeTimer,
            "capslock": capslockTimer,
            "numlock": numlockTimer,
            "brightness": brightnessTimer
        })

    Timer {
        id: volumeTimer
        interval: root.displayDuration
        repeat: false
        onTriggered: root.hide("volume")
    }

    Timer {
        id: capslockTimer
        interval: root.displayDuration
        repeat: false
        onTriggered: root.hide("capslock")
    }

    Timer {
        id: numlockTimer
        interval: root.displayDuration
        repeat: false
        onTriggered: root.hide("numlock")
    }

    Timer {
        id: brightnessTimer
        interval: root.displayDuration
        repeat: false
        onTriggered: root.hide("brightness")
    }
}
