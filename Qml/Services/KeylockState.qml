pragma Singleton

import QtQuick
import Quickshell
import Vast.Keylock

Singleton {
    readonly property bool capsLock: Keylock.capsLock
    readonly property bool numLock: Keylock.numLock
}
