import QtQuick
import QtQuick.Shapes

import qs.Configs

Shape {
    id: root

    property int location: Qt.TopRightCorner
    property int extensionSide: Qt.Vertical

    property real radius: 30
    property color color: "white"

    width: radius
    height: radius

    Behavior on radius {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    preferredRendererType: Shape.CurveRenderer

    rotation: {
        if (location === Qt.TopRightCorner)
            return extensionSide === Qt.Vertical ? 0 : 180;
        else if (location === Qt.TopLeftCorner)
            return extensionSide === Qt.Vertical ? 90 : 270;
        else if (location === Qt.BottomRightCorner)
            return extensionSide === Qt.Vertical ? 270 : 90;
        else if (location === Qt.BottomLeftCorner)
            return extensionSide === Qt.Vertical ? 180 : 0;
        return 0;
    }

    states: [
        State {
            name: "TR_Vert"
            when: root.location === Qt.TopRightCorner && root.extensionSide === Qt.Vertical
            AnchorChanges {
                target: root
                anchors.bottom: parent.top
                anchors.right: parent.right
            }
        },
        State {
            name: "TR_Horiz"
            when: root.location === Qt.TopRightCorner && root.extensionSide === Qt.Horizontal
            AnchorChanges {
                target: root
                anchors.top: parent.top
                anchors.left: parent.right
            }
        },
        State {
            name: "TL_Vert"
            when: root.location === Qt.TopLeftCorner && root.extensionSide === Qt.Vertical
            AnchorChanges {
                target: root
                anchors.bottom: parent.top
                anchors.left: parent.left
            }
        },
        State {
            name: "TL_Horiz"
            when: root.location === Qt.TopLeftCorner && root.extensionSide === Qt.Horizontal
            AnchorChanges {
                target: root
                anchors.top: parent.top
                anchors.right: parent.left
            }
        },
        State {
            name: "BR_Vert"
            when: root.location === Qt.BottomRightCorner && root.extensionSide === Qt.Vertical
            AnchorChanges {
                target: root
                anchors.top: parent.bottom
                anchors.right: parent.right
            }
        },
        State {
            name: "BR_Horiz"
            when: root.location === Qt.BottomRightCorner && root.extensionSide === Qt.Horizontal
            AnchorChanges {
                target: root
                anchors.bottom: parent.bottom
                anchors.left: parent.right
            }
        },
        State {
            name: "BL_Vert"
            when: root.location === Qt.BottomLeftCorner && root.extensionSide === Qt.Vertical
            AnchorChanges {
                target: root
                anchors.top: parent.bottom
                anchors.left: parent.left
            }
        },
        State {
            name: "BL_Horiz"
            when: root.location === Qt.BottomLeftCorner && root.extensionSide === Qt.Horizontal
            AnchorChanges {
                target: root
                anchors.bottom: parent.bottom
                anchors.right: parent.left
            }
        }
    ]

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.color

        startX: root.width
        startY: 0

        PathLine {
            x: root.width
            y: root.height
        }
        PathLine {
            x: 0
            y: root.height
        }

        PathArc {
            x: root.width
            y: 0
            radiusX: root.radius
            radiusY: root.radius
            useLargeArc: false
            direction: PathArc.Counterclockwise
        }
    }
}
