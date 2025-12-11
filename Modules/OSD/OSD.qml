pragma ComponentBehavior: Bound

import QtQuick

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: mainRect

    anchors {
        right: parent.right
        bottom: parent.bottom
    }

    implicitWidth: GlobalStates.isVolumeOSDShow || GlobalStates.isNumLockOSDShow || GlobalStates.isCapsLockOSDShow ? 250 : 0
    implicitHeight: GlobalStates.isVolumeOSDShow || GlobalStates.isNumLockOSDShow || GlobalStates.isCapsLockOSDShow ? calculateHeight() : 0
    radius: 0
    topLeftRadius: Appearance.rounding.normal
    color: Colours.m3Colors.m3Background
    clip: true

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    function calculateHeight() {
        var totalHeight = 0;
        var spacing = 10;
        var padding = 10;

        if (GlobalStates.isCapsLockOSDShow)
            totalHeight += 50;
        if (GlobalStates.isNumLockOSDShow)
            totalHeight += 50;
        if (GlobalStates.isVolumeOSDShow)
            totalHeight += 80;

        var activeCount = 0;
        if (GlobalStates.isCapsLockOSDShow)
            activeCount++;
        if (GlobalStates.isNumLockOSDShow)
            activeCount++;
        if (GlobalStates.isVolumeOSDShow)
            activeCount++;

        if (activeCount > 1)
            totalHeight += (activeCount - 1) * spacing;

        return totalHeight > 0 ? totalHeight + (padding * 2) : 0;
    }

    Loader {
        anchors.fill: parent
        active: GlobalStates.isVolumeOSDShow || GlobalStates.isNumLockOSDShow || GlobalStates.isCapsLockOSDShow
        asynchronous: true
        sourceComponent: Column {
            anchors {
                fill: parent
                margins: 15
            }
            spacing: Appearance.spacing.normal

            CapsLockWidget {
                id: capsLockOSD
                isCapsLockOSDShow: GlobalStates.isCapsLockOSDShow
            }

            NumLockWidget {
                id: numLockOSD
                isNumLockOSDShow: GlobalStates.isNumLockOSDShow
            }

            Volumes {
                id: volumeOSD

                isVolumeOSDShow: GlobalStates.isVolumeOSDShow
            }
        }
    }
}
