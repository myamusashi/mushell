import QtQuick
import Quickshell.Services.Notifications

import qs.Configs
import qs.Helpers
import qs.Components

Item {
    id: root

    property alias contentLayout: contentLayout
    property alias iconLayout: iconLayout
    required property var notif
    property bool isRemoving: false
    property alias mArea: delegateMouseNotif

    signal entered
    signal exited
    signal animationCompleted

    width: parent.width
    height: isRemoving ? 0 : contentLayout.height * 1.3
    clip: true
    x: parent.width

    Component.onCompleted: {
        slideInAnim.start();
    }

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

    function removeNotificationWithAnimation() {
        isRemoving = true;
        slideOutAnim.start();

        Qt.callLater(function () {
            swipeRemoveTimer.start();
        });
    }

    StyledRect {
        anchors.fill: parent
        color: root.notif.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3ErrorContainer : Themes.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal
        anchors.leftMargin: 10
        clip: true
        border.color: root.notif.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3Error : "transparent"
        border.width: root.notif.urgency === NotificationUrgency.Critical ? 1 : 0

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
                    root.removeNotificationWithAnimation();
                    if (root.notif)
                        root.notif.close();
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 10
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: Appearance.spacing.normal

            Icon {
                id: iconLayout

                modelData: root.notif
            }

            Content {
                id: contentLayout

                modelData: root.notif
                width: parent.width - 40 - parent.spacing
            }
        }
    }
}
