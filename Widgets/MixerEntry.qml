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

    anchors.centerIn: parent
    spacing: Appearance.spacing.normal

    required property bool useCustomProperties
    property Component customProperty
    required property PwNode node
    property string icon: Audio.getIcon(node)

    PwObjectTracker {
        objects: [root.node]
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: root.icon !== ""
            icon: root.icon
            color: Themes.m3Colors.m3OnSurface
            font.pointSize: Appearance.fonts.extraLarge
        }

        Loader {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            active: true
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
            }
        }

        StyledButton {
            Layout.alignment: Qt.AlignVCenter
            buttonTitle: root.node.audio.muted ? "unmute" : "mute"
            onClicked: root.node.audio.muted = !root.node.audio.muted
            buttonTextColor: Themes.m3Colors.m3OnSurface
            buttonColor: Themes.m3Colors.m3SurfaceContainer
            isButtonFullRound: false
            backgroundRounding: 15
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

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
