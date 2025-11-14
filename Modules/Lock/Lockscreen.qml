pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    property alias lock: lock

    WlSessionLock {
        id: lock

        signal unlock

        Surface {
            id: surface

            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lock.locked = true
        }

        function unlock(): void {
            lock.unlock()
        }

        function isLocked(): bool {
            return lock.locked
        }
    }
}
