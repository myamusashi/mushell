pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import "../../Components"

SettingsCard {
    id: root

    title: qsTr("Input Devices")

    readonly property var sourceNodes: {
        const nodes = Pipewire.nodes.values;
        const filtered = nodes.filter(n => !n.isStream && n.audio && (n.type & PwNodeType.Source));
        filtered.sort((a, b) => (a.description || a.name).localeCompare(b.description || b.name));
        return filtered;
    }

    readonly property var currentSource: Pipewire.defaultAudioSource
    readonly property int count: sourceNodes.length

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            visible: root.count === 0
            text: qsTr("No input devices detected.")
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        Repeater {
            model: root.sourceNodes

            delegate: AudioLevelRow {
                id: sourceDelegate

                required property PwNode modelData

                Layout.fillWidth: true
                node: sourceDelegate.modelData
                selectable: true
                isCurrent: root.currentSource && sourceDelegate.modelData.id === root.currentSource.id
                onDefaultRequested: {
                    Pipewire.preferredDefaultAudioSource = sourceDelegate.modelData;
                }
            }
        }
    }
}
