pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

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

        property int monitorWidth: Hypr.focusedMonitor.width * 0.2
        property int monitorHeight: Hypr.focusedMonitor.height / 2

        WlrLayershell.namespace: "shell:notification"
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: monitorWidth
        implicitHeight: monitorHeight

        Flickable {
            id: notifFlickable

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }

            width: parent.width
            contentHeight: parent.height
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

                    delegate: Com.Wrapper {
                        id: wrapper

						onEntered: closePopups.stop()
						onExited: closePopups.start()

                        Timer {
                            id: closePopups

                            interval: wrapper.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000
                            running: true
                            onTriggered: {
                                Notifs.notifications.removePopupNotification(wrapper.modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
