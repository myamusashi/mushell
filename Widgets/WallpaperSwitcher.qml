import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
	id: scope

	property bool isWallpaperSwitcherOpen: false

	LazyLoader {
		property bool wsOpen: false

		active: wsOpen

		component: PanelWindow {
			id: root

			anchors {
				right: true
				top: true
				bottom: true
			}
		}
	}
}
