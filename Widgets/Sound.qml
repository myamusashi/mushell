pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: root

    implicitWidth: container.width
    implicitHeight: parent.height
    color: "transparent"
    radius: Appearance.rounding.small

    property string icon: Audio.getIcon(root.node)
    property PwNode node: Pipewire.defaultAudioSink

    Behavior on implicitWidth {
        NAnim {}
    }

    PwObjectTracker {
        objects: [root.node]
    }

    Dots {
        id: container

        spacing: 5

        Icon {
            type: Icon.Material
            color: Colours.m3Colors.m3OnBackground
            icon: root.icon
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.fonts.size.large * 1.5
        }

        StyledText {
            color: Colours.m3Colors.m3OnBackground
            text: (root.node.audio.volume * 100).toFixed(0) + "%"
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.fonts.size.medium
        }
    }

    MArea {
        acceptedButtons: Qt.MiddleButton | Qt.LeftButton
        anchors.fill: parent

        onClicked: mevent => {
            if (mevent.button === Qt.MiddleButton)
                Audio.toggleMute(root.node);
        }

        onWheel: mevent => Audio.wheelAction(mevent, root.node)
    }
}
