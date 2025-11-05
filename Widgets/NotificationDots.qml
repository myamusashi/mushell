import QtQuick

import qs.Data
import qs.Helpers
import qs.Components

StyledRect {
	implicitWidth: root.width
	implicitHeight: parent.height
	color: mArea.containsPress ? Colors.withAlpha(Colors.colors.on_surface, 0.08) : mArea.containsMouse ? Colors.withAlpha(Colors.colors.on_surface, 0.16) : "transparent"

	Dots {
		id: root

		property int notificationCount: Notifs.notifications.listNotifications.length || 0
		property bool isDndEnable: Notifs.notifications.disabledDnD

		implicitWidth: 50
		implicitHeight: parent.height - 5

		MatIcon {
			color: {
				if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
					Colors.colors.primary;
				else if (root.isDndEnable)
					Colors.colors.on_surface;
				else
					Colors.colors.on_surface;
			}
			font.pixelSize: Appearance.fonts.large * 1.3
			anchors.horizontalCenter: parent.horizontalCenter
			icon: {
				if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
					"notifications_unread";
				else if (root.isDndEnable)
					"notifications_off";
				else
					"notifications";
			}

			MouseArea {
				id: mArea

				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: notificationCenter.isNotificationCenterOpen = !notificationCenter.isNotificationCenterOpen
			}
		}
	}

	NotificationCenter {
		id: notificationCenter
	}
}
