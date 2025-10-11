pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.Data
import qs.Components
import qs.Helpers

Loader {
	active: root.isBarOpen

	sourceComponent: RowLayout {
		id: root

		property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

		Rectangle {
			id: workspaceBar

			Layout.preferredWidth: Math.max(50, Workspaces.maxWorkspace * 25)
			implicitHeight: 25
			// border.color: Appearance.colors.on_background
			// radius: Appearance.rounding.small
			// color: Appearance.colors.background
			color: "transparent"

			Row {
				anchors.centerIn: parent
				spacing: 15

				Repeater {
					model: Workspaces.maxWorkspace || 1

					Item {
						id: wsItem

						required property int index
						property bool focused: Hyprland.focusedMonitor?.activeWorkspace?.id === (index + 1)

						width: workspaceText.width
						height: workspaceText.height

						StyledText {
							id: workspaceText
							text: (wsItem.index + 1).toString()
							color: {
								if (workspaceMArea.containsMouse)
									return Appearance.colors.withAlpha(Appearance.colors.primary, 0.5);

								if (wsItem.focused)
									return Appearance.colors.primary;
								else
									return Appearance.colors.on_background;
							}
							font.pixelSize: Appearance.fonts.medium * 1.3
							font.bold: wsItem.focused
						}

						MouseArea {
							id: workspaceMArea

							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: Workspaces.switchWorkspace(wsItem.index + 1)
						}
					}
				}
			}
		}
	}
}
