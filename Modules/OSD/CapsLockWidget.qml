import QtQuick

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

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
                color: Colours.m3Colors.m3OnBackground
                font.pixelSize: Appearance.fonts.large * 1.5
            }

            MaterialIcon {
                icon: KeyLockState.state.capsLock ? "lock" : "lock_open_right"
                color: KeyLockState.state.capsLock ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Tertiary
                font.pointSize: Appearance.fonts.large * 1.5
            }
        }
    }
}
