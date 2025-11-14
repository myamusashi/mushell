pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import qs.Data

Scope {
    id: root

    property bool isVolumeOSDShow: false
    property bool isCapsLockOSDShow: false
    property bool isNumLockOSDShow: false

    Connections {
        target: KeyLockState.state
        function onCapsLockChanged() {
            root.isCapsLockOSDShow = true
            hideOSDTimer.restart()
        }
        function onNumLockChanged() {
            root.isNumLockOSDShow = true
            hideOSDTimer.restart()
        }
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio
        function onVolumeChanged() {
            root.isVolumeOSDShow = true
            hideOSDTimer.restart()
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Timer {
        id: hideOSDTimer

        interval: 2000
        onTriggered: {
            root.isVolumeOSDShow = false
            root.isCapsLockOSDShow = false
            root.isNumLockOSDShow = false
        }
    }

    Volumes {
        active: root.isVolumeOSDShow
        node: Pipewire.defaultAudioSink
    }

    CapsLockWidget {
        active: root.isCapsLockOSDShow
    }

    NumLockWidget {
        active: root.isNumLockOSDShow
    }
}
