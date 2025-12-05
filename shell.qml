//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur-dark
//@ pragma Env QS_NO_RELOAD_POPUP=1
import qs.Modules.Lock
import qs.Modules.Wallpaper
import qs.Modules.Launcher
import qs.Modules.RecordPanel
import qs.Modules.Overview
import qs.Modules.Polkit
import qs.Modules
import qs.Helpers

import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    Lockscreen {}
    Wall {}
    RecordPanel {}
    Polkit {}
    Screencapture {
        id: screencapture
    }
    Wrapper {}
    Overview {}

    Connections {
        target: Quickshell

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }

        function onReloadFailed() {
            Quickshell.inhibitReloadPopup();
        }
    }

    GlobalShortcut {
        name: "screencapture"
        onPressed: GlobalStates.isScreenCapturePanelOpen = !GlobalStates.isScreenCapturePanelOpen
    }
}
