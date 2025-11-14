//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur-dark
//@ pragma Env QS_NO_RELOAD_POPUP=1
import qs.Modules.Lock
import qs.Modules.Bar
import qs.Modules.Wallpaper
import qs.Modules.Session
import qs.Modules.Launcher
import qs.Modules.Notifications
// import qs.Modules.BigClock
import qs.Modules.OSD
import qs.Modules.Overview
import qs.Modules.Polkit

import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    Bar {
        id: bar
    }
    Lockscreen {}
    Wall {}
    WallpaperSelector {
        id: ws
    }
    Session {
        id: session
    }
    Polkit {}
    App {
        id: appLauncher
    }
    Screencapture {
        id: screencapture
    }
    Notifications {}
    // Clock {}
    OSD {}
    Overview {}

    Connections {
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup()
        }

        function onReloadFailed() {
            Quickshell.inhibitReloadPopup()
        }

        target: Quickshell
    }

    GlobalShortcut {
        name: "bar"
        onPressed: bar.isBarOpen = !bar.isBarOpen
    }

    GlobalShortcut {
        name: "wallpaperSelector"
        onPressed: ws.isWallpaperSwitcherOpen = !ws.isWallpaperSwitcherOpen
    }

    GlobalShortcut {
        name: "session"
        onPressed: session.isSessionOpen = !session.isSessionOpen
    }

    GlobalShortcut {
        name: "appLauncher"
        onPressed: appLauncher.isLauncherOpen = !appLauncher.isLauncherOpen
    }

    GlobalShortcut {
        name: "screencapture"
        onPressed: screencapture.isScreencaptureOpen = !screencapture.isScreencaptureOpen
    }
}
