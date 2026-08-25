import QtQuick
import Quickshell.Services.Notifications

import qs.Components.Feedback
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils as H
import qs.Services

Item {
    id: root

    property alias contentLayout: contentLayout
    property alias iconLayout: iconLayout
    property alias mouseArea: delegateMouseNotif

    required property var notif

    property bool isPopup: false
    property real timerDuration: 3000
    property real timerStartTime: 0
    property real timerRemaining: timerDuration

    signal entered
    signal exited

    implicitWidth: parent.width
    implicitHeight: innerRow.implicitHeight + 20
    clip: true
    x: parent.width

    function pauseTimer() {
        if (timer.running) {
            timerRemaining = Math.max(0, timerRemaining - (Date.now() - timerStartTime));
            timer.stop();
        }
        if (borderAnimation.animation.running)
            borderAnimation.animation.pause();
    }

    function resumeTimer() {
        if (!timer.running && timerRemaining > 0) {
            timer.interval = timerRemaining;
            timerStartTime = Date.now();
            timer.start();
        }
        if (borderAnimation.animation.paused)
            borderAnimation.animation.resume();
    }

    function resetTimer() {
        timerRemaining = timerDuration;
        timer.interval = timerDuration;
        timerStartTime = Date.now();
        timer.restart();
        borderAnimation.animation.restart();
    }

    Timer {
        id: timer

        interval: root.timerDuration
        onTriggered: slideOutAnim.start()
    }

    Component.onCompleted: {
        slideInAnim.start();
        timerStartTime = Date.now();
        timer.start();
    }

    Component.onDestruction: {
        slideInAnim.stop();
        slideOutAnim.stop();
        swipeOutAnim.stop();
    }

    ListView.onPooled: {
        slideInAnim.stop();
        slideOutAnim.stop();
        borderAnimation.animation.stop();
    }

    ListView.onReused: {
        x = parent.width;
        slideInAnim.start();
        resetTimer();
    }

    NAnim {
        id: slideInAnim

        target: root
        property: "x"
        from: root.parent.width
        to: 0
        duration: Appearance.animations.durations.emphasized
        easing.bezierCurve: Appearance.animations.curves.emphasized
        onFinished: borderAnimation.animation.start()
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
            root.notif.unlock(root);
        }
    }

    NAnim {
        id: swipeOutAnim

        target: root
        property: "x"
        duration: Appearance.animations.durations.small
        easing.bezierCurve: Appearance.animations.curves.standardAccel
        onFinished: {
            root.notif.unlock(root);
            root.notif.close();
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
        id: wrapperRect

        anchors {
            fill: parent
            leftMargin: 10
        }
        radius: Appearance.rounding.normal
        color: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainer

        HoverHandler {
            id: notifHover
        }

        Connections {
            target: notifHover

            function onHoveredChanged() {
                if (notifHover.hovered) {
                    root.pauseTimer();
                } else if (!delegateMouseNotif.pressed && !delegateMouseNotif.drag.active) {
                    root.resumeTimer();
                }
            }
        }

        Connections {
            target: contentLayout

            function onReplyFocusedChanged() {
                if (contentLayout.replyFocused)
                    root.pauseTimer();
                else if (!notifHover.hovered && !delegateMouseNotif.pressed && !delegateMouseNotif.drag.active)
                    root.resumeTimer();
            }
        }

        H.MArea {
            id: delegateMouseNotif

            onPressed: root.pauseTimer()

            onReleased: {
                if (!notifHover.hovered && !drag.active)
                    root.resumeTimer();
            }

            drag {
                axis: Drag.XAxis
                target: root
                minimumX: -root.width
                maximumX: root.width

                onActiveChanged: {
                    if (drag.active) {
                        root.pauseTimer();
                        return;
                    }
                    if (Math.abs(root.x) > root.width * 0.45) {
                        swipeOutAnim.to = root.x > 0 ? root.width : -root.width;
                        swipeOutAnim.start();
                    } else {
                        root.x = 0;
                        if (!notifHover.hovered)
                            root.resumeTimer();
                    }
                }
            }
        }

        Row {
            id: innerRow

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: Appearance.margin.small
                leftMargin: Appearance.margin.small
                rightMargin: Appearance.margin.small
            }
            spacing: Appearance.spacing.normal

            NotifIcon {
                id: iconLayout

                modelData: root.notif
            }

            Content {
                id: contentLayout

                width: parent.width - iconLayout.width - parent.spacing
                modelData: root.notif
            }
        }
    }

    Rectangle {
        anchors.fill: wrapperRect
        border {
            width: 2.0
            color: Colours.m3Colors.m3OutlineVariant
        }
        radius: wrapperRect.radius
        color: "transparent"
    }

    BorderProgress {
        id: borderAnimation

        anchors.fill: wrapperRect
        source: wrapperRect
        progress: 1.0
        radius: wrapperRect.radius
        borderWidth: 2.0
        borderColor: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary
        animationDuration: root.timerDuration
    }
}
