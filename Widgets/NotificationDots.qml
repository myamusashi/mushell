import QtQuick

import qs.Configs
import qs.Helpers
import qs.Components
import qs.Services
import qs.Modules.Notifications

StyledRect {
    implicitWidth: root.width
    implicitHeight: parent.height
    color: mArea.containsPress ? Themes.withAlpha(Themes.m3Colors.onSurface, 0.08) : mArea.containsMouse ? Themes.withAlpha(Themes.m3Colors.onSurface, 0.16) : "transparent"

    Dots {
        id: root

        property int notificationCount: Notifs.notifications.listNotifications.length || 0
        property bool isDndEnable: Notifs.notifications.disabledDnD

        implicitWidth: 50
        implicitHeight: parent.height - 5

        MaterialIcon {
            color: {
                if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
                    Themes.m3Colors.primary;
                else if (root.isDndEnable)
                    Themes.m3Colors.onSurface;
                else
                    Themes.m3Colors.onSurface;
            }
            font.pointSize: Appearance.fonts.large
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: notificationCenter.isNotificationCenterOpen = !notificationCenter.isNotificationCenterOpen
    }

    NotificationCenter {
        id: notificationCenter
    }
}
