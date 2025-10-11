import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	active: dashboardLoader.activeAsync
	asynchronous: true

	anchors.fill: parent

	sourceComponent: Rectangle {
	Layout.fillWidth: true
	Layout.preferredHeight: 60
	color: Appearance.colors.background
	radius: Appearance.rounding.normal
	border.color: Appearance.colors.outline
	border.width: 2

	RowLayout {
		anchors.fill: parent
		anchors.margins: 16

		StyledText {
			Layout.fillWidth: true
			text: "Notifications"
			color: Appearance.colors.on_background
			font.pixelSize: Appearance.fonts.large * 1.2
			font.weight: Font.Medium
		}

		Repeater {
			model: [
				{
					icon: "clear_all",
					action: () => {
						Notifs.notifications.dismissAll();
					}
				},
				{
					icon: Notifs.notifications.disabledDnD ? "notifications_off" : "notifications_active",
					action: () => {
						Notifs.notifications.disabledDnD = !Notifs.notifications.disabledDnD;
					}
				}
			]

			delegate: Rectangle {
				id: notifHeaderDelegate

				Layout.preferredWidth: 32
				Layout.preferredHeight: 32
				radius: 6
				color: iconMouse.containsMouse ? Appearance.colors.surface_container_high : "transparent"

				required property var modelData

				MatIcon {
					anchors.centerIn: parent
					icon: notifHeaderDelegate.modelData.icon
					font.pixelSize: Appearance.fonts.large * 1.6
					color: Appearance.colors.on_background
				}

				MouseArea {
					id: iconMouse

					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					hoverEnabled: true
					onClicked: notifHeaderDelegate.modelData.action()
				}
			}
		}
	}
}
}
