pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Vast.Audio
import Vast.Utils

import qs.Core.Configs
import qs.Core.Utils
import qs.Widgets
import qs.Services
import qs.Components.Base

ScrollView {
    id: root

    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    property int currentSinkIndex: 0

    property var audioCards: ({})
    property string audioProfileName: ""
    property string audioProfileDescription: ""

    Instantiator {
        id: audioProfiles

        model: AudioProfilesWatcher.cards
        delegate: QtObject {
            required property var card
            required property string name
            required property string description

            Component.onCompleted: {
                root.audioCards = card;
                root.audioProfileName = name;
                root.audioProfileDescription = description;
            }
        }
    }

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

            Repeater {
                model: ScriptModel {
                    values: Pipewire.nodes.values.filter(n => !n.isStream && n.audio && (n.type & PwNodeType.Sink)).map(n => ({
                                nodeId: n.id,
                                name: n.name,
                                description: n.description
                            }))
                }

                delegate: RowLayout {
                    id: volumeEntryDelegate

                    required property var modelData
                    required property int index

                    spacing: Appearance.spacing.small

                    StyledRect {
                        id: sinkIndicator
                        property color target: root.currentSinkIndex === volumeEntryDelegate.index ? Colours.m3Colors.m3Primary : "transparent"
                        property color colorFrom
                        property color colorTo
                        property bool colorBlending: false
                        property real colorBlendProgress: 1.0
                        onColorBlendProgressChanged: {
                            if (!colorBlending)
                                return;
                            if (colorBlendProgress >= 1) {
                                color = colorTo;
                                colorBlending = false;
                            } else if (colorBlendProgress > 0) {
                                color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                            }
                        }
                        onTargetChanged: {
                            colorBlendAnim.stop();
                            colorFrom = color;
                            colorTo = target;
                            colorBlending = true;
                            colorBlendProgress = 0.0;
                            colorBlendAnim.start();
                        }

                        implicitWidth: 15
                        implicitHeight: 15
                        radius: Appearance.rounding.full
                        border.width: 2
                        border.color: Colours.m3Colors.m3Primary

                        NAnim {
                            id: colorBlendAnim
                            target: sinkIndicator
                            property: "colorBlendProgress"
                            from: 0.0
                            to: 1.0
                            duration: Appearance.animations.durations.small
                        }
                    }

                    StyledText {
                        text: volumeEntryDelegate.modelData.description ?? ""
                        color: root.currentSinkIndex === volumeEntryDelegate.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: root.currentSinkIndex === volumeEntryDelegate.index ? Font.Medium : Font.Normal
                    }

                    TapHandler {
                        onTapped: {
                            root.currentSinkIndex = volumeEntryDelegate.index;
                            AudioDevicesWatcher.setDefaultSink(volumeEntryDelegate.modelData.name);
                            Configs.audio.defaultSinkName = volumeEntryDelegate.modelData.name;
                        }
                    }
                }
            }

            MixerEntry {
                useCustomProperties: true
                audioNode: Pipewire.defaultAudioSink
                customProperty: AudioProfiles {
                    card: root.audioCards
                    Layout.fillWidth: true
                }
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

                    PwObjectTracker {
                        objects: [groups.modelData.source]
                    }

                    IconImage {
                        source: IconUtils.guessIconPath(groups.modelData.source)
                        asynchronous: true
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 60
                        Layout.alignment: Qt.AlignVCenter
                    }

                    MixerEntry {
                        id: mixerGroup

                        audioNode: groups.modelData.source
                    }
                }
            }
        }
    }
}
