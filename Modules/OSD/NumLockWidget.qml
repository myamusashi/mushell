pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

Item {
    id: numLockOSD

	required property bool isNumLockOSDShow

    width: parent.width
    height: isNumLockOSDShow ? 50 : 0
    visible: height > 0
    clip: true

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }

    StyledRect {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spacing.normal
            opacity: numLockOSD.height / 50

            StyledText {
                text: "Num Lock"
                font.weight: Font.Medium
                color: Themes.m3Colors.m3OnBackground
                font.pixelSize: Appearance.fonts.large * 1.5
            }

            MaterialIcon {
                icon: KeyLockState.state.numLock ? "lock" : "lock_open_right"
                color: KeyLockState.state.numLock ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3Tertiary
                font.pointSize: Appearance.fonts.large * 1.5
            }
        }
    }
}
