pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: volumeOSD

    implicitWidth: parent.width
    implicitHeight: GlobalStates.isOSDVisible("volume") ? 80 : 0
    visible: height > 0
    clip: true

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    property string icon: Audio.getIcon(Pipewire.defaultAudioSink)

    StyledRect {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: "transparent"

        Item {
            id: content

            anchors {
                fill: parent
                leftMargin: 15
                rightMargin: 15
                topMargin: 10
                bottomMargin: 10
            }
            opacity: volumeOSD.height > 0 ? 1 : 0

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            Icon {
                id: volumeIcon

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                color: Colours.m3Colors.m3OnBackground
                icon: volumeOSD.icon
                font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
            }

            Column {
                anchors {
                    left: volumeIcon.right
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                }
                spacing: Appearance.spacing.small

                Row {
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: "Volume:"
                        font.weight: Font.Medium
                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.large
                    }

                    StyledText {
                        text: `${Math.round(Pipewire.defaultAudioSink?.audio.volume * 100)}%`
                        font.weight: Font.Medium
                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                StyledSlide {
                    width: parent.width
                    height: 32
                    value: Pipewire.defaultAudioSink.audio.volume
                    onValueChanged: Pipewire.defaultAudioSink.audio.volume = value
                }
            }
        }
    }
}
