pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "../Components/Base"

ColumnLayout {
    id: root

    property alias slider: volumeSlider
    required property PwNode audioNode
    property bool useCustomProperties: false
    property Component customProperty

    PwObjectTracker {
        id: objectTracker

        objects: [root.audioNode]
    }

    Loader {
        active: root.useCustomProperties

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignLeft
        sourceComponent: root.customProperty
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignCenter

        StyledRect {
            Layout.alignment: Qt.AlignCenter
            implicitWidth: 30
            implicitHeight: 30
            radius: Appearance.rounding.full

            Icon {
                id: iconItem

                type: Icon.Material
                anchors.centerIn: parent
                visible: icon !== ""
                icon: Audio.getIcon(root.audioNode)
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }

            MArea {
                id: mouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: mouseEvent => {
                    if (mouseEvent.button === Qt.LeftButton)
                        Audio.toggleMute(root.audioNode);
                }
                onWheel: mouseEvent => Audio.wheelAction(mouseEvent, root.audioNode)
            }
        }

        StyledSlide {
            id: volumeSlider

            Layout.fillWidth: true
            Layout.preferredHeight: 44
            popupValueFormat: volumeValue => Math.round(volumeValue * 100)
            value: root.audioNode.audio.volume
            onMoved: root.audioNode.audio.volume = value
        }
    }
}
