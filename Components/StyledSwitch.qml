pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Configs
import qs.Helpers

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
        color: root.checked ? Themes.m3Colors.primary : Themes.m3Colors.surfaceContainerHighest
        border.width: 2
        border.color: root.checked ? "transparent" : Themes.m3Colors.outline

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
            color: isActive ? Themes.m3Colors.onPrimary : Themes.m3Colors.outline

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
                    color: root.checked ? Themes.m3Colors.onPrimaryContainer : Themes.m3Colors.surfaceContainerHighest
                    font.pointSize: Appearance.fonts.medium
                }
            }
        }
    }
}
