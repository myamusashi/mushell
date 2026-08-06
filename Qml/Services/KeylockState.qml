pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.Keylock

import qs.Core.States

Singleton {
    readonly property bool capsLock: Keylock.capsLock
    readonly property bool numLock: Keylock.numLock

    Connections {
        target: KeylockState

        function onCapsLockChanged() {
            GlobalStates.showOSD("capslock");
        }
        function onNumLockChanged() {
            GlobalStates.showOSD("numlock");
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
}
