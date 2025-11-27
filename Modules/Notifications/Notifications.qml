pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland

import qs.Configs
import qs.Services

import "Components" as Com

LazyLoader {
    activeAsync: Notifs.notifications.popupNotifications.length > 0

    component: PanelWindow {
        id: root

        anchors {
            top: true
            right: true
        }

        margins {
            right: 5
            top: 5
        }

        WlrLayershell.namespace: "shell:notification"
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: 300 * 1.5
        implicitHeight: Math.min(600, notifColumn.implicitHeight)

        Flickable {
            id: notifFlickable

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }

            width: 350
            contentHeight: notifColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: notifColumn

                width: parent.width
                spacing: Appearance.spacing.normal

                Repeater {
                    id: notifRepeater

                    model: ScriptModel {
                        values: [...Notifs.notifications.popupNotifications.map(a => a)].reverse()
                    }

                    delegate: Com.Wrapper {}
                }
            }
        }
    }
}
