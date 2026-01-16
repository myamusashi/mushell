import QtQuick

import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: dots

    Dots {
        id: root

        property int notificationCount: Notifs.notClosed.length
        property bool isDndEnable: Notifs.dnd

        width: 30
        height: parent.height

        Icon {
            type: Icon.Material
            color: {
                if (root.notificationCount > 0 && root.notificationCount !== null && root.isDndEnable !== true)
                    Colours.m3Colors.m3Primary;
                else if (root.isDndEnable)
                    Colours.m3Colors.m3OnSurface;
                else
                    Colours.m3Colors.m3OnSurface;
            }
            font.pixelSize: Appearance.fonts.size.large * 1.2
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
