pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Notifications

import qs.Configs
import qs.Services
import qs.Components

import "Components" as Com

OuterShapeItem {
    content: item

    Item {
        id: item

        anchors {
            right: parent.right
            top: parent.top
            topMargin: 0
        }
        width: Hypr.focusedMonitor.width * 0.2
        height: Notifs.notifications.popupNotifications.length > 0 ? Math.min(notifColumn.height + 30, parent.height * 0.4) : 0

        Behavior on height {
            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            }
        }

        Shape {
            id: maskShape

            anchors.fill: parent

            ShapePath {
                fillColor: Themes.m3Colors.m3Background
                strokeColor: "transparent"

                startX: 0
                startY: 0

                PathLine {
                    x: maskShape.width
                    y: 0
                }

                PathLine {
                    x: maskShape.width
                    y: maskShape.height
                }

                PathLine {
                    x: Appearance.rounding.normal
                    y: maskShape.height
                }

                PathArc {
                    x: 0
                    y: maskShape.height - Appearance.rounding.normal
                    radiusX: Appearance.rounding.normal
                    radiusY: Appearance.rounding.normal
                }

                PathLine {
                    x: 0
                    y: Appearance.rounding.normal
                }
            }
        }

        Flickable {
            id: notifFlickable

            anchors.fill: parent
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

                    delegate: Com.Wrapper {
                        id: wrapper

                        onEntered: closePopups.stop()
                        onExited: closePopups.start()

                        Timer {
                            id: closePopups

                            interval: wrapper.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000
                            running: true
                            onTriggered: wrapper.removeNotificationWithAnimation()
                        }

                        Timer {
                            id: removeTimer

                            interval: Appearance.animations.durations.emphasizedAccel + 50
                            onTriggered: Notifs.notifications.removePopupNotification(wrapper.modelData)
                        }
                    }
                }
            }
        }
    }
}
