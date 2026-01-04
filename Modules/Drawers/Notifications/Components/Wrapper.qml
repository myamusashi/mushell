import QtQuick
import Quickshell.Services.Notifications

import qs.Components
import qs.Configs
import qs.Helpers as H
import qs.Services

Item {
    id: root

    required property var notif
    property bool isPopup: false
    property alias contentLayout: contentLayout
    property alias iconLayout: iconLayout
    property alias mArea: delegateMouseNotif

    signal entered
    signal exited

    implicitWidth: parent.width
    implicitHeight: contentLayout.height * 1.3
    clip: true
    x: parent.width

    Timer {
        id: timer

        interval: root.notif.expireTimeout > 0 ? root.notif.expireTimeout : 5000
        running: !delegateMouseNotif.containsMouse
        onTriggered: {
            timer.stop();
            slideOutAnim.start();
        }
    }

    Component.onCompleted: {
        slideInAnim.start();
        timer.start();
    }

    Component.onDestruction: {
        slideInAnim.stop();
        slideOutAnim.stop();
        swipeOutAnim.stop();
        timer.stop();
    }

    ListView.onPooled: {
        slideInAnim.stop();
        slideOutAnim.stop();
        timer.stop();
    }

    ListView.onReused: {
        x = parent.width;
        slideInAnim.start();
        timer.restart();
    }

    NAnim {
        id: slideInAnim

        target: root
        property: "x"
        from: root.parent.width
        to: 0
        duration: Appearance.animations.durations.emphasized
        easing.bezierCurve: Appearance.animations.curves.emphasized
    }

    NAnim {
        id: slideOutAnim

        target: root
        property: "x"
        to: root.parent.width
        duration: Appearance.animations.durations.emphasizedAccel
        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
        onFinished: {
            if (root.isPopup)
                root.notif.popup = false;
        }
    }

    NAnim {
        id: swipeOutAnim

        target: root
        property: "x"
        duration: Appearance.animations.durations.small
        easing.bezierCurve: Appearance.animations.curves.standardAccel
        onFinished: {
            if (root.isPopup)
                root.notif.popup = false;
        }
    }

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }

    StyledRect {
        anchors {
            fill: parent
            leftMargin: 10
        }
        radius: Appearance.rounding.normal
        clip: true

        color: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainer

        border {
            color: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : "transparent"
            width: root.notif.urgency === NotificationUrgency.Critical ? 1 : 0
        }

        H.MArea {
            id: delegateMouseNotif

            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                root.entered();
                timer.stop();
            }

            onExited: {
                root.exited();
                timer.restart();
            }

            drag {
                axis: Drag.XAxis
                target: root
                minimumX: -root.width
                maximumX: root.width

                onActiveChanged: {
                    if (drag.active) {
                        timer.stop();
                        return;
                    }
                    if (Math.abs(root.x) > root.width * 0.45) {
                        swipeOutAnim.to = root.x > 0 ? root.width : -root.width;
                        swipeOutAnim.start();
                        root.notif.close();
                    } else {
                        root.x = 0;
                        timer.restart();
                    }
                }
            }
        }

        Row {
            anchors {
                fill: parent
                topMargin: 10
                leftMargin: 10
                rightMargin: 10
            }
            spacing: Appearance.spacing.normal

            Icon {
                id: iconLayout

                modelData: root.notif
            }

            Content {
                id: contentLayout

                modelData: root.notif
            }
        }
    }
}
