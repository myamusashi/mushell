pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services

Switch {
    id: root

    property bool isUseIcon: true
    property string onIcon: "check"
    property string offIcon: "close"

    indicator: StyledRect {
        implicitWidth: 52
        implicitHeight: 32
        x: root.leftPadding
        y: parent.height / 2 - height / 2
        radius: Appearance.rounding.full
        color: root.checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3SurfaceContainerHighest
        border.width: 2
        border.color: root.checked ? "transparent" : Colours.m3Colors.m3Outline

        StyledRect {
            id: handle

            readonly property int margin: 4
            readonly property bool isActive: root.down || root.checked
            readonly property int targetX: root.checked ? parent.width - targetWidth - margin : margin
            readonly property int targetWidth: isActive ? 28 : 16
            readonly property int targetHeight: root.down ? 28 : (root.checked ? 24 : 16)

            x: targetX
            y: (parent.height - height) / 2
            width: targetWidth
            height: targetHeight
            radius: Appearance.rounding.full
            color: isActive ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3Outline

            Behavior on x {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                    duration: Appearance.animations.durations.small
                }
            }
            Behavior on height {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                    duration: Appearance.animations.durations.small
                }
            }
            Behavior on width {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                    duration: Appearance.animations.durations.small
                }
            }

            Loader {
                active: root.isUseIcon
                anchors.centerIn: parent
                asynchronous: true
                sourceComponent: MaterialIcon {
                    icon: root.checked ? root.onIcon : root.offIcon
                    color: root.checked ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3SurfaceContainerHighest
                    font.pointSize: Appearance.fonts.size.medium
                }
            }
        }
    }
}
