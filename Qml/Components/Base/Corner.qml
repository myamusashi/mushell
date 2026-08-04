import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

WrapperItem {
    id: root

    anchors.margins: -1

    property alias color: shapePath.fillColor
    property alias radius: root.implicitWidth

    required property int location
    required property int extensionSide

    readonly property bool isTopRight: location === Qt.TopRightCorner
    readonly property bool isTopLeft: location === Qt.TopLeftCorner
    readonly property bool isBottomRight: location === Qt.BottomRightCorner
    readonly property bool isBottomLeft: location === Qt.BottomLeftCorner

    readonly property bool isVertical: extensionSide === Qt.Vertical
    readonly property bool isHorizontal: extensionSide === Qt.Horizontal

    margin: -1
    implicitWidth: 30
    implicitHeight: implicitWidth

    Behavior on implicitWidth {
        NAnim {}
    }

    // qmllint disable
    states: [
        State {
            name: "TR_Vert"
            when: root.isTopRight && root.isVertical
            AnchorChanges {
                target: root
                anchors.bottom: parent.top
                anchors.right: parent.right
            }
            PropertyChanges {
                target: root
                rotation: 0
            }
        },
        State {
            name: "TR_Horiz"
            when: root.isTopRight && root.isHorizontal
            AnchorChanges {
                target: root
                anchors.top: parent.top
                anchors.left: parent.right
            }
            PropertyChanges {
                target: root
                rotation: 180
            }
        },
        State {
            name: "TL_Vert"
            when: root.isTopLeft && root.isVertical
            AnchorChanges {
                target: root
                anchors.bottom: parent.top
                anchors.left: parent.left
            }
            PropertyChanges {
                target: root
                rotation: 90
            }
        },
        State {
            name: "TL_Horiz"
            when: root.isTopLeft && root.isHorizontal
            AnchorChanges {
                target: root
                anchors.top: parent.top
                anchors.right: parent.left
            }
            PropertyChanges {
                target: root
                rotation: 270
            }
        },
        State {
            name: "BR_Vert"
            when: root.isBottomRight && root.isVertical
            AnchorChanges {
                target: root
                anchors.top: parent.bottom
                anchors.right: parent.right
            }
            PropertyChanges {
                target: root
                rotation: 270
            }
        },
        State {
            name: "BR_Horiz"
            when: root.isBottomRight && root.isHorizontal
            AnchorChanges {
                target: root
                anchors.bottom: parent.bottom
                anchors.left: parent.right
            }
            PropertyChanges {
                target: root
                rotation: 90
            }
        },
        State {
            name: "BL_Vert"
            when: root.isBottomLeft && root.isVertical
            AnchorChanges {
                target: root
                anchors.top: parent.bottom
                anchors.left: parent.left
            }
            PropertyChanges {
                target: root
                rotation: 180
            }
        },
        State {
            name: "BL_Horiz"
            when: root.isBottomLeft && root.isHorizontal
            AnchorChanges {
                target: root
                anchors.bottom: parent.bottom
                anchors.right: parent.left
            }
            PropertyChanges {
                target: root
                rotation: 0
            }
        }
    ]
    // qmllint enable

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath

            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: "white"
            pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
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
                radiusX: root.implicitWidth
                radiusY: root.implicitHeight
                useLargeArc: false
                direction: PathArc.Counterclockwise
            }
        }
    }
}
