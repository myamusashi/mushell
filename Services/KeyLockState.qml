pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Helpers

Singleton {
    id: root

    readonly property KeyStateComponent state: KeyStateComponent {}
    readonly property var keystate: JSON.parse(keyStateFile.text().trim())

    Process {
        id: lockStateProcess

        running: true
        command: [Paths.rootDir + "/Assets/keystate-bin"]
    }

    FileView {
        id: keyStateFile

        path: "/tmp/keystate.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
    }

    component KeyStateComponent: QtObject {
        readonly property bool numLock: root.keystate.numLock
        readonly property bool capsLock: root.keystate.capsLock
    }
}
