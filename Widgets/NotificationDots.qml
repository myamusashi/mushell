import QtQuick

import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: dots

    implicitWidth: root.width
    implicitHeight: parent.height

    Dots {
        id: root

        property int notificationCount: Notifs.notClosed.length
        property bool isDndEnable: Notifs.dnd

        implicitWidth: 10
        implicitHeight: parent.height

        MaterialIcon {
            color: {
                if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
                    Colours.m3Colors.m3Primary;
                else if (root.isDndEnable)
                    Colours.m3Colors.m3OnSurface;
                else
                    Colours.m3Colors.m3OnSurface;
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
        onClicked: GlobalStates.isNotificationCenterOpen = !GlobalStates.isNotificationCenterOpen
    }
}
