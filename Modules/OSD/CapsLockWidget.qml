import QtQuick

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

Item {
    id: capsLockOSD

    required property bool isCapsLockOSDShow

    width: parent.width
    height: isCapsLockOSDShow ? 50 : 0
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
            opacity: capsLockOSD.height / 50

            StyledText {
                text: "Caps Lock"
                font.weight: Font.Medium
                color: Themes.m3Colors.m3OnBackground
                font.pixelSize: Appearance.fonts.large * 1.5
            }

            MaterialIcon {
                icon: KeyLockState.state.capsLock ? "lock" : "lock_open_right"
                color: KeyLockState.state.capsLock ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3Tertiary
                font.pointSize: Appearance.fonts.large * 1.5
            }
        }
    }
}
