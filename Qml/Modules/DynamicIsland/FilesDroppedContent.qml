pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property var island
    required property bool active

    readonly property int fileCount: root.island.droppedFiles.length
    readonly property real maxContentHeight: fileCount * 18 + (fileCount > 1 ? fileCount - 1 : 0) * 4
    readonly property real visibleHeight: Math.min(200, maxContentHeight)

    readonly property real fileNameMaxWidth: root.active ? computeMaxWidth() : 0

    implicitWidth: Math.max(220, fileNameMaxWidth + 80)
    implicitHeight: visibleHeight + 56

    function computeMaxWidth() {
        var maximum = 0;
        for (var i = 0; i < fileCount; i++)
            maximum = Math.max(maximum, String(root.island.droppedFiles[i]).split("/").pop().length);
        return Math.min(300, maximum * 8 + 40);
    }

    StyledText {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 8
        }

        visible: root.active
        text: qsTr("%1 file(s)").arg(fileCount)
        font.pixelSize: Appearance.fonts.size.normal
        font.weight: Font.DemiBold
        color: Colours.m3Colors.m3OnSurface
    }

    Flickable {
        id: filesFlickable

        anchors {
            top: parent.top
            topMargin: 32
            left: parent.left
            right: parent.right
            leftMargin: 8
            rightMargin: 12
        }

        height: root.visibleHeight
        contentWidth: width
        contentHeight: root.maxContentHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        visible: root.active

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.island.droppedFiles

                delegate: StyledText {
                    required property var modelData

                    width: filesFlickable.width
                    text: String(modelData).split("/").pop()
                    font.pixelSize: Appearance.fonts.size.small
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Rectangle {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 4
        }

        visible: root.active
        implicitWidth: Math.max(72, nextLabel.implicitWidth + 24)
        implicitHeight: 28
        radius: Appearance.rounding.small
        color: nextMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"

        StyledText {
            id: nextLabel

            anchors.centerIn: parent
            text: qsTr("Next")
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
            color: Colours.m3Colors.m3Primary
        }

        MArea {
            id: nextMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.island.goToDeviceSelection()
        }
    }
}
