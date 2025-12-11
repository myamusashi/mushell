//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur-dark
//@ pragma Env QS_NO_RELOAD_POPUP=1

import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.Helpers
import qs.Modules
import qs.Modules.Launcher
import qs.Modules.Lock
import qs.Modules.Overview
import qs.Modules.Polkit
import qs.Modules.RecordPanel
import qs.Modules.Wallpaper

ShellRoot {
	id: root

	property alias wrapper: wrapper
    Lockscreen {}
    Wall {}
    RecordPanel {}
    Polkit {}
    Screencapture {
        id: screencapture
    }
	Wrapper {
		id: wrapper
	}
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
