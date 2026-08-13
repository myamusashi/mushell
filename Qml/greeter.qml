//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma DropExpensiveFonts
//@ pragma Env QSG_RHI_BACKEND=vulkan

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import "Greeter" as GREET

ShellRoot {
    GREET.BackdropPanel {
        id: backdrop
    }

    GREET.MainPanel {
        id: mainPanel

        auth: authenticator
        launching: rootFlow.launching

        onEntranceFinished: if (!rootFlow.launching) lock.locked = true
        onLogoutRequested: {
            lock.locked = false;
            Qt.quit();
        }
    }

    WlSessionLock {
        id: lock
        locked: false

        GREET.Surface {
            id: surface

            lock: lock
            auth: authenticator

            onSuccessSequenceFinished: rootFlow.launchSession()
            onLogoutRequested: {
                lock.locked = false;
                Qt.quit();
            }
        }
    }

    GREET.Auth {
        id: authenticator
    }

    QtObject {
        id: rootFlow

        property bool launching: false

        function onAuthenticated() {
            if (lock.locked)
                surface.playSuccessSequence();
            else
                rootFlow.launchSession();
        }

        function launchSession() {
            if (rootFlow.launching)
                return;

            rootFlow.launching = true;
            lock.locked = false;
            launchTimer.start();
        }
    }

    Connections {
        target: authenticator

        function onAuthenticated() {
            rootFlow.onAuthenticated();
        }
    }

    Timer {
        id: launchTimer

        interval: 2000
        repeat: false

        onTriggered: authenticator.launch()
    }
}
