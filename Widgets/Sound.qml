pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

StyledRect {
    id: root

    property string icon: Audio.getIcon(root.node)
    property PwNode node: Pipewire.defaultAudioSink

    Layout.fillHeight: true
    // color: Themes.colors.withAlpha(Themes.m3Colors.m3Background, 0.79)
    color: "transparent"
    implicitWidth: container.width
    radius: 5

    Behavior on implicitWidth {
        NAnim {}
    }

    PwObjectTracker {
        objects: [root.node]
    }

    Dots {
        id: container

        spacing: 5

        MaterialIcon {
            color: Themes.m3Colors.m3OnBackground
            icon: root.icon
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.fonts.large * 1.5
        }

        StyledText {
            color: Themes.m3Colors.m3OnBackground
            text: (root.node.audio.volume * 100).toFixed(0) + "%"
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.fonts.medium
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
