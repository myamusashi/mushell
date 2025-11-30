import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Item {
    id: root

    property alias contentLayout: contentLayout
    property alias iconLayout: iconLayout
    required property Notification modelData
    property bool isRemoving: false
    property alias mArea: delegateMouseNotif

    signal entered
    signal exited

    width: parent.width
    height: isRemoving ? 0 : contentLayout.height * 1.3
    clip: true
    x: parent.width

    Component.onCompleted: {
        slideInAnim.start();
    }

    signal animationCompleted

    NAnim {
		id: slideInAnim

        target: root
        property: "x"
        from: root.parent.width
        to: 0
        duration: Appearance.animations.durations.emphasized
        easing.bezierCurve: Appearance.animations.curves.emphasized

        onFinished: root.animationCompleted()
    }

    NAnim {
        id: slideOutAnim

        target: root
        property: "x"
        to: root.width
        duration: Appearance.animations.durations.emphasizedAccel
        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
    }

    Behavior on x {
        enabled: !root.isRemoving && !delegateMouseNotif.drag.active
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }

    RetainableLock {
        id: retainNotif

        object: root.modelData
        locked: true
    }

    function removeNotificationWithAnimation() {
        isRemoving = true;
        slideOutAnim.start();

        Qt.callLater(function () {
            removeTimer.start();
        });
    }

    StyledRect {
        anchors.fill: parent
        color: root.modelData.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3ErrorContainer : Themes.m3Colors.m3SurfaceContainer
        topLeftRadius: Appearance.rounding.large
        bottomLeftRadius: Appearance.rounding.large
        radius: 0
        topRightRadius: 0
        bottomRightRadius: 0
        border.color: root.modelData.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3Error : "transparent"
        border.width: root.modelData.urgency === NotificationUrgency.Critical ? 1 : 0

        MArea {
            id: delegateMouseNotif

            anchors.fill: parent
            hoverEnabled: true

            onEntered: root.entered()
            onExited: root.exited()

            drag {
                axis: Drag.XAxis
                target: root
                minimumX: -root.width
                maximumX: root.width

                onActiveChanged: {
                    if (delegateMouseNotif.drag.active)
                        return;

                    if (Math.abs(root.x) > (root.width * 0.45)) {
                        var targetX = root.x > 0 ? root.width : -root.width;
                        swipeOutAnim.to = targetX;
                        swipeOutAnim.start();

                        Qt.callLater(function () {
                            swipeRemoveTimer.start();
                        });
                    } else
                        root.x = 0;
                }
            }

            NAnim {
                id: swipeOutAnim

                target: root
                property: "x"
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.standardAccel
            }

            Timer {
                id: swipeRemoveTimer

                interval: Appearance.animations.durations.normal
                onTriggered: {
                    Notifs.notifications.removePopupNotification(root.modelData);
                    Notifs.notifications.removeListNotification(root.modelData);
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

                modelData: root.modelData
            }

            Content {
                id: contentLayout

                notif: root.modelData
                width: parent.width - 40 - parent.spacing
            }
        }
    }
}
