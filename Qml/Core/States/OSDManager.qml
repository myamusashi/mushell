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

    signal activeChanged

    function show(name) {
        if (!name)
            return;
        activeOSDs[name] = true;
        activeChanged();
        if (!pausedOSDs[name])
            timers[name]?.restart();
    }

    function hide(name) {
        if (!name)
            return;
        activeOSDs[name] = false;
        pausedOSDs[name] = false;
        activeChanged();
        timers[name]?.stop();
    }

    function toggle(name) {
        activeOSDs[name] ? hide(name) : show(name);
    }

    function isActive(name) {
        return activeOSDs[name] || false;
    }

    function pause(name) {
        if (!name || !activeOSDs[name])
            return;
        pausedOSDs[name] = true;
        timers[name]?.stop();
    }

    function resume(name) {
        if (!name || !activeOSDs[name])
            return;
        pausedOSDs[name] = false;
        timers[name]?.restart();
    }

    function allHidden() {
        return !anyVisible;
    }

    readonly property var timers: ({
            "volume": volumeTimer,
            "capslock": capslockTimer,
            "numlock": numlockTimer
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
}
