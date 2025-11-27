import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Item {
    id: delegateNotif

    property alias contentLayout: contentLayout
    property alias iconLayout: iconLayout
    required property Notification modelData

    width: parent.width
    height: contentLayout.height * 1.3
    clip: true
    scale: 0.9
    opacity: 0

    Component.onCompleted: {
        scaleAnim.start();
        opacityAnim.start();
    }

    NAnim {
        id: scaleAnim

        target: delegateNotif
        property: "scale"
        from: 0.9
        to: 1
        duration: Appearance.animations.durations.normal
    }

    NAnim {
        id: opacityAnim

        target: delegateNotif
        property: "opacity"
        from: 0
        to: 1
        duration: Appearance.animations.durations.normal
    }

    Behavior on x {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.normal
        }
    }

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.normal
        }
    }

    RetainableLock {
        id: retainNotif

        object: delegateNotif.modelData
        locked: true
    }

    Timer {
        id: closePopups

        interval: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000
        running: true

        onTriggered: Notifs.notifications.removePopupNotification(delegateNotif.modelData)
    }

    StyledRect {
        anchors.fill: parent
        color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3ErrorContainer : Themes.m3Colors.m3SurfaceContainerLow
        radius: Appearance.rounding.large
        border.color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3Error : "transparent"
        border.width: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? 1 : 0

        MArea {
            id: delegateMouseNotif

            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                closePopups.stop();
            }
            onExited: {
                closePopups.start();
            }
            drag {
                axis: Drag.XAxis
                target: delegateNotif
                onActiveChanged: {
                    if (delegateMouseNotif.drag.active)
                        return;
                    if (Math.abs(delegateNotif.x) > (delegateNotif.width * 0.45)) {
                        Notifs.notifications.removePopupNotification(delegateNotif.modelData);
                        Notifs.notifications.removeListNotification(delegateNotif.modelData);
                    } else
                        delegateNotif.x = 0;
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 15
            anchors.leftMargin: 15
			anchors.rightMargin: 15
            spacing: Appearance.spacing.normal

            Icon {
                id: iconLayout

                modelData: delegateNotif.modelData
            }

            Content {
                id: contentLayout

                notif: delegateNotif.modelData
                width: parent.width - 40 - parent.spacing
            }
        }
    }
}
