//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur-dark
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell

import qs.Modules
import qs.Modules.Lock
import qs.Modules.Polkit
import qs.Modules.RecordPanel
import qs.Modules.Wallpaper

ShellRoot {
    id: root

    Lockscreen {}
    Wall {}
    RecordPanel {}
    Polkit {}
    Wrapper {
        id: wrapper
    }

    Connections {
        target: Quickshell

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }

        function onReloadFailed() {
            Quickshell.inhibitReloadPopup();
        }
    }
}
