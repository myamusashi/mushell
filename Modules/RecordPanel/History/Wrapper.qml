import QtQuick

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    required property var modelData
    property var itemData: modelData
    property bool isRemoving: false
    signal entered
    signal exited
    signal animationCompleted

    width: parent.width
    height: isRemoving ? 0 : contentLayout.height * 1.3
    clip: true
    opacity: 0
    y: 50

    Component.onCompleted: {
        slideInAnim.start();
    }

    ParallelAnimation {
        id: slideInAnim

        NAnim {
            target: root
            property: "y"
            from: 50
            to: 0
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }

        NAnim {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }

        onFinished: root.animationCompleted()
    }

    ParallelAnimation {
        id: slideOutAnim

        NAnim {
            target: root
            property: "x"
            to: root.width
            duration: Appearance.animations.durations.emphasizedAccel
            easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
        }

        NAnim {
            target: root
            property: "opacity"
            to: 0
            duration: Appearance.animations.durations.emphasizedAccel
            easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
        }
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

    StyledRect {
        anchors.fill: parent
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal
        anchors.leftMargin: 10
        clip: true

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
                        slideOutAnim.start();
                    } else
                        root.x = 0;
                }
            }
        }

        Row {
            anchors {
                fill: parent
                margins: 10
            }
            spacing: Appearance.spacing.normal

            Icon {
                id: iconLayout

                modelData: root.itemData
            }

            Content {
                id: contentLayout

                modelData: root.itemData
                width: parent.width - iconLayout.width - parent.spacing
            }
        }
    }
}
