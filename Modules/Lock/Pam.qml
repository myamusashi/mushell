pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root

    required property WlSessionLock lock

    property string currentText: ""
    property bool showFailure: false
    property bool unlockInProgress: false
    property bool unlocking: false

    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "")
            return

        unlockInProgress = true
        pam.start()
    }

    PamContext {
        id: pam

        config: "password.conf"
        configDirectory: "root:/Assets/pam.d"

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText)
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.lock.unlock()
            } else {
                root.currentText = ""
                root.showFailure = true
            }

            root.unlockInProgress = false
        }
    }
}
