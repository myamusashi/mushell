pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import "../../Components"

SettingsCard {
    id: root

    title: qsTr("Playback")

    readonly property var streamNodes: {
        const nodes = Pipewire.nodes.values;
        const filtered = nodes.filter(n => n.isStream && n.audio && (n.type & PwNodeType.Sink));
        filtered.sort((a, b) => (a.description || a.name).localeCompare(b.description || b.name));
        return filtered;
    }

    readonly property int count: streamNodes.length

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            visible: root.count === 0
            text: qsTr("No active playback streams.")
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        Repeater {
            model: root.streamNodes

            delegate: RowLayout {
                id: streamDelegate

                required property PwNode modelData

                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                IconImage {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter
                    source: IconUtils.guessIconPath(streamDelegate.modelData)
                    asynchronous: true
                }

                AudioLevelRow {
                    Layout.fillWidth: true
                    node: streamDelegate.modelData
                }
            }
        }
    }
}
