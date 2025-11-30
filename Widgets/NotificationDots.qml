import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Components
import qs.Services
import qs.Modules.Notifications

Item {
	id: dots

    implicitWidth: root.width
    implicitHeight: parent.height

    Dots {
        id: root

        property int notificationCount: Notifs.notifications.listNotifications.length || 0
        property bool isDndEnable: Notifs.disabledDnD

        implicitWidth: 10
        implicitHeight: parent.height

		MaterialIcon {
            color: {
                if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
                    Themes.m3Colors.m3Primary;
                else if (root.isDndEnable)
                    Themes.m3Colors.m3OnSurface;
                else
                    Themes.m3Colors.m3OnSurface;
            }
            font.pointSize: Appearance.fonts.large
            icon: {
                if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
                    "notifications_unread";
                else if (root.isDndEnable)
                    "notifications_off";
                else
                    "notifications";
            }
        }
    }
    MArea {
        id: mArea

		anchors.fill: parent
		layerColor: "transparent"
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: notificationCenter.isNotificationCenterOpen = !notificationCenter.isNotificationCenterOpen
    }

    NotificationCenter {
		id: notificationCenter
	}
}
