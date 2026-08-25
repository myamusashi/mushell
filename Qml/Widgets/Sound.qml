pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "../Components/Base"

StyledRect {
    id: root

    readonly property PwNode audioNode: Pipewire.defaultAudioSink

    implicitWidth: container.width
    implicitHeight: parent.height
    color: "transparent"
    radius: Appearance.rounding.small

    Behavior on implicitWidth {
        NAnim {}
    }

    Dots {
        id: container

        spacing: Appearance.spacing.small

        Icon {
            type: Icon.Material
            color: Colours.m3Colors.m3OnBackground
            icon: Audio.getIcon(root.audioNode)
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.fonts.size.large * 1.5
        }

        StyledText {
            color: Colours.m3Colors.m3OnBackground
            text: (root.audioNode.audio.volume * 100).toFixed(0) + "%"
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.fonts.size.medium
        }
    }

    MArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.LeftButton
        onWheel: mouseEvent => Audio.wheelAction(mouseEvent, root.audioNode)
        onClicked: mouseEvent => {
            if (mouseEvent.button === Qt.MiddleButton)
                Audio.toggleMute(root.audioNode);
            else if (mouseEvent.button === Qt.LeftButton)
                GlobalStates.toggleOSD("volume");
        }
    }
}
