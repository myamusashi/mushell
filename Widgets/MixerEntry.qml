pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

ColumnLayout {
    id: root

    required property bool useCustomProperties
    property Component customProperty
    required property PwNode node
    property string icon: Audio.getIcon(node)

    PwObjectTracker {
        objects: [root.node]
    }

    RowLayout {
        Layout.alignment: Qt.AlignLeft
        MaterialIcon {
            Layout.alignment: Qt.AlignLeft
            visible: icon !== ""
            icon: root.icon
            color: Themes.m3Colors.onSurface
            font.pointSize: Appearance.fonts.extraLarge
        }

        Loader {
            active: true

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            sourceComponent: root.useCustomProperties ? root.customProperty : defaultNode
        }

        Component {
            id: defaultNode

            StyledLabel {
                text: {
                    const app = root.node.properties["application.name"] ?? (root.node.description != "" ? root.node.description : root.node.name);
                    const media = root.node.properties["media.name"];
                    return media != undefined ? `${app} - ${media}` : app;
                }
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        StyledButton {
            buttonTitle: root.node.audio.muted ? "unmute" : "mute"
            onClicked: root.node.audio.muted = !root.node.audio.muted
            buttonTextColor: Themes.m3Colors.onSurface
            buttonColor: Themes.m3Colors.surfaceContainer
            isButtonFullRound: false
            backgroundRounding: 15
        }
    }

    RowLayout {
        StyledLabel {
            Layout.preferredWidth: 50
            text: `${Math.floor(root.node.audio.volume * 100)}%`
        }

        StyledSlide {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            value: root.node.audio.volume
            onValueChanged: root.node.audio.volume = value
        }
    }
}
