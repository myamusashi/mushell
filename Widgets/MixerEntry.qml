pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell.Services.Pipewire

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ColumnLayout {
    id: root

    required property bool useCustomProperties
    property Component customProperty
    required property PwNode node
    property string icon: Audio.getIcon(node)

    PwObjectTracker {
        objects: [root.node]
    }

    Loader {
        active: true

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignLeft
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

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignCenter

        StyledRect {
            Layout.alignment: Qt.AlignCenter
            implicitWidth: 30
            implicitHeight: 30
            radius: Appearance.rounding.full

            MaterialIcon {
                anchors.centerIn: parent
                visible: icon !== ""
                icon: root.icon
                color: Colours.m3Colors.m3OnSurface
                font.pointSize: Appearance.fonts.size.large * 1.5
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
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            value: root.node.audio.volume
            onValueChanged: root.node.audio.volume = value
        }
    }
}
