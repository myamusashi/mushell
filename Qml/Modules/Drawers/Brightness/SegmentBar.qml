pragma ComponentBehavior: Bound

import QtQuick

import qs.Services

Rectangle {
    id: root

    signal interactStarted
    signal interactEnded

    color: "black"

    implicitWidth: 220
    implicitHeight: 15

    readonly property real ratio: Brightness.value / (Brightness.maxValue || 1)
    property int segmentCount: 20
    property real segmentSpacing: 0.5
    property real segmentMargins: 0.5

    function commitFromX(x: real): void {
        const usable = width - segmentMargins * 2;
        const clamped = Math.max(segmentMargins, Math.min(width - segmentMargins, x));
        Brightness.setBrightness(Math.round(((clamped - segmentMargins) / usable) * Brightness.maxValue));
    }

    MouseArea {
        id: interactionArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => {
            root.interactStarted();
            root.commitFromX(mouse.x);
        }
        onReleased: root.interactEnded()
        onPositionChanged: mouse => {
            if (interactionArea.pressed)
                root.commitFromX(mouse.x);
        }
        onCanceled: root.interactEnded()
    }

    Item {
        id: pill

        anchors.fill: parent

        Row {
            anchors.fill: parent
            anchors.margins: root.segmentMargins
            spacing: root.segmentSpacing

            Repeater {
                model: root.segmentCount

                delegate: Item {
                    id: segmentCell

                    required property int index

                    width: (pill.width - root.segmentMargins * 2 - (root.segmentCount - 1) * root.segmentSpacing) / root.segmentCount
                    height: parent.height

                    Rectangle {
                        id: segment

                        readonly property int litSegments: Math.round(root.ratio * root.segmentCount)
                        readonly property bool isLit: segmentCell.index < litSegments

                        anchors.centerIn: parent
                        width: segmentCell.width
                        height: segmentCell.height
                        radius: 0

                        color: isLit ? "white" : "transparent"
                        border.color: "black"
                        border.width: 0.5
                    }
                }
            }
        }
    }
}
