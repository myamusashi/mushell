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
    scale: 0.9
    opacity: 0

    Component.onCompleted: {
        scaleAnim.start();
        opacityAnim.start();
    }

    NAnim {
		id: scaleAnim

        target: root
        property: "scale"
        from: 0.9
        to: 1
        duration: Appearance.animations.durations.emphasized
        easing.bezierCurve: Appearance.animations.curves.emphasized
    }

    NAnim {
		id: opacityAnim

        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: Appearance.animations.durations.emphasizedDecel
        easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
    }

    NAnim {
		id: exitScaleAnim

        target: root
        property: "scale"
        to: 0.9
        duration: Appearance.animations.durations.emphasizedAccel
        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
    }

    NAnim {
		id: exitOpacityAnim

        target: root
        property: "opacity"
        to: 0
        duration: Appearance.animations.durations.emphasizedAccel
        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
    }

    Behavior on x {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        enabled: !root.isRemoving
        NAnim {
            duration: Appearance.animations.durations.emphasizedDecel
            easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
        }
    }

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }

    Behavior on scale {
        enabled: !root.isRemoving
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
        exitScaleAnim.start();
        exitOpacityAnim.start();

        Qt.callLater(function () {
            removeTimer.start();
        });
    }

    StyledRect {
        anchors.fill: parent
        color: root.modelData.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3ErrorContainer : Themes.m3Colors.m3SurfaceContainerLow
        radius: Appearance.rounding.large
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
                    } else {
                        root.x = 0;
                    }
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
