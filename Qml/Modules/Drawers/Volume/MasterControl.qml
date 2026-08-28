pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

ColumnLayout {
    id: root

    required property real sliderHeight
    required property var controller

    property alias showVolume: root.showVolumeInternal

    property bool showVolumeInternal: false

    implicitWidth: 50
    implicitHeight: 250
    spacing: Appearance.spacing.normal

    Item {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        implicitWidth: 30
        implicitHeight: 30

        Icon {
            id: volumeIcon

            anchors.centerIn: parent
            type: Icon.Material
            icon: Audio.getIcon(Pipewire.defaultAudioSink)
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge
            opacity: root.showVolumeInternal ? 0 : 1
            scale: root.showVolumeInternal ? 0.5 : 1

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        StyledText {
            anchors.centerIn: volumeIcon
            text: (Pipewire.defaultAudioSink.audio.volume * 100).toFixed(0)
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            opacity: root.showVolumeInternal ? 1 : 0
            scale: root.showVolumeInternal ? 1 : 0.5

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: mouseEvent => {
                if (mouseEvent.button === Qt.LeftButton)
                    Audio.toggleMute(Pipewire.defaultAudioSink);
            }
        }
    }

    Timer {
        id: volumeHideTimer

        interval: 500
        onTriggered: root.showVolumeInternal = false
    }

    StyledSlide {
        Layout.fillWidth: true
        Layout.preferredHeight: root.sliderHeight
        orientation: Qt.Vertical
        popupValueFormat: volumeValue => Math.round(volumeValue * 100)
        value: Pipewire.defaultAudioSink.audio.volume
        onMoved: Pipewire.defaultAudioSink.audio.volume = value
        onValueChanged: {
            root.showVolumeInternal = true;
            if (!pressed)
                volumeHideTimer.restart();
        }
        onPressedChanged: {
            if (pressed) {
                GlobalStates.pauseOSD("volume");
                volumeHideTimer.stop();
                root.showVolumeInternal = true;
            } else {
                GlobalStates.resumeOSD("volume");
                volumeHideTimer.restart();
            }
        }
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 15
        implicitHeight: 15

        Pulse {
            anchors.centerIn: parent
            isActive: Players.active.playbackState === MprisPlaybackState.Playing && GlobalStates.isOSDVisible("volume")
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onEntered: GlobalStates.pauseOSD("volume")
            onExited: GlobalStates.resumeOSD("volume")
            onClicked: root.controller.openPerAppVolume = !root.controller.openPerAppVolume
        }
    }
}
