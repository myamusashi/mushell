pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Services
import qs.Widgets

ScrollView {
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    RowLayout {
        anchors.fill: parent
        Layout.margins: 15
        spacing: 20

        ColumnLayout {
            Layout.margins: 10
            Layout.alignment: Qt.AlignTop

            PwNodeLinkTracker {
                id: linkTracker

                node: Pipewire.defaultAudioSink
            }

            MixerEntry {
                useCustomProperties: false
                node: Pipewire.defaultAudioSink
            }

            Rectangle {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3Outline
                implicitHeight: 1
            }

            Repeater {
                model: linkTracker.linkGroups

                delegate: RowLayout {
                    id: groups

                    required property PwLinkGroup modelData

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    IconImage {
                        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(groups.modelData.source.name)?.icon, "image-missing")
                        asynchronous: true
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 60
                        Layout.alignment: Qt.AlignVCenter
                    }

                    MixerEntry {
                        id: mixerGroup

                        useCustomProperties: false
                        node: groups.modelData.source
                    }
                }
            }
        }
    }
}
