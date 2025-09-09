//@ pragma UseQApplication
import qs.Modules.Lock
import qs.Modules.Bar
import qs.Modules.Wallpaper
import qs.Modules.Session
import qs.Modules.Launcher
import qs.Modules.Notifications
import qs.Modules.Dashboard

import QtQuick
import Quickshell

ShellRoot {
	Bar {}
	Lockscreen {}
	Wall {}
	Session {}
	App {}
	Screencapture {}
	Notifications {}
	Dashboard {}

	Connections {
		function onReloadCompleted() {
			Quickshell.inhibitReloadPopup();
		}

		function onReloadFailed() {
			Quickshell.inhibitReloadPopup();
		}

		target: Quickshell
	}
}
