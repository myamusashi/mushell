pragma ComponentBehavior: Bound

import QtQuick

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: numLockOSD

    width: parent.width
    height: GlobalStates.isOSDVisible("numlock") ? 50 : 0
    visible: height > 0
    clip: true

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
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
                color: Colours.m3Colors.m3OnBackground
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }

            Icon {
                type: Icon.Material
                icon: KeyLockState.state.numLock ? "lock" : "lock_open_right"
                color: KeyLockState.state.numLock ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Tertiary
                font.pointSize: Appearance.fonts.size.large * 1.5
            }
        }
    }
}
