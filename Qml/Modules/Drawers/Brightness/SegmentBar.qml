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
        const usable = root.width - root.segmentMargins * 2;
        const clamped = Math.max(root.segmentMargins, Math.min(root.width - root.segmentMargins, x));
        Brightness.setBrightness(Math.round(((clamped - root.segmentMargins) / usable) * Brightness.maxValue));
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
                    id: cell

                    required property int index

                    width: (pill.width - root.segmentMargins * 2 - (root.segmentCount - 1) * root.segmentSpacing) / root.segmentCount
                    height: parent.height

                    Rectangle {
                        id: segment

                        readonly property int litSegments: Math.round(root.ratio * root.segmentCount)
                        readonly property bool lit: cell.index < litSegments

                        anchors.centerIn: parent
                        width: cell.width
                        height: cell.height
                        radius: 0

                        color: lit ? "white" : "transparent"
                        border.color: "black"
                        border.width: 0.5
                    }
                }
            }
        }
    }
}
