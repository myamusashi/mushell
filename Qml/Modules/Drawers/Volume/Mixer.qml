pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Column {
    id: root

    required property PwNode audioNode
    required property real sliderHeight
    required property int itemSize

    property bool showVolume: false

    spacing: Appearance.spacing.normal

    PwObjectTracker {
        objects: [root.audioNode]
    }

    Item {
        implicitWidth: root.itemSize
        implicitHeight: 30

        IconImage {
            id: appIcon

            anchors.centerIn: parent
            implicitWidth: 30
            implicitHeight: 30
            opacity: root.showVolume ? 0 : 1
            scale: root.showVolume ? 0.5 : 1
            source: IconUtils.guessIconPath(root.audioNode)

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
            anchors.centerIn: appIcon
            text: (root.audioNode.audio.volume * 100).toFixed(0)
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            opacity: root.showVolume ? 1 : 0
            scale: root.showVolume ? 1 : 0.5

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

        Timer {
            id: appVolumeHideTimer

            interval: 500
            onTriggered: root.showVolume = false
        }
    }

    StyledSlide {
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: root.itemSize
        implicitHeight: root.sliderHeight
        orientation: Qt.Vertical
        popupValueFormat: volumeValue => Math.round(volumeValue * 100)
        value: root.audioNode.audio.volume
        onMoved: root.audioNode.audio.volume = value
        onValueChanged: {
            root.showVolume = true;
            if (!pressed)
                appVolumeHideTimer.restart();
        }
        onPressedChanged: {
            if (pressed) {
                GlobalStates.pauseOSD("volume");
                appVolumeHideTimer.stop();
                root.showVolume = true;
            } else {
                GlobalStates.resumeOSD("volume");
                appVolumeHideTimer.restart();
            }
        }
    }
}
