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
    required property PwNode node
    property bool useCustomProperties: false
    property Component customProperty

    PwObjectTracker {
        id: objectTracker

        objects: [root.node]
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
                icon: Audio.getIcon(root.node)
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }

            MArea {
                id: mArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: mevent => {
                    if (mevent.button === Qt.LeftButton)
                        Audio.toggleMute(root.node);
                }
                onWheel: mevent => Audio.wheelAction(mevent, root.node)
            }
        }

        StyledSlide {
            id: volumeSlider

            Layout.fillWidth: true
            Layout.preferredHeight: 44
            value: root.node.audio.volume
            onMoved: root.node.audio.volume = value
        }
    }
}
